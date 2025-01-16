import { Injectable } from '@angular/core';
import { Client } from '@stomp/stompjs';
import { BehaviorSubject } from 'rxjs';

export interface AmbulanceLocation {
  ambulanceId: string;
  latitude: number;
  longitude: number;
}

@Injectable({
  providedIn: 'root',
})
export class WebsocketService {
  private client: Client;
  private ambulanceLocations = new BehaviorSubject<AmbulanceLocation[]>([]);

  constructor() {
    this.client = new Client({
      brokerURL: `ws://localhost:8888/ambulance-service/ws`, // Direct WebSocket URL
      connectHeaders: {},
      debug: (str: string) => {
        console.log(str);
      },
      reconnectDelay: 5000,
      heartbeatIncoming: 4000,
      heartbeatOutgoing: 4000,
    });

    this.client.onConnect = () => {
      console.log('Connected to WebSocket');
      this.subscribeToAmbulanceUpdates();
    };

    this.client.onStompError = (frame) => {
      console.error('Broker reported error: ' + frame.headers['message']);
      console.error('Additional details: ' + frame.body);
    };

    this.client.onWebSocketError = (event) => {
      console.error('WebSocket error:', event);
    };

    this.client.activate();
  }

  private subscribeToAmbulanceUpdates() {
    this.client.subscribe('/topic/ambulance-locations', (message) => {
      const locations = JSON.parse(message.body); // Parse the received message
      console.log('Received ambulance locations:', locations); // Log the locations
      this.ambulanceLocations.next(locations); // Update the BehaviorSubject
    });
  }

  getAmbulanceLocations() {
    return this.ambulanceLocations.asObservable();
  }

  disconnect() {
    if (this.client) {
      this.client.deactivate();
    }
  }
}
