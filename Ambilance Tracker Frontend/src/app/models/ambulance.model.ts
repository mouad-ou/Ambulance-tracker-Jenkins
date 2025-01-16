export interface Ambulance {
  id: number;
  driverName: string;
  available: boolean;
  latitude: number;
  longitude: number;
  status: 'AVAILABLE' | 'BUSY';
  currentCaseId?: number;
}

export interface AmbulanceLocation {
  ambulanceId: string;
  latitude: number;
  longitude: number;
}
