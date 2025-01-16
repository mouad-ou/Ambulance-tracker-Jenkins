export interface Case {
  id: number;
  specialization: string;
  status: string;
  assignedAmbulanceId: number;
  assignedHospitalId: number;
  estimatedDuration: number;
  estimatedDistance: number;
  realDuration?: number;
  createdAt: string;
  routeGeometry?: string;
  routePolyline?: string;
}
