package mine.dispatchcoordinationservice.model;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Data
@Table(name = "cases")
public class Case {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Double latitude; // Location of the emergency

    @Column(nullable = false)
    private Double longitude; // Location of the emergency

    @Column(nullable = false)
    private String specialization; // Specialization requested

    @Column(nullable = false)
    private String status; // Case status (OPEN, COMPLETED, CANCELED)

    @Column(name = "ambulance_id", nullable = false)
    private Integer assignedAmbulanceId;
    // ID of the assigned ambulance

    @Column(name = "hospital_id", nullable = false)
    private Long assignedHospitalId;

    @Column(name = "estimated_duration", nullable = false)
    private Double estimatedDuration;

    @Column(name = "estimated_distance", nullable = false)
    private Double estimatedDistance;

    @Column(name = "route_geometry", nullable = false, columnDefinition = "LONGTEXT")
    private String routeGeometry;

    @Column(name = "real_duration")
    private Double realDuration;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
