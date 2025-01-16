import 'ambulance_info.dart';
import 'hospital_info.dart';

class EmergencyRequest {
  final double latitude;
  final double longitude;
  final String specialization;

  EmergencyRequest({
    required this.latitude,
    required this.longitude,
    required this.specialization,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'specialization': specialization,
    };
  }
}

class EmergencyResponse {
  final String status;
  final String? routePolyline;
  final AmbulanceInfo? assignedAmbulance;
  final HospitalInfo? assignedHospital;

  EmergencyResponse({
    required this.status,
    this.routePolyline,
    this.assignedAmbulance,
    this.assignedHospital,
  });

  factory EmergencyResponse.fromJson(Map<String, dynamic> json) {
    return EmergencyResponse(
      status: json['status'] ?? 'unknown',
      routePolyline: json['routePolyline'],
      assignedAmbulance: json['assignedAmbulance'] != null 
          ? AmbulanceInfo.fromJson(json['assignedAmbulance']) 
          : null,
      assignedHospital: json['assignedHospital'] != null 
          ? HospitalInfo.fromJson(json['assignedHospital']) 
          : null,
    );
  }
}
