package mine.hospital_service.config;

import mine.hospital_service.model.Hospital;
import mine.hospital_service.repository.HospitalRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Arrays;

@Configuration
public class DataInitializer {

    @Bean
    public CommandLineRunner initializeDatabase(HospitalRepository hospitalRepository) {
        return args -> {
            // Predefined hospital data for Marrakech
            Hospital hospital1 = new Hospital();
            hospital1.setName("Marrakech General Hospital");
            hospital1.setLatitude(31.6295);
            hospital1.setLongitude(-7.9811);
            hospital1.setAvailable(true);
            hospital1.setAddress("123 Main Street, Marrakech");
            hospital1.setSpeciality("Cardiology");
            hospital1.setAmbulanceIds(Arrays.asList(1));


            Hospital hospital2 = new Hospital();
            hospital2.setName("Marrakech Neuro Hospital");
            hospital2.setLatitude(31.6315);
            hospital2.setLongitude(-7.9892);
            hospital2.setAvailable(true);
            hospital2.setAddress("456 Elm Street, Marrakech");
            hospital2.setSpeciality("Neurology");
            hospital2.setAmbulanceIds(Arrays.asList(2));

            Hospital hospital3 = new Hospital();
            hospital3.setName("Marrakech Pediatric Center");
            hospital3.setLatitude(31.6354);
            hospital3.setLongitude(-7.9921);
            hospital3.setAvailable(true);
            hospital3.setAddress("789 Maple Avenue, Marrakech");
            hospital3.setSpeciality("Pediatrics");
            hospital3.setAmbulanceIds(Arrays.asList(3));

            // Save to database
            hospitalRepository.saveAll(Arrays.asList(hospital1, hospital2, hospital3));

            // Retrieve hospitals in Marrakech and print them
            System.out.println("Hospitals in Marrakech:");
            hospitalRepository.findAll().forEach(hospital -> {
                System.out.println("Hospital Name: " + hospital.getName() +
                        ", Speciality: " + hospital.getSpeciality() +
                        ", Address: " + hospital.getAddress() +
                        ", Latitude: " + hospital.getLatitude() +
                        ", Longitude: " + hospital.getLongitude());
            });
        };
    }
}
