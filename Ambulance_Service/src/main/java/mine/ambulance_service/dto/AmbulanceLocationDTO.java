package mine.ambulance_service.dto;

public class AmbulanceLocationDTO {
    private Long ambulanceId;
    private double latitude;
    private double longitude;

    public AmbulanceLocationDTO() {}

    public AmbulanceLocationDTO(Long ambulanceId, double latitude, double longitude) {
        this.ambulanceId = ambulanceId;
        this.latitude = latitude;
        this.longitude = longitude;
    }

    public Long getAmbulanceId() {
        return ambulanceId;
    }

    public double getLatitude() {
        return latitude;
    }

    public double getLongitude() {
        return longitude;
    }

    public void setAmbulanceId(Long ambulanceId) {
        this.ambulanceId = ambulanceId;
    }

    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }

    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }
}
