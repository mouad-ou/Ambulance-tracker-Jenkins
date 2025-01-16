package mine.hospital_service.repository;

import mine.hospital_service.dto.AmbulanceDTO;
import mine.hospital_service.model.Hospital;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface HospitalRepository extends JpaRepository<Hospital, Long> {

    // Query method to find hospitals by speciality, ignoring case
    @Query("SELECT h FROM Hospital h WHERE LOWER(h.speciality) = LOWER(:speciality)")
    List<Hospital> findBySpecialityCaseInsensitive(@Param("speciality") String speciality);

}
