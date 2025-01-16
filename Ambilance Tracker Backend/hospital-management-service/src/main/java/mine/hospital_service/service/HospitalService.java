package mine.hospital_service.service;

import mine.hospital_service.dto.AmbulanceDTO;
import mine.hospital_service.model.Hospital;
import mine.hospital_service.repository.HospitalRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class HospitalService {

    private final HospitalRepository hospitalRepository;
    private final WebClient webClient;

    public HospitalService(WebClient.Builder webClientBuilder, HospitalRepository hospitalRepository) {
        this.hospitalRepository = hospitalRepository;
        this.webClient = webClientBuilder.baseUrl("http://ambulance-service").build();
    }


    public List<Hospital> getAllHospitals() {
        return hospitalRepository.findAll();
    }

    public Optional<Hospital> getHospitalById(Long id) {
        return hospitalRepository.findById(id);
    }

    public Hospital createHospital(Hospital hospital) {
        return hospitalRepository.save(hospital);
    }

    public Optional<Hospital> updateHospital(Long id, Hospital updatedHospital) {
        return hospitalRepository.findById(id)
                .map(existingHospital -> {
                    existingHospital.setName(updatedHospital.getName());
                    existingHospital.setLatitude(updatedHospital.getLatitude());
                    existingHospital.setLongitude(updatedHospital.getLongitude());
                    existingHospital.setAvailable(updatedHospital.isAvailable());
                    existingHospital.setAmbulanceIds(updatedHospital.getAmbulanceIds());
                    existingHospital.setAddress(updatedHospital.getAddress());
                    existingHospital.setSpeciality(updatedHospital.getSpeciality());
                    return hospitalRepository.save(existingHospital);
                });
    }

    public boolean deleteHospital(Long id) {
        return hospitalRepository.findById(id)
                .map(hospital -> {
                    hospitalRepository.delete(hospital);
                    return true;
                }).orElse(false);
    }

    public Optional<Hospital> addAmbulanceToHospital(Long hospitalId, Integer ambulanceId) {
        return hospitalRepository.findById(hospitalId)
                .map(hospital -> {
                    if (!hospital.getAmbulanceIds().contains(ambulanceId)) {
                        hospital.getAmbulanceIds().add(ambulanceId);
                        hospitalRepository.save(hospital);
                    }
                    return hospital;
                });
    }

    public Optional<Hospital> removeAmbulanceFromHospital(Long hospitalId, Integer ambulanceId) {
        return hospitalRepository.findById(hospitalId)
                .map(hospital -> {
                    hospital.getAmbulanceIds().remove(ambulanceId);
                    hospitalRepository.save(hospital);
                    return hospital;
                });
    }

    public Optional<AmbulanceDTO> fetchAmbulanceDetails(Integer ambulanceId) {
        try {
            return Optional.ofNullable(
                    webClient.get()
                            .uri("/ambulances/{id}", ambulanceId)
                            .retrieve()
                            .bodyToMono(AmbulanceDTO.class)
                            .block()
            );
        } catch (Exception e) {
            // Log the exception for debugging
            System.err.println("Error fetching ambulance details: " + e.getMessage());
            return Optional.empty();
        }
    }

    public List<Hospital> findBySpeciality(String speciality) {
        if (speciality == null || speciality.trim().isEmpty()) {
            throw new IllegalArgumentException("Speciality must not be null or empty.");
        }
        return hospitalRepository.findBySpecialityCaseInsensitive(speciality.trim());
    }


    public List<AmbulanceDTO> findByAmbulanceIds(Long hospitalId) {
        return hospitalRepository.findById(hospitalId)
                .map(hospital -> {
                    return hospital.getAmbulanceIds().stream()
                            .map(ambulanceId -> fetchAmbulanceDetails(ambulanceId).orElse(null))
                            .toList();
                }).orElse(List.of());
    }

    public List<String> getAllSpecialities() {
        return hospitalRepository.findAll().stream()
                .map(Hospital::getSpeciality)
                .distinct()
                .collect(Collectors.toList());
    }
}
