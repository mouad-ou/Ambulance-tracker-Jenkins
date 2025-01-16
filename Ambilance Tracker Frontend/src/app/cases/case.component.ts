import { Component, OnInit, OnDestroy } from '@angular/core';
import * as mapboxgl from 'mapbox-gl';
import * as polylineUtil from '@mapbox/polyline';
import { CaseService } from '../services/case.service';
import { WebsocketService } from '../services/websocket.service';
import { AmbulanceService } from '../services/ambulance.service';
import { NgForOf, NgIf } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Case } from '../models/case.model';
import { Ambulance } from '../models/ambulance.model';
import { Subscription } from 'rxjs';

interface RouteLayer {
  routeId: string;
  sourceId: string;
  layerId: string;
  markers: mapboxgl.Marker[];
}

interface AmbulanceMarker {
  marker: mapboxgl.Marker;
  popup: mapboxgl.Popup;
  ambulanceData: Ambulance;
  isOnline: boolean;
}

@Component({
  selector: 'app-cases',
  standalone: true,
  imports: [NgForOf, FormsModule, NgIf],
  templateUrl: './case.component.html',
  styleUrls: ['./case.component.css'],
})
export class CaseComponent implements OnInit, OnDestroy {
  map!: mapboxgl.Map;
  cases: Case[] = [];
  ambulances: Map<number, AmbulanceMarker> = new Map();
  activeRoutes: Map<number, RouteLayer> = new Map();
  activeRouteCount: number = 0;
  showAmbulances: boolean = true;
  private locationSubscription?: Subscription;
  private casesRefreshInterval?: any;
  private ambulanceRefreshInterval?: any;
  private readonly REFRESH_INTERVAL = 2000; // 2 seconds

  routeColors: string[] = [
    '#e74c3c', '#3498db', '#2ecc71', '#f1c40f', '#9b59b6',
    '#e67e22', '#1abc9c', '#34495e', '#d35400', '#27ae60'
  ];

  get filteredCases(): Case[] {
    return this.cases;
  }

  constructor(
    private caseService: CaseService,
    private ambulanceService: AmbulanceService,
    private webSocketService: WebsocketService
  ) {}

  ngOnInit(): void {
    this.initializeMap();
    this.loadCases();
    this.initializeAmbulances();
    this.startCasesRefresh();
    this.startAmbulanceRefresh();
    this.initializeWebSocket();
  }

  ngOnDestroy(): void {
    this.clearRoutes();
    this.clearAmbulances();
    if (this.map) {
      this.map.remove();
    }
    if (this.locationSubscription) {
      this.locationSubscription.unsubscribe();
    }
    if (this.casesRefreshInterval) {
      clearInterval(this.casesRefreshInterval);
    }
    if (this.ambulanceRefreshInterval) {
      clearInterval(this.ambulanceRefreshInterval);
    }
  }

  private startCasesRefresh(): void {
    // Initial load
    this.loadCases();
    
    // Set up interval for periodic refresh
    this.casesRefreshInterval = setInterval(() => {
      this.loadCases();
    }, this.REFRESH_INTERVAL);
  }

  private startAmbulanceRefresh(): void {
    // Initial load
    this.loadAmbulances();
    
    // Set up interval for periodic refresh
    this.ambulanceRefreshInterval = setInterval(() => {
      this.loadAmbulances();
    }, this.REFRESH_INTERVAL);
  }

  private initializeWebSocket(): void {
    const connectWebSocket = () => {
      this.locationSubscription = this.webSocketService
        .getAmbulanceLocations()
        .subscribe({
          next: (locations) => {
            locations.forEach(location => {
              const ambulanceId = parseInt(location.ambulanceId);
              const existingAmbulance = this.ambulances.get(ambulanceId);
              if (existingAmbulance) {
                const updatedAmbulance: Ambulance = {
                  ...existingAmbulance.ambulanceData,
                  latitude: location.latitude,
                  longitude: location.longitude
                };
                this.updateAmbulanceLocation(updatedAmbulance);
              }
            });
          },
          error: (err) => {
            console.error('WebSocket error:', err);
            // Try to reconnect after a delay
            setTimeout(() => {
              console.log('Attempting to reconnect WebSocket...');
              this.locationSubscription?.unsubscribe();
              connectWebSocket();
            }, 5000); // 5 second delay before reconnect
          }
        });
    };

    // Initial connection
    connectWebSocket();
  }

  loadCases(): void {
    this.caseService.getAllCases().subscribe({
      next: (data) => {
        const previousCases = new Map(this.cases.map(c => [c.id, c]));
        this.cases = data.map((caseItem) => ({
          ...caseItem,
          routePolyline: caseItem.routeGeometry,
        }));

        // Check for changes
        let hasChanges = false;
        if (previousCases.size !== this.cases.length) {
          hasChanges = true;
        } else {
          for (const newCase of this.cases) {
            const oldCase = previousCases.get(newCase.id);
            if (!oldCase || 
                oldCase.status !== newCase.status || 
                oldCase.routeGeometry !== newCase.routeGeometry) {
              hasChanges = true;
              break;
            }
          }
        }

        // Only update routes if there are changes
        if (hasChanges) {
          console.log('Cases updated, refreshing routes...');
          this.showAllRoutes();
        }
      },
      error: (err) => {
        console.error('Error fetching cases:', err);
        // Optionally show an error message to the user
      },
    });
  }

  private loadAmbulances(): void {
    this.ambulanceService.getAllAmbulances().subscribe({
      next: (ambulances) => {
        // Store current ambulances for comparison
        const currentAmbulances = new Map(Array.from(this.ambulances.entries())
          .map(([id, data]) => [id, data.ambulanceData]));

        // Process each ambulance
        ambulances.forEach(ambulance => {
          const existing = currentAmbulances.get(ambulance.id);
          if (!existing || 
              existing.available !== ambulance.available || 
              existing.latitude !== ambulance.latitude || 
              existing.longitude !== ambulance.longitude || 
              existing.currentCaseId !== ambulance.currentCaseId) {
            // Update only if there are changes
            this.addAmbulanceMarker(ambulance);
          }
        });

        // Remove ambulances that no longer exist
        this.ambulances.forEach((_, id) => {
          if (!ambulances.find(a => a.id === id)) {
            this.removeAmbulanceMarker(id);
          }
        });
      },
      error: (err) => {
        console.error('Error fetching ambulances:', err);
      }
    });
  }

  private initializeAmbulances(): void {
    // Initial load is now handled by startAmbulanceRefresh
    this.loadAmbulances();
  }

  private initializeMap(): void {
    this.map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/yacinemansour/cm4u3ppqk003d01sa0bch87jn',
      center: [-7.9811, 31.6295],
      zoom: 12,
      accessToken: 'pk.eyJ1IjoieWFjaW5lbWFuc291ciIsImEiOiJjbTRzbTBuZmowMnAxMnBzZ3ozZWNyMTQ1In0.MuCDPa78D1cgrKqm3LDX2Q',
    });

    // Wait for map to load before adding routes
    this.map.on('load', () => {
      // Map is ready, routes will be added after cases are loaded
      console.log('Map loaded and ready for routes');
    });
  }

  showAllRoutes(): void {
    this.clearRoutes();
    this.cases.forEach((caseItem, index) => {
      if (caseItem.routePolyline) {
        this.addRoute(caseItem, this.routeColors[index % this.routeColors.length]);
      }
    });

    // Fit map to show all routes
    if (this.activeRoutes.size > 0) {
      const bounds = new mapboxgl.LngLatBounds();
      this.activeRoutes.forEach(route => {
        if (this.map.getSource(route.sourceId)) {
          const source = this.map.getSource(route.sourceId) as mapboxgl.GeoJSONSource;
          const data = source.serialize().data as GeoJSON.Feature<GeoJSON.LineString>;
          data.geometry.coordinates.forEach(coord => {
            bounds.extend(coord as mapboxgl.LngLatLike);
          });
        }
      });
      this.map.fitBounds(bounds, { padding: 50 });
    }
  }

  clearRoutes(): void {
    this.activeRoutes.forEach(route => {
      // Remove layers and sources
      if (this.map.getLayer(route.layerId)) {
        this.map.removeLayer(route.layerId);
      }
      if (this.map.getSource(route.sourceId)) {
        this.map.removeSource(route.sourceId);
      }
      // Remove markers
      route.markers.forEach(marker => marker.remove());
    });
    this.activeRoutes.clear();
    this.activeRouteCount = 0;
  }

  toggleRoute(caseItem: Case): void {
    const caseId = caseItem.id;
    if (this.activeRoutes.has(caseId)) {
      this.removeRoute(caseId);
    } else {
      const colorIndex = this.activeRoutes.size % this.routeColors.length;
      this.addRoute(caseItem, this.routeColors[colorIndex]);
    }
  }

  isRouteActive(caseId: number): boolean {
    return this.activeRoutes.has(caseId);
  }

  private addRoute(caseItem: Case, color: string): void {
    if (!caseItem.routePolyline || caseItem.routePolyline.trim() === '') {
      console.error('Invalid route polyline for case:', caseItem.id);
      return;
    }

    const coordinates: Array<[number, number]> = polylineUtil.decode(caseItem.routePolyline)
      .map((point: [number, number]) => [point[1], point[0]]);

    const sourceId = `route-source-${caseItem.id}`;
    const layerId = `route-layer-${caseItem.id}`;

    // Add the route source
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

    // Add the route layer
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
        'line-width': 4,
        'line-opacity': 0.8,
      },
    });

    // Add start and end markers
    const markers: mapboxgl.Marker[] = [];

    // Start marker
    const startEl = document.createElement('div');
    startEl.className = 'start-marker';
    const startMarker = new mapboxgl.Marker(startEl)
      .setLngLat(coordinates[0])
      .setPopup(new mapboxgl.Popup().setHTML(`
        <div class="popup-content">
          <h4>Start Point</h4>
          <p>Case #${caseItem.id}</p>
          <p>Status: ${caseItem.status}</p>
        </div>
      `))
      .addTo(this.map);
    markers.push(startMarker);

    // End marker
    const endEl = document.createElement('div');
    endEl.className = 'end-marker';
    const endMarker = new mapboxgl.Marker(endEl)
      .setLngLat(coordinates[coordinates.length - 1])
      .setPopup(new mapboxgl.Popup().setHTML(`
        <div class="popup-content">
          <h4>End Point</h4>
          <p>Case #${caseItem.id}</p>
          <p>Hospital ID: ${caseItem.assignedHospitalId}</p>
        </div>
      `))
      .addTo(this.map);
    markers.push(endMarker);

    // Store the route information
    this.activeRoutes.set(caseItem.id, {
      routeId: caseItem.id.toString(),
      sourceId,
      layerId,
      markers,
    });

    this.activeRouteCount = this.activeRoutes.size;
  }

  private removeRoute(caseId: number): void {
    const route = this.activeRoutes.get(caseId);
    if (route) {
      if (this.map.getLayer(route.layerId)) {
        this.map.removeLayer(route.layerId);
      }
      if (this.map.getSource(route.sourceId)) {
        this.map.removeSource(route.sourceId);
      }
      route.markers.forEach(marker => marker.remove());
      this.activeRoutes.delete(caseId);
      this.activeRouteCount = this.activeRoutes.size;
    }
  }

  private addAmbulanceMarker(ambulance: Ambulance): void {
    // Remove existing marker if any
    this.removeAmbulanceMarker(ambulance.id);

    // Create marker element
    const el = document.createElement('div');
    el.className = 'ambulance-marker';
    el.style.backgroundImage = 'url(icons/ambulance.png)';
    el.style.width = '32px';
    el.style.height = '32px';
    el.style.backgroundSize = 'contain';
    el.style.cursor = 'pointer';
    el.classList.add(ambulance.available ? 'available' : 'busy');

    // Create popup
    const popup = new mapboxgl.Popup({ offset: 25 }).setHTML(`
      <div class="ambulance-popup">
        <h3>Ambulance ${ambulance.id}</h3>
        <p>Driver: ${ambulance.driverName}</p>
        <p>Status: ${ambulance.available ? 'Available' : 'Busy'}</p>
        ${ambulance.currentCaseId ? `<p>Current Case: ${ambulance.currentCaseId}</p>` : ''}
      </div>
    `);

    // Create marker
    const marker = new mapboxgl.Marker(el)
      .setLngLat([ambulance.longitude, ambulance.latitude])
      .setPopup(popup);

    if (this.showAmbulances) {
      marker.addTo(this.map);
    }

    this.ambulances.set(ambulance.id, {
      marker,
      popup,
      ambulanceData: ambulance,
      isOnline: true
    });
  }

  private updateAmbulanceLocation(ambulance: Ambulance): void {
    const ambulanceMarker = this.ambulances.get(ambulance.id);
    if (ambulanceMarker) {
      const { marker, popup } = ambulanceMarker;
      marker.setLngLat([ambulance.longitude, ambulance.latitude]);

      // Update popup content
      popup.setHTML(`
        <div class="ambulance-popup">
          <h3>Ambulance ${ambulance.id}</h3>
          <p>Driver: ${ambulance.driverName}</p>
          <p>Status: ${ambulance.available ? 'Available' : 'Busy'}</p>
          ${ambulance.currentCaseId ? `<p>Current Case: ${ambulance.currentCaseId}</p>` : ''}
        </div>
      `);

      // Update marker status class
      const el = marker.getElement();
      el.classList.remove('available', 'busy');
      el.classList.add(ambulance.available ? 'available' : 'busy');

      // Update stored data
      this.ambulances.set(ambulance.id, {
        marker,
        popup,
        ambulanceData: ambulance,
        isOnline: true
      });
    } else {
      this.addAmbulanceMarker(ambulance);
    }
  }

  private removeAmbulanceMarker(ambulanceId: number): void {
    const ambulanceMarker = this.ambulances.get(ambulanceId);
    if (ambulanceMarker) {
      ambulanceMarker.marker.remove();
      this.ambulances.delete(ambulanceId);
    }
  }

  private clearAmbulances(): void {
    this.ambulances.forEach(({ marker }) => marker.remove());
    this.ambulances.clear();
  }

  toggleAmbulances(): void {
    this.showAmbulances = !this.showAmbulances;
    this.ambulances.forEach(({ marker }) => {
      if (this.showAmbulances) {
        marker.addTo(this.map);
      } else {
        marker.remove();
      }
    });
  }

  removeCase(id: number): void {
    if (confirm('Are you sure you want to delete this case?')) {
      this.caseService.deleteCase(id).subscribe({
        next: () => {
          // Remove the case's route if it's active
          this.removeRoute(id);
          // Remove the case from the local array
          this.cases = this.cases.filter(c => c.id !== id);
          console.log('Case deleted successfully');
        },
        error: (error) => {
          console.error('Error deleting case:', error);
        }
      });
    }
  }
}
