package mine.ambulance_service.service;

import mine.ambulance_service.model.Ambulance;
import mine.ambulance_service.repository.AmbulanceRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AmbulanceLocationNotifierService {

    private static final Logger log = LoggerFactory.getLogger(AmbulanceLocationNotifierService.class);

    private final AmbulanceRepository ambulanceRepository;
    private final SimpMessagingTemplate messagingTemplate;

    @Autowired
    public AmbulanceLocationNotifierService(AmbulanceRepository ambulanceRepository, SimpMessagingTemplate messagingTemplate) {
        this.ambulanceRepository = ambulanceRepository;
        this.messagingTemplate = messagingTemplate;
    }

    /**
     * Notify clients about the current location of a specific ambulance.
     *
     * @param ambulanceId the ID of the ambulance
     */
    public void notifyAmbulanceLocation(Long ambulanceId) {
        Optional<Ambulance> ambulanceOptional = ambulanceRepository.findById(Math.toIntExact(ambulanceId));

        if (ambulanceOptional.isPresent()) {
            Ambulance ambulance = ambulanceOptional.get();
            AmbulanceLocationUpdate locationUpdate = new AmbulanceLocationUpdate(
                    ambulance.getId(),
                    ambulance.getLatitude(),
                    ambulance.getLongitude(),
                    ambulance.isAvailable()
            );

            // Send location update to WebSocket clients
            messagingTemplate.convertAndSend("/topic/ambulance-location/" + ambulanceId, locationUpdate);
            log.info("Sent location update for ambulance ID={}: {}, {}", ambulanceId, ambulance.getLatitude(), ambulance.getLongitude());
        } else {
            log.warn("Ambulance with ID={} not found. Cannot send location update.", ambulanceId);
        }
    }

    /**
     * Get ambulance location by ID and notify WebSocket clients.
     *
     * @param id the ID of the ambulance
     * @return the optional ambulance object
     */
    public Optional<Ambulance> getAmbulanceLocation(Long id) {
        return ambulanceRepository.findById(Math.toIntExact(id))
                .map(ambulance -> {
                    // Notify the WebSocket clients with the current location
                    notifyAmbulanceLocation(id);
                    return ambulance;
                });
    }

    /**
     * Periodically broadcast locations of all ambulances.
     */
    @Scheduled(fixedRate = 5000) // Broadcast every 5 seconds
    public void broadcastAllAmbulanceLocations() {
        Iterable<Ambulance> ambulances = ambulanceRepository.findAll();

        ambulances.forEach(ambulance -> {
            AmbulanceLocationUpdate locationUpdate = new AmbulanceLocationUpdate(
                    ambulance.getId(),
                    ambulance.getLatitude(),
                    ambulance.getLongitude(),
                    ambulance.isAvailable()
            );

            messagingTemplate.convertAndSend("/topic/ambulance-locations", locationUpdate);
            log.info("Broadcasted location for ambulance ID={}: {}, {}", ambulance.getId(), ambulance.getLatitude(), ambulance.getLongitude());
        });
    }

    /**
     * Data transfer object for ambulance location updates.
     */
    public static class AmbulanceLocationUpdate {
        private Long id;
        private Double latitude;
        private Double longitude;
        private boolean available;

        public AmbulanceLocationUpdate(Long id, Double latitude, Double longitude, boolean available) {
            this.id = id;
            this.latitude = latitude;
            this.longitude = longitude;
            this.available = available;
        }

        public Long getId() {
            return id;
        }

        public Double getLatitude() {
            return latitude;
        }

        public Double getLongitude() {
            return longitude;
        }

        public boolean isAvailable() {
            return available;
        }
    }
}
