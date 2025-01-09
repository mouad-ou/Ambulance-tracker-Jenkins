package mine.dispatchcoordinationservice.service;

import mine.dispatchcoordinationservice.dto.*;
import mine.dispatchcoordinationservice.model.Case;
import mine.dispatchcoordinationservice.util.RouteUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@Service
public class DispatchService {

    private static final Logger log = LoggerFactory.getLogger(DispatchService.class);

    private static final String HOSPITAL_MANAGEMENT_SERVICE_URL = "http://hospital-management-service";
    private static final String ROUTE_OPTIMIZATION_SERVICE_URL = "http://route-optimization-service";
    private static final String AMBULANCE_SERVICE_URL = "http://ambulance-service";

    private static final ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();

    private final WebClient webClient;
    private final CaseService caseService;

    private static final int TOTAL_SIMULATION_SECONDS = 60;

    public DispatchService(WebClient.Builder webClientBuilder, CaseService caseService) {
        this.webClient = webClientBuilder.build();
        this.caseService = caseService;
    }

    public DispatchResult handleEmergency(EmergencyRequest request) {
        List<Hospital> hospitals = fetchHospitalsBySpeciality(request.getSpecialization());
        if (hospitals.isEmpty()) {
            return createFailureResult("No hospital with the required specialization found.");
        }

        List<AmbulanceHospitalPair> ambulanceHospitalPairs = getAvailableAmbulances(hospitals);
        if (ambulanceHospitalPairs.isEmpty()) {
            return createFailureResult("No available ambulances found for the required specialization.");
        }

        AmbulanceHospitalPair selectedPair = findNearestAmbulance(ambulanceHospitalPairs, request);
        if (selectedPair == null) {
            return createFailureResult("No suitable ambulance found.");
        }

        RouteResponse routeToPatient = fetchRoute(
                selectedPair.getAmbulance().getLatitude(),
                selectedPair.getAmbulance().getLongitude(),
                request.getLatitude(),
                request.getLongitude()
        );
        if (!"SUCCESS".equals(routeToPatient.getStatus()) || routeToPatient.getGeometry() == null) {
            return createFailureResult("Route calculation (Ambulance->Patient) failed.");
        }

        double hospitalLat = selectedPair.getHospital().getLatitude();
        double hospitalLng = selectedPair.getHospital().getLongitude();
        RouteResponse routeToHospital = fetchRoute(
                request.getLatitude(),
                request.getLongitude(),
                hospitalLat,
                hospitalLng
        );
        if (!"SUCCESS".equals(routeToHospital.getStatus()) || routeToHospital.getGeometry() == null) {
            return createFailureResult("Route calculation (Patient->Hospital) failed.");
        }

        String mergedGeometry = RouteUtils.mergePolylines(routeToPatient.getGeometry(), routeToHospital.getGeometry());
        log.info("Merged route geometry created.");

        boolean updated = updateAmbulanceAvailability(selectedPair.getAmbulance().getId(), false);
        if (!updated) {
            return createFailureResult("Failed to update ambulance availability.");
        }

        double totalDistance = routeToPatient.getDistance() + routeToHospital.getDistance();
        double totalDuration = routeToPatient.getDuration() + routeToHospital.getDuration();
        Case newCase = saveDispatchCase(request, selectedPair, mergedGeometry, totalDistance, totalDuration);

        DispatchResult dispatchResult = createDispatchResult(selectedPair, mergedGeometry, newCase);

        simulateMergedRoute(
                selectedPair.getAmbulance().getId(),
                mergedGeometry,
                TOTAL_SIMULATION_SECONDS,
                newCase.getId()
        );

        return dispatchResult;
    }

    private List<Hospital> fetchHospitalsBySpeciality(String speciality) {
        try {
            return webClient.get()
                    .uri(HOSPITAL_MANAGEMENT_SERVICE_URL + "/hospitals?speciality=" + speciality)
                    .retrieve()
                    .onStatus(HttpStatusCode::isError,
                            response -> Mono.error(new RuntimeException("Error fetching hospitals")))
                    .bodyToFlux(Hospital.class)
                    .collectList()
                    .block();
        } catch (Exception e) {
            log.error("Error fetching hospitals by specialization: {}", speciality, e);
            return Collections.emptyList();
        }
    }

    private List<AmbulanceHospitalPair> getAvailableAmbulances(List<Hospital> hospitals) {
        List<AmbulanceHospitalPair> pairs = new ArrayList<>();
        for (Hospital hospital : hospitals) {
            List<Ambulance> ambulances = fetchAmbulancesByHospital(hospital.getId());
            ambulances.stream()
                    .filter(Ambulance::isAvailable)
                    .forEach(ambulance -> pairs.add(new AmbulanceHospitalPair(ambulance, hospital)));
        }
        return pairs;
    }

    private List<Ambulance> fetchAmbulancesByHospital(Long hospitalId) {
        try {
            return webClient.get()
                    .uri(HOSPITAL_MANAGEMENT_SERVICE_URL + "/hospitals/by-hospital/" + hospitalId)
                    .retrieve()
                    .onStatus(HttpStatusCode::isError,
                            response -> Mono.error(new RuntimeException("Error fetching ambulances")))
                    .bodyToFlux(Ambulance.class)
                    .collectList()
                    .block();
        } catch (Exception e) {
            log.error("Error fetching ambulances for hospital ID: {}", hospitalId, e);
            return Collections.emptyList();
        }
    }

    private AmbulanceHospitalPair findNearestAmbulance(List<AmbulanceHospitalPair> pairs,
                                                       EmergencyRequest request) {
        return pairs.stream()
                .min(Comparator.comparingDouble(pair ->
                        RouteUtils.calculateDistance(pair.getAmbulance().getLatitude(),
                                pair.getAmbulance().getLongitude(),
                                request.getLatitude(),
                                request.getLongitude())))
                .orElse(null);
    }

    private RouteResponse fetchRoute(double originLat, double originLng, double destLat, double destLng) {
        try {
            log.info("Fetching route from ({}, {}) to ({}, {})", originLat, originLng, destLat, destLng);
            String url = ROUTE_OPTIMIZATION_SERVICE_URL + "/routes" +
                    String.format("?originLat=%f&originLng=%f&destLat=%f&destLng=%f",
                            originLat, originLng, destLat, destLng);
            
            return webClient.get()
                    .uri(url)
                    .retrieve()
                    .onStatus(HttpStatusCode::isError,
                            response -> response.bodyToMono(String.class)
                                    .flatMap(error -> {
                                        log.error("Route service error: {}", error);
                                        return Mono.error(new RuntimeException("Error calculating route: " + error));
                                    }))
                    .bodyToMono(RouteResponse.class)
                    .block();
        } catch (Exception e) {
            log.error("Error fetching route: {}", e.getMessage(), e);
            return new RouteResponse("FAILURE", null);
        }
    }

    private boolean updateAmbulanceAvailability(Integer ambulanceId, boolean availability) {
        try {
            webClient.put()
                    .uri(AMBULANCE_SERVICE_URL + "/ambulances/" + ambulanceId + "/availability")
                    .bodyValue(Collections.singletonMap("available", availability))
                    .retrieve()
                    .onStatus(HttpStatusCode::isError,
                            response -> Mono.error(new RuntimeException("Error updating ambulance availability")))
                    .toBodilessEntity()
                    .block();
            return true;
        } catch (Exception e) {
            log.error("Error updating availability for ambulance ID={}, err={}", ambulanceId, e.getMessage());
            return false;
        }
    }

    private Case saveDispatchCase(EmergencyRequest request,
                                  AmbulanceHospitalPair selectedPair,
                                  String mergedGeometry,
                                  double totalDistance,
                                  double totalDuration) {
        Case newCase = new Case();
        newCase.setLatitude(request.getLatitude());
        newCase.setLongitude(request.getLongitude());
        newCase.setSpecialization(request.getSpecialization());
        newCase.setStatus("ENROUTE_TO_PATIENT");
        newCase.setAssignedAmbulanceId(selectedPair.getAmbulance().getId());
        newCase.setAssignedHospitalId(selectedPair.getHospital().getId());
        newCase.setRouteGeometry(mergedGeometry);
        newCase.setEstimatedDistance(totalDistance);
        newCase.setEstimatedDuration(totalDuration);
        newCase.setCreatedAt(LocalDateTime.now());
        return caseService.createCase(newCase);
    }

    private DispatchResult createDispatchResult(AmbulanceHospitalPair selectedPair,
                                                String mergedGeometry,
                                                Case savedCase) {
        DispatchResult result = new DispatchResult();
        result.setAssignedAmbulance(selectedPair.getAmbulance());
        result.setAssignedHospital(selectedPair.getHospital());
        result.setRoutePolyline(mergedGeometry);
        result.setStatus("SUCCESS");
        return result;
    }

    private void simulateMergedRoute(Integer ambulanceId,
                                     String mergedPolyline,
                                     int durationSeconds,
                                     Long caseId) {
        if (mergedPolyline == null || mergedPolyline.isEmpty()) {
            log.warn("simulateMergedRoute: empty polyline, skipping.");
            return;
        }

        List<double[]> routePoints = RouteUtils.decodePolyline(mergedPolyline);
        if (routePoints.size() < 2) {
            log.warn("simulateMergedRoute: not enough points to simulate.");
            return;
        }

        final int totalPoints = routePoints.size();
        final int totalTicks = durationSeconds;
        final double segmentCount = totalPoints - 1;

        final int[] currentTick = {0};

        scheduler.scheduleAtFixedRate(() -> {
            try {
                Case c = caseService.findCaseById(caseId);
                if (c == null || "CLOSED".equalsIgnoreCase(c.getStatus())) {
                    log.info("simulateMergedRoute: case #{} is closed or not found. Stopping updates for ambulance ID={}.",
                            caseId, ambulanceId);
                    return;
                }

                int tick = currentTick[0];
                if (tick > totalTicks) {
                    log.info("simulateMergedRoute: route finished for ambulance ID={}. Setting available=true, closing case #{}.",
                            ambulanceId, caseId);

                    setAmbulanceAvailability(ambulanceId, true);
                    updateCaseStatus(caseId, "CLOSED");
                    return;
                }

                double fractionComplete = (double) tick / totalTicks;
                double totalSegments = fractionComplete * segmentCount;

                int segmentIndex = (int) Math.floor(totalSegments);
                double segmentFraction = totalSegments - segmentIndex;

                if (segmentIndex >= totalPoints - 1) {
                    segmentIndex = totalPoints - 2;
                    segmentFraction = 1.0;
                }

                double[] start = routePoints.get(segmentIndex);
                double[] end   = routePoints.get(segmentIndex + 1);

                double lat = RouteUtils.lerp(start[0], end[0], segmentFraction);
                double lng = RouteUtils.lerp(start[1], end[1], segmentFraction);

                updateAmbulanceLocation(ambulanceId, lat, lng);

                log.info("Tick {} => Ambulance ID={} location updated to lat={}, lng={}",
                        tick, ambulanceId, lat, lng);

                currentTick[0] = tick + 1;

            } catch (Exception e) {
                log.error("simulateMergedRoute: error for ambulanceId={}, caseId={}, msg={}",
                        ambulanceId, caseId, e.getMessage(), e);
            }
        }, 0, 1, TimeUnit.SECONDS);
    }

    private void updateAmbulanceLocation(Integer ambulanceId, double latitude, double longitude) {
        try {
            Map<String, Object> body = new HashMap<>();
            body.put("latitude", latitude);
            body.put("longitude", longitude);

            webClient.put()
                    .uri(AMBULANCE_SERVICE_URL + "/ambulances/" + ambulanceId + "/location")
                    .bodyValue(body)
                    .retrieve()
                    .onStatus(HttpStatusCode::isError,
                            response -> Mono.error(new RuntimeException("Error updating ambulance location")))
                    .toBodilessEntity()
                    .block();
        } catch (Exception e) {
            log.error("Failed to update location for ambulance ID={}, error={}", ambulanceId, e.getMessage());
        }
    }

    private void updateCaseStatus(Long caseId, String newStatus) {
        try {
            Case existing = caseService.findCaseById(caseId);
            if (existing == null) {
                log.warn("updateCaseStatus: Case #{} not found; cannot update to status={}", caseId, newStatus);
                return;
            }
            existing.setStatus(newStatus);
            caseService.updateCase(existing);
            log.info("Case #{} updated to status='{}'.", caseId, newStatus);
        } catch (Exception e) {
            log.error("Failed to update case #{} status to '{}': {}", caseId, newStatus, e.getMessage());
        }
    }

    private void setAmbulanceAvailability(Integer ambulanceId, boolean availability) {
        try {
            webClient.put()
                    .uri(AMBULANCE_SERVICE_URL + "/ambulances/" + ambulanceId + "/availability")
                    .bodyValue(Collections.singletonMap("available", availability))
                    .retrieve()
                    .onStatus(HttpStatusCode::isError,
                            response -> Mono.error(new RuntimeException("Error updating ambulance availability")))
                    .toBodilessEntity()
                    .block();
        } catch (Exception e) {
            log.error("Failed to set availability for ambulance ID={}, error={}", ambulanceId, e.getMessage());
        }
    }

    private DispatchResult createFailureResult(String message) {
        DispatchResult result = new DispatchResult();
        result.setStatus("FAILURE");
        log.error("Dispatch failed: {}", message);
        return result;
    }
}