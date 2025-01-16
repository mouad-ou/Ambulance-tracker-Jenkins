import { Component, OnInit, OnDestroy } from '@angular/core';
import { AmbulanceService } from '../services/ambulance.service';
import { WebsocketService } from '../services/websocket.service';
import { Ambulance } from '../models/ambulance.model';
import {NgClass, NgForOf, NgIf, DecimalPipe} from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClientModule } from '@angular/common/http';
import { Subscription } from 'rxjs';
import * as mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';

@Component({
  selector: 'app-ambulance',
  standalone: true,
  imports: [
    FormsModule,
    NgClass,
    NgForOf,
    HttpClientModule,
    NgIf,
    DecimalPipe
  ],
  templateUrl: './ambulance.component.html',
  styleUrls: ['./ambulance.component.css'],
})
export class AmbulanceComponent implements OnInit, OnDestroy {
  ambulances: Ambulance[] = [];
  totalAmbulances = 0;
  availableAmbulances = 0;
  selectedStatus = 'All';
  newAmbulance: { latitude: number; available: boolean; driverName: string; longitude: number } = { driverName: '', available: false, latitude: 0, longitude: 0 };
  updateAmbulance: Ambulance | null = null;
  showModal = false;
  confirmDeleteId: number | null = null;
  private locationSubscription?: Subscription;
  private map!: mapboxgl.Map;
  private ambulanceMarkers: { [key: string]: mapboxgl.Marker } = {};

  constructor(
    private ambulanceService: AmbulanceService,
    private websocketService: WebsocketService
  ) {}

  ngOnInit(): void {
    this.loadAmbulances();
    this.initializeMap();
    this.subscribeToLocationUpdates();
  }

  ngOnDestroy(): void {
    if (this.locationSubscription) {
      this.locationSubscription.unsubscribe();
    }
    // Remove all markers
    Object.values(this.ambulanceMarkers).forEach(marker => marker.remove());
    // Cleanup map
    if (this.map) {
      this.map.remove();
    }
  }

  private initializeMap(): void {
    this.map = new mapboxgl.Map({
      container: 'ambulance-map',
      style: 'mapbox://styles/yacinemansour/cm4u3ppqk003d01sa0bch87jn',
      center: [-7.9811, 31.6295],
      zoom: 12,
      accessToken: 'pk.eyJ1IjoieWFjaW5lbWFuc291ciIsImEiOiJjbTRzbTBuZmowMnAxMnBzZ3ozZWNyMTQ1In0.MuCDPa78D1cgrKqm3LDX2Q',
    });

    this.map.on('load', () => {
      this.addAmbulanceMarkers();
    });
  }

  private addAmbulanceMarkers(): void {
    this.ambulances.forEach(ambulance => {
      // Create marker element
      const el = document.createElement('div');
      el.className = 'ambulance-marker';
      el.style.backgroundImage = 'url(/icons/ambulance.png)';
      el.style.width = '32px';
      el.style.height = '32px';
      el.style.backgroundSize = 'contain';
      el.style.cursor = 'pointer';

      // Add popup
      const popup = new mapboxgl.Popup({ offset: 25 })
        .setHTML(`
          <div class="ambulance-popup">
            <h3>Ambulance ${ambulance.id}</h3>
            <p>Driver: ${ambulance.driverName}</p>
            <p>Status: ${ambulance.available ? 'Available' : 'Busy'}</p>
          </div>
        `);

      // Create and store the marker
      const marker = new mapboxgl.Marker(el)
        .setLngLat([ambulance.longitude, ambulance.latitude])
        .setPopup(popup)
        .addTo(this.map);

      this.ambulanceMarkers[ambulance.id] = marker;
    });
  }

  private subscribeToLocationUpdates(): void {
    this.locationSubscription = this.websocketService.getAmbulanceLocations().subscribe(
      locations => {
        locations.forEach(location => {
          const ambulanceId = location.ambulanceId;
          const marker = this.ambulanceMarkers[ambulanceId];
          
          if (marker) {
            // Update marker position with smooth animation
            marker.setLngLat([location.longitude, location.latitude]);
          }

          // Update ambulance data
          const ambulance = this.ambulances.find(a => a.id === Number(ambulanceId));
          if (ambulance) {
            ambulance.latitude = location.latitude;
            ambulance.longitude = location.longitude;
          }
        });
      },
      error => {
        console.error('Error receiving ambulance locations:', error);
      }
    );
  }

  loadAmbulances(): void {
    this.ambulanceService.getAllAmbulances().subscribe((data) => {
      this.ambulances = data;
      this.totalAmbulances = data.length;
      this.availableAmbulances = data.filter((a) => a.available).length;
      if (this.map) {
        this.addAmbulanceMarkers();
      }
    });
  }

  addAmbulance(): void {
    this.ambulanceService.createAmbulance(this.newAmbulance).subscribe((ambulance) => {
      this.ambulances.push(ambulance);
      this.newAmbulance = {  driverName: '', available: false, latitude: 0, longitude: 0  };
      this.loadAmbulances();
      this.closeModal();
    });
  }

  startUpdate(ambulance: Ambulance): void {
    this.updateAmbulance = { ...ambulance };
    this.showModal = true;
  }

  updateExistingAmbulance(): void {
    if (this.updateAmbulance) {
      this.ambulanceService.updateAmbulance(this.updateAmbulance.id, this.updateAmbulance).subscribe(() => {
        this.loadAmbulances();
        this.updateAmbulance = null;
        this.closeModal();
      });
    }
  }

  confirmDelete(id: number): void {
    this.confirmDeleteId = id;
  }

  deleteAmbulance(): void {
    if (this.confirmDeleteId !== null) {
      this.ambulanceService.deleteAmbulance(this.confirmDeleteId).subscribe(() => {
        this.loadAmbulances();
        this.confirmDeleteId = null;
      });
    }
  }

  closeModal(): void {
    this.showModal = false;
    this.updateAmbulance = null;
  }

  get filteredAmbulances() {
    if (this.selectedStatus === 'All') {
      return this.ambulances;
    }
    const isAvailable = this.selectedStatus === 'Available';
    return this.ambulances.filter((ambulance) => ambulance.available === isAvailable);
  }
}
