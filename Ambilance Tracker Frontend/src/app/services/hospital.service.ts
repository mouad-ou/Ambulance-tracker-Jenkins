import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import {Hospital} from "../models/hospital.model";



@Injectable({
  providedIn: 'root',
})
export class HospitalService {
  private apiUrl = 'http://localhost:8093/hospitals'; // Base URL for the backend API

  constructor(private http: HttpClient) {}

  // Fetch all hospitals
  getAllHospitals(): Observable<Hospital[]> {
    return this.http.get<Hospital[]>(`${this.apiUrl}`);
  }

  // Fetch a single hospital by ID
  getHospitalById(id: number): Observable<Hospital> {
    return this.http.get<Hospital>(`${this.apiUrl}/${id}`);
  }

  // Create a new hospital
  createHospital(hospital: Hospital): Observable<Hospital> {
    return this.http.post<Hospital>(`${this.apiUrl}`, hospital);
  }

  // Update an existing hospital by ID
  updateHospital(id: number, updatedHospital: Hospital): Observable<Hospital> {
    return this.http.put<Hospital>(`${this.apiUrl}/${id}`, updatedHospital);
  }

  // Delete a hospital by ID
  deleteHospital(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
