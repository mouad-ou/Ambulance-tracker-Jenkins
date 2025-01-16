import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Case } from '../models/case.model';

@Injectable({
  providedIn: 'root',
})
export class CaseService {
  private apiUrl = 'http://localhost:8888/dispatch-coordination-service/cases';

  constructor(private http: HttpClient) {}

  // Get all cases
  getAllCases(): Observable<Case[]> {
    return this.http.get<Case[]>(this.apiUrl);
  }

  // Get a single case by ID
  getCaseById(id: number): Observable<Case> {
    return this.http.get<Case>(`${this.apiUrl}/${id}`);
  }

  // Update a case
  updateCase(id: number, updatedCase: Case): Observable<Case> {
    return this.http.put<Case>(`${this.apiUrl}/${id}`, updatedCase);
  }

  deleteCase(id: number): Observable<void> {
    return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }
}
