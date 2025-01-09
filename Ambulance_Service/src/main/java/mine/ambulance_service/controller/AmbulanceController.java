package mine.ambulance_service.controller;

import mine.ambulance_service.model.Ambulance;
import mine.ambulance_service.service.AmbulanceService;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/ambulances")
public class AmbulanceController {

    private final SimpMessagingTemplate messagingTemplate;
    private final AmbulanceService ambulanceService;

    // Constructor injection for both AmbulanceService and SimpMessagingTemplate
    public AmbulanceController(AmbulanceService ambulanceService, SimpMessagingTemplate messagingTemplate) {
        this.ambulanceService = ambulanceService;
        this.messagingTemplate = messagingTemplate;
    }

    @GetMapping
    public List<Ambulance> getAllAmbulances() {
        return ambulanceService.getAllAmbulances();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Ambulance> getAmbulanceById(@PathVariable Long id) {
        return ambulanceService.getAmbulanceById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{id}/location")
    public ResponseEntity<Map<String, Object>> getAmbulanceLocation(@PathVariable Long id) {
        return ambulanceService.getAmbulanceById(id)
                .map(ambulance -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("id", ambulance.getId());
                    response.put("driverName", ambulance.getDriverName());
                    response.put("latitude", ambulance.getLatitude());
                    response.put("longitude", ambulance.getLongitude());
                    response.put("available", ambulance.isAvailable());
                    return ResponseEntity.ok(response);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Ambulance> createAmbulance(@RequestBody Ambulance ambulance) {
        if (ambulance.getLatitude() == null || ambulance.getLongitude() == null) {
            return ResponseEntity.badRequest().build();
        }
        Ambulance created = ambulanceService.createAmbulance(ambulance);
        return ResponseEntity.ok(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Ambulance> updateAmbulance(@PathVariable Long id, @RequestBody Ambulance updatedAmbulance) {
        return ambulanceService.updateAmbulance(id, updatedAmbulance)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}/location")
    public ResponseEntity<Void> updateAmbulanceLocation(
            @PathVariable Long id,
            @RequestBody Map<String, Double> location) {
        Double latitude = location.get("latitude");
        Double longitude = location.get("longitude");
        
        if (latitude == null || longitude == null) {
            return ResponseEntity.badRequest().build();
        }

        return ambulanceService.updateAmbulanceLocation(id, latitude, longitude)
                .map(ambulance -> {
                    // Notify WebSocket subscribers
                    Map<String, Object> update = new HashMap<>();
                    update.put("id", ambulance.getId());
                    update.put("driverName", ambulance.getDriverName());
                    update.put("latitude", ambulance.getLatitude());
                    update.put("longitude", ambulance.getLongitude());
                    update.put("available", ambulance.isAvailable());
                    
                    messagingTemplate.convertAndSend(
                            "/topic/ambulance/" + id + "/location",
                            update
                    );
                    return ResponseEntity.ok().<Void>build();
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}/availability")
    public ResponseEntity<Void> updateAmbulanceAvailability(
            @PathVariable Long id,
            @RequestBody Map<String, Boolean> availability) {
        Boolean available = availability.get("available");
        if (available == null) {
            return ResponseEntity.badRequest().build();
        }

        return ambulanceService.updateAmbulanceAvailability(id, available)
                .map(ambulance -> {
                    // Notify WebSocket subscribers about availability change
                    Map<String, Object> update = new HashMap<>();
                    update.put("id", ambulance.getId());
                    update.put("driverName", ambulance.getDriverName());
                    update.put("latitude", ambulance.getLatitude());
                    update.put("longitude", ambulance.getLongitude());
                    update.put("available", ambulance.isAvailable());
                    
                    messagingTemplate.convertAndSend(
                            "/topic/ambulance/" + id + "/location",
                            update
                    );
                    return ResponseEntity.ok().<Void>build();
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAmbulance(@PathVariable Long id) {
        boolean deleted = ambulanceService.deleteAmbulance(id);
        return deleted ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }
}
