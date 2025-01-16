package mine.routeoptimizationservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
public class RouteOptimizationServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(RouteOptimizationServiceApplication.class, args);
    }
}

