package mine.ambulance_service.repository;

import mine.ambulance_service.model.Ambulance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AmbulanceRepository extends JpaRepository<Ambulance, Integer> {
    // Additional query methods if needed
}
