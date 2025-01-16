package mine.hospital_service.controller;

import mine.hospital_service.dto.AmbulanceDTO;
import mine.hospital_service.model.Hospital;
import mine.hospital_service.service.HospitalService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/hospitals")
public class HospitalController {

    private final HospitalService hospitalService;

    public HospitalController(HospitalService hospitalService) {
        this.hospitalService = hospitalService;
    }

    @GetMapping
    public List<Hospital> getAllHospitals() {
        return hospitalService.getAllHospitals();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Hospital> getHospitalById(@PathVariable Long id) {
        return hospitalService.getHospitalById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<List<Hospital>> createHospitals(@RequestBody List<Hospital> hospitals) {
        List<Hospital> savedHospitals = new ArrayList<>();
        for (Hospital hospital : hospitals) {
            Hospital saved = hospitalService.createHospital(hospital);
            savedHospitals.add(saved);
        }
        return ResponseEntity.ok(savedHospitals);
    }


    @PutMapping("/{id}")
    public ResponseEntity<Hospital> updateHospital(@PathVariable Long id, @RequestBody Hospital updatedHospital) {
        return hospitalService.updateHospital(id, updatedHospital)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteHospital(@PathVariable Long id) {
        boolean deleted = hospitalService.deleteHospital(id);
        return deleted ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }

    @PostMapping("/{id}/ambulances/{ambulanceId}")
    public ResponseEntity<Hospital> addAmbulanceToHospital(@PathVariable Long id, @PathVariable Integer ambulanceId) {
        return hospitalService.addAmbulanceToHospital(id, ambulanceId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}/ambulances/{ambulanceId}")
    public ResponseEntity<Hospital> removeAmbulanceFromHospital(@PathVariable Long id, @PathVariable Integer ambulanceId) {
        return hospitalService.removeAmbulanceFromHospital(id, ambulanceId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping(value = "/ambulances/{ambulanceId}", produces = "application/json")
    public ResponseEntity<AmbulanceDTO> getAmbulanceDetails(@PathVariable Integer ambulanceId) {
        return hospitalService.fetchAmbulanceDetails(ambulanceId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    @GetMapping(value = "/speciality", produces = "application/json")
    public ResponseEntity<List<Hospital>> getHospitalsBySpeciality(@RequestParam(required = false) String speciality) {
        return ResponseEntity.ok(hospitalService.findBySpeciality(speciality));
    }
    @GetMapping(value = "by-hospital/{hospitalId}", produces = "application/json")
    public List<AmbulanceDTO> getAmbulancesByHospital(@PathVariable Long hospitalId) {
        return hospitalService.findByAmbulanceIds(hospitalId);
    }

    @GetMapping(value = "/specialities", produces = "application/json")
    public List<String> getAllSpecialities() {
        return hospitalService.getAllSpecialities();
    }
}
