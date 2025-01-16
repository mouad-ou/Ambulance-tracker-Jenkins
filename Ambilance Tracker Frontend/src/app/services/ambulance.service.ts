import { Injectable } from '@angular/core';
import {HttpClient, HttpHeaders} from '@angular/common/http';
import { Observable } from 'rxjs';
import {Ambulance} from "../models/ambulance.model";
import {AmbulanceDTOModel} from "../models/ambulanceDTO.model";


@Injectable({
  providedIn: 'root',
})
export class AmbulanceService {
  private apiUrl = 'http://localhost:8888/ambulance-service/ambulances'; // Base URL for the backend API

  constructor(private http: HttpClient) {}

  getAllAmbulances(): Observable<Ambulance[]> {
    return this.http.get<Ambulance[]>(`${this.apiUrl}`);
  }

  getAmbulanceById(id: number): Observable<Ambulance> {
    return this.http.get<Ambulance>(`${this.apiUrl}/${id}`);
  }

  createAmbulance(ambulance: AmbulanceDTOModel): Observable<Ambulance> {
    return this.http.post<Ambulance>(`${this.apiUrl}`, ambulance);
  }

  updateAmbulance(id: number, updatedAmbulance: {
  }): Observable<Ambulance> {
    return this.http.put<Ambulance>(`${this.apiUrl}/${id}`, updatedAmbulance);
  }

  updateAmbulanceLocation(id: number, latitude: number, longitude: number): Observable<Ambulance> {
    return this.http.put<Ambulance>(`${this.apiUrl}/${id}/location`, { latitude, longitude });
  }

  // Delete an ambulance by ID
  deleteAmbulance(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
