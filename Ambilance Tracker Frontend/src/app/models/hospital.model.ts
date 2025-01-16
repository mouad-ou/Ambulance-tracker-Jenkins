export interface Hospital {
  id: number;
  name: string;
  latitude: number;
  longitude: number;
  available: boolean;
  address: string;
  specializations: string[];
  availableBeds: number;
  speciality: string;
}
