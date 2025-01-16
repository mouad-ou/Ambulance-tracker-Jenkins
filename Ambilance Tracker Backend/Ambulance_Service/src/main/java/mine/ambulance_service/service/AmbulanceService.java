package mine.ambulance_service.service;

import mine.ambulance_service.model.Ambulance;
import mine.ambulance_service.repository.AmbulanceRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class AmbulanceService {

    private final AmbulanceRepository ambulanceRepository;
    private final AmbulanceLocationNotifierService notifierService;

    public AmbulanceService(AmbulanceRepository ambulanceRepository, AmbulanceLocationNotifierService notifierService) {
        this.ambulanceRepository = ambulanceRepository;
        this.notifierService = notifierService;
    }

    public List<Ambulance> getAllAmbulances() {
        return ambulanceRepository.findAll();
    }

    public Optional<Ambulance> getAmbulanceById(Long id) {
        return ambulanceRepository.findById(Math.toIntExact(id));
    }

    public Ambulance createAmbulance(Ambulance ambulance) {
        return ambulanceRepository.save(ambulance);
    }

    public Optional<Ambulance> updateAmbulance(Long id, Ambulance updatedAmbulance) {
        return ambulanceRepository.findById(Math.toIntExact(id))
                .map(existingAmbulance -> {
                    existingAmbulance.setAvailable(updatedAmbulance.isAvailable());
                    existingAmbulance.setLatitude(updatedAmbulance.getLatitude());
                    existingAmbulance.setLongitude(updatedAmbulance.getLongitude());
                    existingAmbulance.setDriverName(updatedAmbulance.getDriverName());
                    existingAmbulance.setId(updatedAmbulance.getId());
                    return ambulanceRepository.save(existingAmbulance);
                });
    }
    public Optional<Ambulance> updateAmbulanceLocation(Long id, Double latitude, Double longitude) {
        return ambulanceRepository.findById(Math.toIntExact(id))
                .map(existingAmbulance -> {
                    existingAmbulance.setLatitude(latitude);
                    existingAmbulance.setLongitude(longitude);
                    // Notify WebSocket clients of location update
                    notifierService.notifyAmbulanceLocation(id);
                    return ambulanceRepository.save(existingAmbulance);
                });
    }
    public Optional<Ambulance> getAmbulanceLocation(Long id) {
        return ambulanceRepository.findById(Math.toIntExact(id))
                .map(ambulance -> {
                    // Notify the WebSocket clients with the current location
                    notifierService.notifyAmbulanceLocation(id);
                    return ambulance;
                });
    }

    public boolean deleteAmbulance(Long id) {
        return ambulanceRepository.findById(Math.toIntExact(id))
                .map(ambulance -> {
                    ambulanceRepository.delete(ambulance);
                    return true;
                }).orElse(false);
    }

    public Optional<Ambulance> updateAmbulanceAvailability(Long id, boolean available) {
        return ambulanceRepository.findById(Math.toIntExact(id))
                .map(existingAmbulance -> {
                    existingAmbulance.setAvailable(available);
                    ambulanceRepository.save(existingAmbulance);
                    return existingAmbulance;
                });
    }

}
