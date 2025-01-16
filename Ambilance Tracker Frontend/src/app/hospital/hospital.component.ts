import { Component, OnInit } from '@angular/core';
import { HospitalService } from '../services/hospital.service';
import { NgClass, NgForOf, NgIf } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Hospital } from '../models/hospital.model';

@Component({
  selector: 'app-hospital',
  standalone: true,
  imports: [FormsModule, NgClass, NgForOf, NgIf],
  templateUrl: './hospital.component.html',
  styleUrls: ['./hospital.component.css'],
})
export class HospitalComponent implements OnInit {
  hospitals: Hospital[] = [];
  filteredHospitals: Hospital[] = [];
  totalHospitals = 0;
  selectedHospital: Hospital | null = null;
  formHospital: Partial<Hospital> = { name: '', latitude: 0, longitude: 0, available: false, address: '', speciality: '' };
  showModal = false;
  confirmDeleteId: number | null = null;
  selectedStatus: string = 'All'; // Default filter value

  constructor(private hospitalService: HospitalService) {}

  ngOnInit(): void {
    this.loadHospitals();
  }

  loadHospitals(): void {
    this.hospitalService.getAllHospitals().subscribe((data) => {
      this.hospitals = data;
      this.filterHospitals();
      this.totalHospitals = this.hospitals.length;
    });
  }

  filterHospitals(): void {
    if (this.selectedStatus === 'All') {
      this.filteredHospitals = this.hospitals;
    } else if (this.selectedStatus === 'Available') {
      this.filteredHospitals = this.hospitals.filter((hospital) => hospital.available);
    } else {
      this.filteredHospitals = this.hospitals.filter((hospital) => !hospital.available);
    }
  }

  onStatusChange(): void {
    this.filterHospitals();
  }

  addHospital(): void {
    this.hospitalService.createHospital(this.formHospital as Hospital).subscribe(() => {
      this.loadHospitals();
      this.closeModal();
    });
  }

  editHospital(hospital: Hospital): void {
    this.selectedHospital = hospital;
    this.formHospital = { ...hospital }; // Pre-fill the form
    this.showModal = true;
  }

  updateHospital(): void {
    if (this.selectedHospital) {
      this.hospitalService.updateHospital(this.selectedHospital.id, this.formHospital as Hospital).subscribe(() => {
        this.loadHospitals();
        this.closeModal();
      });
    }
  }

  confirmDelete(id: number): void {
    this.confirmDeleteId = id;
  }

  deleteHospital(): void {
    if (this.confirmDeleteId !== null) {
      this.hospitalService.deleteHospital(this.confirmDeleteId).subscribe(() => {
        this.loadHospitals();
        this.confirmDeleteId = null;
      });
    }
  }

  closeModal(): void {
    this.showModal = false;
    this.confirmDeleteId = null;
    this.selectedHospital = null;
    this.formHospital = { name: '', latitude: 0, longitude: 0, available: false, address:"",speciality:"" }; // Reset form
  }
}
