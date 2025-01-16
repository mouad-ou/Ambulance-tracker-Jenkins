package mine.dispatchcoordinationservice.controller;

import mine.dispatchcoordinationservice.dto.DispatchResult;
import mine.dispatchcoordinationservice.dto.EmergencyRequest;
import mine.dispatchcoordinationservice.service.DispatchService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/dispatch")
public class DispatchController {

    private final DispatchService dispatchService;

    public DispatchController(DispatchService dispatchService) {
        this.dispatchService = dispatchService;
    }

    @PostMapping("/emergency")
    public ResponseEntity<DispatchResult> handleEmergency(@RequestBody EmergencyRequest request) {
        DispatchResult result = dispatchService.handleEmergency(request);
        // Always return 200 for valid requests, even if no ambulance is found
        return ResponseEntity.ok(result);
    }
}
