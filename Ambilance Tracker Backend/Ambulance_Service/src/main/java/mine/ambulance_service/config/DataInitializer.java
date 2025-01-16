package mine.ambulance_service.config;

import mine.ambulance_service.model.Ambulance;
import mine.ambulance_service.repository.AmbulanceRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Arrays;

@Configuration
public class DataInitializer {

    @Bean
    public CommandLineRunner initializeAmbulances(AmbulanceRepository ambulanceRepository) {
        return args -> {
            // Predefined ambulance data with driver names
            Ambulance ambulance1 = new Ambulance();
            ambulance1.setDriverName("Ahmed Bensouda");
            ambulance1.setAvailable(true);
            ambulance1.setLatitude(31.6255);
            ambulance1.setLongitude(-7.9810);

            Ambulance ambulance2 = new Ambulance();
            ambulance2.setDriverName("Fatima El Ghazi");
            ambulance2.setAvailable(true);
            ambulance2.setLatitude(31.6302);
            ambulance2.setLongitude(-7.9864);

            Ambulance ambulance3 = new Ambulance();
            ambulance3.setDriverName("Youssef El Idrissi");
            ambulance3.setAvailable(false);
            ambulance3.setLatitude(31.6361);
            ambulance3.setLongitude(-7.9918);

            // Save ambulances to the database
            ambulanceRepository.saveAll(Arrays.asList(ambulance1, ambulance2, ambulance3));

            // Retrieve all ambulances and print them
            System.out.println("Ambulances in Marrakech:");
            ambulanceRepository.findAll().forEach(ambulance -> {
                System.out.println("Ambulance ID: " + ambulance.getId() +
                        ", Driver: " + ambulance.getDriverName() +
                        ", Available: " + ambulance.isAvailable() +
                        ", Latitude: " + ambulance.getLatitude() +
                        ", Longitude: " + ambulance.getLongitude());
            });
        };
    }
}

