import { Component, OnInit, OnDestroy } from '@angular/core';
import * as mapboxgl from 'mapbox-gl';
import * as polyline from '@mapbox/polyline';
import { CaseService } from '../services/case.service';
import { HospitalService } from '../services/hospital.service';
import { AmbulanceService } from '../services/ambulance.service';
import { WebsocketService, AmbulanceLocation } from '../services/websocket.service';
import { Case } from '../models/case.model';
import { Hospital } from '../models/hospital.model';
import { Ambulance } from '../models/ambulance.model';
import { Subscription } from 'rxjs';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent implements OnInit, OnDestroy {
  private map!: mapboxgl.Map;
  private ambulanceMarkers: { [key: string]: mapboxgl.Marker } = {};
  private activeRoutes = new Map<number, { sourceId: string; layerId: string; markers: mapboxgl.Marker[] }>();
  private websocketSubscription?: Subscription;
  private locationSubscription?: Subscription;
  private readonly REFRESH_INTERVAL = 2000;
  private readonly routeColors: string[] = [
    '#e74c3c', '#3498db', '#2ecc71', '#f1c40f', '#9b59b6',
    '#e67e22', '#1abc9c', '#34495e', '#d35400', '#27ae60'
  ];

  availableAmbulances: number = 0;
  availableHospitals: number = 0;
  activeCases: number = 0;
  activeRouteCount: number = 0;
  showAmbulances: boolean = true;

  constructor(
    private caseService: CaseService,
    private hospitalService: HospitalService,
    private ambulanceService: AmbulanceService,
    private websocketService: WebsocketService
  ) {}

  ngOnInit(): void {
    this.initializeMap();
    this.loadInitialData();
    this.startDataRefresh();
    this.setupWebSocket();
  }

  ngOnDestroy(): void {
    if (this.websocketSubscription) {
      this.websocketSubscription.unsubscribe();
    }
    if (this.locationSubscription) {
      this.locationSubscription.unsubscribe();
    }
    Object.values(this.ambulanceMarkers).forEach(marker => marker.remove());
    this.clearRoutes();
  }

  private initializeMap(): void {
    this.map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/yacinemansour/cm4u3ppqk003d01sa0bch87jn',
      center: [-7.9811, 31.6295],
      zoom: 12,
      accessToken: 'pk.eyJ1IjoieWFjaW5lbWFuc291ciIsImEiOiJjbTRzbTBuZmowMnAxMnBzZ3ozZWNyMTQ1In0.MuCDPa78D1cgrKqm3LDX2Q',
    });
  }

  private loadInitialData(): void {
    this.loadAmbulances();
    this.loadHospitalData();
    this.loadCases();
  }

  private startDataRefresh(): void {
    setInterval(() => {
      this.loadAmbulances();
      this.loadHospitalData();
      this.loadCases();
    }, this.REFRESH_INTERVAL);
  }

  private setupWebSocket(): void {
    this.locationSubscription = this.websocketService.getAmbulanceLocations().subscribe({
      next: (locations: AmbulanceLocation[]) => {
        locations.forEach(location => {
          const marker = this.ambulanceMarkers[location.ambulanceId];
          if (marker) {
            marker.setLngLat([location.longitude, location.latitude]);
          }
        });
      },
      error: (error: Error) => console.error('Error receiving ambulance locations:', error)
    });
  }

  loadAmbulances(): void {
    this.ambulanceService.getAllAmbulances().subscribe({
      next: (ambulances) => {
        console.log('Received ambulances:', ambulances);
        this.availableAmbulances = ambulances.filter(amb => amb.available).length;
        
        ambulances.forEach(ambulance => {
          const existingMarker = this.ambulanceMarkers[ambulance.id.toString()];
          if (existingMarker) {
            this.updateAmbulanceLocation(ambulance);
          } else {
            this.addAmbulanceMarker(ambulance);
          }
        });

        // Remove markers for ambulances that no longer exist
        Object.keys(this.ambulanceMarkers).forEach(id => {
          if (!ambulances.some(a => a.id.toString() === id)) {
            this.removeAmbulanceMarker(id);
          }
        });
      },
      error: (error: Error) => {
        console.error('Error loading ambulances:', error);
      }
    });
  }

  loadHospitalData(): void {
    this.hospitalService.getAllHospitals().subscribe({
      next: (hospitals) => {
        console.log('Received hospitals:', hospitals);
        this.availableHospitals = hospitals.filter(h => h.available).length;
        
        hospitals.forEach(hospital => {
          if (hospital.latitude && hospital.longitude) {
            const marker = new mapboxgl.Marker({ color: '#50B7F5' })
              .setLngLat([hospital.longitude, hospital.latitude])
              .setPopup(new mapboxgl.Popup().setHTML(
                `<h3>${hospital.name}</h3>
                <p>Status: ${hospital.available ? 'Available' : 'Unavailable'}</p>
                <p>Available Beds: ${hospital.availableBeds || 'N/A'}</p>
                <p>Speciality: ${hospital.speciality || 'General'}</p>`
              ))
              .addTo(this.map);
          }
        });
      },
      error: (error: Error) => {
        console.error('Error loading hospitals:', error);
      }
    });
  }

  private updateAmbulanceLocation(ambulance: Ambulance): void {
    const marker = this.ambulanceMarkers[ambulance.id.toString()];
    if (marker) {
      marker.setLngLat([ambulance.longitude, ambulance.latitude]);
    }
  }

  private addAmbulanceMarker(ambulance: Ambulance): void {
    const el = document.createElement('div');
    el.className = 'ambulance-marker';
    el.style.backgroundImage = 'url(/icons/ambulance.png)';
    el.style.width = '32px';
    el.style.height = '32px';
    el.style.backgroundSize = 'contain';
    el.style.cursor = 'pointer';

    const popup = new mapboxgl.Popup({ offset: 25 })
      .setHTML(`
        <div class="ambulance-popup">
          <h3>Ambulance ${ambulance.id}</h3>
          <p>Driver: ${ambulance.driverName}</p>
          <p>Status: ${ambulance.available ? 'Available' : 'On Call'}</p>
        </div>
      `);

    const marker = new mapboxgl.Marker(el)
      .setLngLat([ambulance.longitude, ambulance.latitude])
      .setPopup(popup)
      .addTo(this.map);

    this.ambulanceMarkers[ambulance.id.toString()] = marker;
  }

  private removeAmbulanceMarker(id: string): void {
    const marker = this.ambulanceMarkers[id];
    if (marker) {
      marker.remove();
      delete this.ambulanceMarkers[id];
    }
  }

  toggleAmbulances(): void {
    this.showAmbulances = !this.showAmbulances;
    Object.values(this.ambulanceMarkers).forEach(marker => {
      if (this.showAmbulances) {
        marker.addTo(this.map);
      } else {
        marker.remove();
      }
    });
  }

  showAllRoutes(): void {
    this.loadCases();
  }

  clearRoutes(): void {
    this.activeRoutes.forEach((route, caseId) => {
      this.removeRoute(caseId);
    });
    this.activeRoutes.clear();
    this.activeRouteCount = 0;
  }

  loadCases(): void {
    console.log('Loading cases...');
    this.caseService.getAllCases().subscribe({
      next: (cases) => {
        console.log('Received all cases:', cases);
        // Filter out closed cases
        const activeCases = cases.filter(caseItem => caseItem.status !== 'CLOSED');
        console.log('Active cases:', activeCases);
        
        // Update active cases count
        this.activeCases = activeCases.length;

        // Clear routes that are no longer active
        this.activeRoutes.forEach((route, caseId) => {
          if (!activeCases.some(c => c.id === caseId)) {
            this.removeRoute(caseId);
          }
        });

        // Add routes for active cases
        activeCases.forEach(caseItem => {
          if (!this.activeRoutes.has(caseItem.id)) {
            const routeData = caseItem.routePolyline || caseItem.routeGeometry;
            if (routeData) {
              console.log('Adding route for active case:', caseItem.id, 'with route data:', routeData);
              this.addRoute(caseItem, this.routeColors[this.activeRouteCount % this.routeColors.length]);
            }
          }
        });
      },
      error: (error: Error) => {
        console.error('Error loading cases:', error);
      }
    });
  }

  addRoute(caseItem: Case, color: string): void {
    const routeData = caseItem.routePolyline || caseItem.routeGeometry;
    if (!routeData || routeData.trim() === '') {
      console.error('Invalid route data for case:', caseItem.id);
      return;
    }

    try {
      console.log('Decoding route data for case:', caseItem.id);
      const coordinates: Array<[number, number]> = polyline.decode(routeData)
        .map((point: [number, number]) => [point[1], point[0]]);

      console.log('Decoded coordinates:', coordinates);
      const sourceId = `route-source-${caseItem.id}`;
      const layerId = `route-layer-${caseItem.id}`;

      // Add the source if it doesn't exist
      if (!this.map.getSource(sourceId)) {
        this.map.addSource(sourceId, {
          type: 'geojson',
          data: {
            type: 'Feature',
            geometry: {
              type: 'LineString',
              coordinates,
            },
            properties: {} as any,
          } as GeoJSON.Feature<GeoJSON.Geometry>,
        });
      }

      // Add the layer if it doesn't exist
      if (!this.map.getLayer(layerId)) {
        this.map.addLayer({
          id: layerId,
          type: 'line',
          source: sourceId,
          layout: {
            'line-join': 'round',
            'line-cap': 'round',
          },
          paint: {
            'line-color': color,
            'line-width': 3,
          },
        });
      }

      // Store the route information
      this.activeRoutes.set(caseItem.id, {
        sourceId,
        layerId,
        markers: [],
      });

      this.activeRouteCount++;
      console.log('Successfully added route for case:', caseItem.id);
    } catch (error) {
      console.error('Error adding route:', error);
    }
  }

  removeRoute(caseId: number): void {
    console.log('Removing route for case:', caseId);
    const route = this.activeRoutes.get(caseId);
    if (route) {
      try {
        if (this.map.getLayer(route.layerId)) {
          this.map.removeLayer(route.layerId);
        }
        if (this.map.getSource(route.sourceId)) {
          this.map.removeSource(route.sourceId);
        }
        route.markers.forEach(marker => marker.remove());
        this.activeRoutes.delete(caseId);
        this.activeRouteCount--;
        console.log('Successfully removed route for case:', caseId);
      } catch (error) {
        console.error('Error removing route:', error);
      }
    }
  }
}
