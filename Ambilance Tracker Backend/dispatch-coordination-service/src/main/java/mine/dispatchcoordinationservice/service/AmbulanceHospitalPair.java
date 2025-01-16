package mine.dispatchcoordinationservice.service;

import mine.dispatchcoordinationservice.dto.Ambulance;
import mine.dispatchcoordinationservice.dto.Hospital;

public class AmbulanceHospitalPair {
    private final Ambulance ambulance;
    private final Hospital hospital;

    public AmbulanceHospitalPair(Ambulance ambulance, Hospital hospital) {
        this.ambulance = ambulance;
        this.hospital = hospital;
    }

    public Ambulance getAmbulance() {
        return ambulance;
    }

    public Hospital getHospital() {
        return hospital;
    }
}