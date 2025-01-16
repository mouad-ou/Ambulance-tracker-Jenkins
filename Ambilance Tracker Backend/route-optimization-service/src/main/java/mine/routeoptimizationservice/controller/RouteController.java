package mine.routeoptimizationservice.controller;

import mine.routeoptimizationservice.dto.RouteResponse;
import mine.routeoptimizationservice.service.RouteService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/routes")
public class RouteController {

    private final RouteService routeService;

    public RouteController(RouteService routeService) {
        this.routeService = routeService;
    }

    @GetMapping
    public RouteResponse getRoute(
            @RequestParam Double originLat,
            @RequestParam Double originLng,
            @RequestParam Double destLat,
            @RequestParam Double destLng
    ) {
        return routeService.getOptimizedRoute(originLat, originLng, destLat, destLng);
    }
}
