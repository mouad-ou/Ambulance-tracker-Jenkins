package mine.ambulance_service.websocket;

import mine.ambulance_service.dto.AmbulanceLocationDTO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.messaging.converter.MappingJackson2MessageConverter;
import org.springframework.messaging.simp.stomp.*;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.messaging.WebSocketStompClient;
import org.springframework.web.socket.sockjs.client.SockJsClient;
import org.springframework.web.socket.sockjs.client.Transport;
import org.springframework.web.socket.sockjs.client.WebSocketTransport;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class WebSocketIntegrationTest {

    @LocalServerPort
    private int port;

    private WebSocketStompClient stompClient;
    private final CompletableFuture<List<AmbulanceLocationDTO>> locationUpdates = new CompletableFuture<>();

    @BeforeEach
    public void setup() {
        List<Transport> transports = new ArrayList<>();
        transports.add(new WebSocketTransport(new StandardWebSocketClient()));
        
        SockJsClient sockJsClient = new SockJsClient(transports);
        stompClient = new WebSocketStompClient(sockJsClient);
        stompClient.setMessageConverter(new MappingJackson2MessageConverter());
    }

    @Test
    public void testLocationUpdates() throws Exception {
        String wsUrl = "ws://localhost:" + port + "/ws";
        StompSessionHandler sessionHandler = new TestStompSessionHandler();

        StompSession session = stompClient.connect(wsUrl, sessionHandler).get(5, TimeUnit.SECONDS);
        session.subscribe("/topic/ambulance-locations", new StompFrameHandler() {
            @Override
            public Type getPayloadType(StompHeaders headers) {
                return List.class;
            }

            @Override
            public void handleFrame(StompHeaders headers, Object payload) {
                if (payload instanceof List<?> list) {
                    List<AmbulanceLocationDTO> locations = new ArrayList<>();
                    for (Object item : list) {
                        if (item instanceof java.util.LinkedHashMap<?, ?> map) {
                            AmbulanceLocationDTO dto = new AmbulanceLocationDTO();
                            dto.setAmbulanceId(((Number) map.get("ambulanceId")).longValue());
                            dto.setLatitude((Double) map.get("latitude"));
                            dto.setLongitude((Double) map.get("longitude"));
                            locations.add(dto);
                        }
                    }
                    locationUpdates.complete(locations);
                }
            }
        });

        // Send a request for locations
        session.send("/app/requestLocations", null);

        // Wait for response
        List<AmbulanceLocationDTO> receivedLocations = locationUpdates.get(5, TimeUnit.SECONDS);
        assertNotNull(receivedLocations, "Should receive location updates");
        assertTrue(receivedLocations.size() > 0, "Should receive at least one location");

        // Print received locations for verification
        System.out.println("Received locations:");
        receivedLocations.forEach(loc -> 
            System.out.printf("Ambulance ID: %d, Latitude: %f, Longitude: %f%n", 
                loc.getAmbulanceId(), loc.getLatitude(), loc.getLongitude())
        );
    }

    private static class TestStompSessionHandler extends StompSessionHandlerAdapter {
        @Override
        public void handleException(StompSession session, StompCommand command, 
                StompHeaders headers, byte[] payload, Throwable exception) {
            exception.printStackTrace();
        }

        @Override
        public void handleTransportError(StompSession session, Throwable exception) {
            exception.printStackTrace();
        }
    }
}
