package mine.dispatchcoordinationservice.dto;

import lombok.Data;

@Data
public class DispatchResult {
    private Ambulance assignedAmbulance;
    private Hospital assignedHospital;
    private String routePolyline;
    private String status;

    public Ambulance getAssignedAmbulance() {
        return assignedAmbulance;
    }

    public void setAssignedAmbulance(Ambulance assignedAmbulance) {
        this.assignedAmbulance = assignedAmbulance;
    }

    public Hospital getAssignedHospital() {
        return assignedHospital;
    }

    public void setAssignedHospital(Hospital assignedHospital) {
        this.assignedHospital = assignedHospital;
    }

    public String getRoutePolyline() {
        return routePolyline;
    }

    public void setRoutePolyline(String routePolyline) {
        this.routePolyline = routePolyline;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
