package mine.dispatchcoordinationservice.dto;

import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor // This adds the default no-args constructor required for Jackson
public class RouteResponse {
    private String geometry;
    private double distance;
    private double duration;
    private String status;

    public String getGeometry() {
        return geometry;
    }

    public void setGeometry(String geometry) {
        this.geometry = geometry;
    }

    public double getDistance() {
        return distance;
    }

    public void setDistance(double distance) {
        this.distance = distance;
    }

    public double getDuration() {
        return duration;
    }

    public void setDuration(double duration) {
        this.duration = duration;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    // Optional: Add a parameterized constructor for specific cases
    public RouteResponse(String failure, Object o) {
        this.status = failure;
    }
}
