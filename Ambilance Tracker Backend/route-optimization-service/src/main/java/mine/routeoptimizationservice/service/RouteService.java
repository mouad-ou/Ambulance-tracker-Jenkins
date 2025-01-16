package mine.routeoptimizationservice.service;

import mine.routeoptimizationservice.dto.MapboxDirectionsResponse;
import mine.routeoptimizationservice.dto.RouteResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

@Service
public class RouteService {

    private static final Logger log = LoggerFactory.getLogger(RouteService.class);

    @Value("${mapbox.api-key}")
    private String mapboxApiKey;

    private final WebClient webClient;

    public RouteService(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.baseUrl("https://api.mapbox.com").build();
    }

    public RouteResponse getOptimizedRoute(Double originLat, Double originLng, Double destLat, Double destLng) {
        try {
            String coordinates = String.format("%f,%f;%f,%f", originLng, originLat, destLng, destLat);
            String url = String.format(
                    "/directions/v5/mapbox/driving/%s?access_token=%s&overview=full&geometries=polyline",
                    coordinates,
                    mapboxApiKey
            );

            log.info("Requesting route from Mapbox: {}", url);
            log.debug("API Key: {}", mapboxApiKey);

            MapboxDirectionsResponse response = webClient.get()
                    .uri(url)
                    .retrieve()
                    .onStatus(HttpStatusCode::isError,
                            error -> error.bodyToMono(String.class)
                                    .flatMap(body -> {
                                        log.error("Mapbox API error: {}", body);
                                        return Mono.error(new RuntimeException("Mapbox API error: " + body));
                                    }))
                    .bodyToMono(MapboxDirectionsResponse.class)
                    .block();

            if (response != null && !response.getRoutes().isEmpty()) {
                MapboxDirectionsResponse.Route route = response.getRoutes().get(0);
                RouteResponse routeResponse = new RouteResponse();
                routeResponse.setGeometry(route.getGeometry());
                routeResponse.setDistance(route.getDistance());
                routeResponse.setDuration(route.getDuration());
                routeResponse.setStatus("SUCCESS");
                log.info("Successfully retrieved route");
                return routeResponse;
            } else {
                log.error("No routes found in Mapbox response");
                RouteResponse routeResponse = new RouteResponse();
                routeResponse.setStatus("FAILURE");
                return routeResponse;
            }
        } catch (Exception e) {
            log.error("Error getting optimized route: {}", e.getMessage(), e);
            RouteResponse routeResponse = new RouteResponse();
            routeResponse.setStatus("FAILURE");
            return routeResponse;
        }
    }
}
