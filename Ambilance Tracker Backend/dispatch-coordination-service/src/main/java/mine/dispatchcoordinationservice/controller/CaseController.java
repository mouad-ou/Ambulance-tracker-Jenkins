package mine.dispatchcoordinationservice.controller;

import mine.dispatchcoordinationservice.model.Case;
import mine.dispatchcoordinationservice.service.CaseService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/cases")
public class CaseController {

    private final CaseService caseService;

    public CaseController(CaseService caseService) {
        this.caseService = caseService;
    }

    @GetMapping
    public List<Case> getAllCases() {
        return caseService.getAllCases();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Case> getCaseById(@PathVariable Integer id) {
        return caseService.getCaseById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<Case> updateCase(@PathVariable Integer id, @RequestBody Case updatedCase) {
        return caseService.getCaseById(id)
                .map(existingCase -> {
                    updatedCase.setId(existingCase.getId());
                    return ResponseEntity.ok(caseService.updateCase(updatedCase));
                })
                .orElse(ResponseEntity.notFound().build());
    }
    @DeleteMapping
    public ResponseEntity<Void> deleteCases() {
        try {
            caseService.deleteCases();
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCase(@PathVariable Integer id) {
        try {
            boolean deleted = caseService.deleteCase(id);
            return deleted ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }


}
