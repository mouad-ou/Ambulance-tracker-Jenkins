package mine.dispatchcoordinationservice.repository;

import mine.dispatchcoordinationservice.model.Case;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CaseRepository extends JpaRepository<Case, Integer> {
}
