package mine.dispatchcoordinationservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
public class DispatchCoordinationServiceApplication {

	public static void main(String[] args) {
		SpringApplication.run(DispatchCoordinationServiceApplication.class, args);
	}

}
