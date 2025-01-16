package mine.ambulance_service.controller;

import mine.ambulance_service.dto.AmbulanceLocationDTO;
import mine.ambulance_service.model.Ambulance;
import mine.ambulance_service.service.AmbulanceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;
import java.util.List;
import java.util.Optional;

@Controller
public class AmbulanceWebSocketController {

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @Autowired
    private AmbulanceService ambulanceService;

    /**
     * Handles requests for ambulance locations.
     * Fetches all ambulance locations from the database and sends them to the frontend.
     * @return List of AmbulanceLocationDTO objects
     */
    @MessageMapping("/requestLocations")
    @SendTo("/topic/ambulance-locations")
    public List<AmbulanceLocationDTO> sendAmbulanceLocations() {
        List<Ambulance> locations = ambulanceService.getAllAmbulances();
        return locations.stream()
                .map(ambulance -> new AmbulanceLocationDTO(ambulance.getId(), ambulance.getLatitude(), ambulance.getLongitude()))
                .toList();
    }

    /**
     * Handles requests for a specific ambulance's location.
     * @param ambulanceId the ID of the ambulance to track
     * @return AmbulanceLocationDTO if found, null otherwise
     */
    @MessageMapping("/ambulance/{ambulanceId}/location")
    @SendTo("/topic/ambulance/{ambulanceId}/location")
    public AmbulanceLocationDTO sendAmbulanceLocation(@DestinationVariable Long ambulanceId) {
        Optional<Ambulance> ambulance = ambulanceService.getAmbulanceById(ambulanceId);
        return ambulance.map(a -> new AmbulanceLocationDTO(a.getId(), a.getLatitude(), a.getLongitude())).orElse(null);
    }

    /**
     * Broadcasts updated ambulance location to all connected clients
     * @param locationDTO the updated location data
     */
    public void broadcastLocation(AmbulanceLocationDTO locationDTO) {
        // Broadcast to all ambulances topic
        messagingTemplate.convertAndSend("/topic/ambulance-locations", locationDTO);
        
        // Broadcast to specific ambulance topic
        messagingTemplate.convertAndSend(
            String.format("/topic/ambulance/%d/location", locationDTO.getAmbulanceId()),
            locationDTO
        );
    }
}