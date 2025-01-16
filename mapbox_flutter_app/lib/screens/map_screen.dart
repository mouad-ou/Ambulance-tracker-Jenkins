import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/emergency_footer.dart';
import '../widgets/location_button.dart';
import '../widgets/ambulance_marker.dart';
import '../widgets/hospital_marker.dart';
import '../widgets/case_status_bar.dart';
import '../models/emergency_request.dart';
import '../models/ambulance_info.dart';
import '../models/hospital_info.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isLoading = true;
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  final Location _location = Location();
  List<LatLng>? _routePoints;
  AmbulanceInfo? _assignedAmbulance;
  HospitalInfo? _assignedHospital;
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription? _locationSubscription;
  Timer? _locationUpdateTimer;
  Timer? _caseStatusTimer;
  EmergencyCaseStatus _caseStatus = EmergencyCaseStatus.waitingForAmbulance;
  final Distance _distance = const Distance();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _webSocketService.dispose();
    _locationUpdateTimer?.cancel();
    _caseStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      await _getCurrentLocation();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _location.getLocation();
      setState(() {
        _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _centerOnLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15);
    }
  }

  void _handleEmergencyResponse(EmergencyResponse response) {
    if (response.routePolyline != null && response.assignedAmbulance != null) {
      setState(() {
        // Decode route geometry
        _routePoints = _decodeRouteGeometry(response.routePolyline!);
        _assignedAmbulance = response.assignedAmbulance;
        _assignedHospital = response.assignedHospital;
        _caseStatus = EmergencyCaseStatus.ambulanceDispatched;
      });

      // Start WebSocket connection for ambulance updates
      if (response.assignedAmbulance?.id != null) {
        _startAmbulanceUpdates(response.assignedAmbulance!.id);
      }

      // First show the entire route
      if (_routePoints != null && _routePoints!.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(_routePoints!);
        _mapController.fitBounds(
          bounds,
          options: const FitBoundsOptions(padding: EdgeInsets.all(50.0)),
        );

        // Then after a short delay, zoom in on the ambulance with 3D effect
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _focusOnAmbulanceWithAnimation();
          }
        });
      }
    }
  }

  void _focusOnAmbulanceWithAnimation() {
    if (_assignedAmbulance != null) {
      final ambulanceLocation = LatLng(
        _assignedAmbulance!.latitude,
        _assignedAmbulance!.longitude,
      );
      
      // Calculate bearing between ambulance and user
      if (_currentLocation != null) {
        final bearing = _calculateBearing(
          ambulanceLocation.latitude,
          ambulanceLocation.longitude,
          _currentLocation!.latitude,
          _currentLocation!.longitude,
        );

        // Calculate camera position behind ambulance
        final distanceBehind = 0.0003; // Approximately 30-40 meters behind
        final bearingRadians = bearing * pi / 180;
        
        // Calculate camera position behind ambulance
        final cameraLat = ambulanceLocation.latitude - 
            (distanceBehind * cos(bearingRadians));
        final cameraLng = ambulanceLocation.longitude - 
            (distanceBehind * sin(bearingRadians));

        // Animate the transition
        _animateToPosition(
          LatLng(cameraLat, cameraLng),
          bearing,
          16.5, // Slightly lower zoom level for better context
          const Duration(milliseconds: 1000),
        );
      }
    }
  }

  void _animateToPosition(LatLng target, double bearing, double zoom, Duration duration) {
    const fps = 60.0;
    final steps = (duration.inMilliseconds / 1000 * fps).round();
    
    final startCenter = _mapController.center;
    final startZoom = _mapController.zoom;
    final startBearing = _mapController.rotation;

    int step = 0;
    Timer.periodic(Duration(milliseconds: (1000 / fps).round()), (timer) {
      if (!mounted || step >= steps) {
        timer.cancel();
        return;
      }

      final progress = step / steps;
      // Use ease out cubic for smooth animation
      final easedProgress = 1 - pow(1 - progress, 3);

      final lat = startCenter.latitude + (target.latitude - startCenter.latitude) * easedProgress;
      final lng = startCenter.longitude + (target.longitude - startCenter.longitude) * easedProgress;
      final newZoom = startZoom + (zoom - startZoom) * easedProgress;
      
      // Calculate the shortest rotation path
      var bearingDiff = (bearing - startBearing) % 360;
      if (bearingDiff > 180) bearingDiff -= 360;
      if (bearingDiff < -180) bearingDiff += 360;
      final newBearing = startBearing + bearingDiff * easedProgress;

      _mapController.move(
        LatLng(lat, lng),
        newZoom,
      );
      _mapController.rotate(newBearing);

      step++;
    });
  }

  void _startAmbulanceUpdates(int ambulanceId) {
    // Cancel existing subscriptions if any
    _locationSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _caseStatusTimer?.cancel();

    // Connect to WebSocket
    _webSocketService.connectToAmbulanceUpdates(ambulanceId);

    // Subscribe to WebSocket updates
    _locationSubscription = _webSocketService.ambulanceLocations?.listen(
      (ambulance) {
        if (mounted) {
          setState(() {
            _assignedAmbulance = ambulance;
          });
          // Update camera to follow ambulance
          _updateAmbulanceCamera();
        }
      },
      onError: (error) {
        debugPrint('Error receiving ambulance updates: $error');
      },
    );

    // Start periodic HTTP updates as backup
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      
      final ambulance = await ApiService.getAmbulanceLocation(ambulanceId);
      if (ambulance != null && mounted) {
        setState(() {
          _assignedAmbulance = ambulance;
        });
        // Update camera to follow ambulance
        _updateAmbulanceCamera();
      }
    });

    // Start case status updates
    _caseStatusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _assignedAmbulance == null || _currentLocation == null) return;

      final userLocation = LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
      final ambulanceLocation = LatLng(_assignedAmbulance!.latitude, _assignedAmbulance!.longitude);
      
      // Calculate distances
      final distanceToUser = _distance.as(
        LengthUnit.Meter,
        userLocation,
        ambulanceLocation,
      );

      EmergencyCaseStatus newStatus = _caseStatus;

      switch (_caseStatus) {
        case EmergencyCaseStatus.waitingForAmbulance:
          // Already handled in _handleEmergencyResponse
          break;

        case EmergencyCaseStatus.ambulanceDispatched:
          if (distanceToUser <= 100) {
            newStatus = EmergencyCaseStatus.ambulanceArrived;
          }
          break;

        case EmergencyCaseStatus.ambulanceArrived:
          if (distanceToUser > 100) {
            newStatus = EmergencyCaseStatus.enRouteToHospital;
          }
          break;

        case EmergencyCaseStatus.enRouteToHospital:
          if (_assignedHospital != null) {
            final hospitalLocation = LatLng(
              _assignedHospital!.latitude,
              _assignedHospital!.longitude,
            );
            final distanceToHospital = _distance.as(
              LengthUnit.Meter,
              ambulanceLocation,
              hospitalLocation,
            );
            
            if (distanceToHospital <= 50) {
              newStatus = EmergencyCaseStatus.arrivedAtHospital;
              Future.delayed(const Duration(minutes: 5), () {
                if (mounted && _caseStatus == EmergencyCaseStatus.arrivedAtHospital) {
                  setState(() {
                    _caseStatus = EmergencyCaseStatus.completed;
                  });
                }
              });
            }
          }
          break;

        case EmergencyCaseStatus.arrivedAtHospital:
        case EmergencyCaseStatus.completed:
          break;
      }

      if (newStatus != _caseStatus) {
        setState(() {
          _caseStatus = newStatus;
        });
      }
    });
  }

  void _updateAmbulanceCamera() {
    if (_assignedAmbulance != null && _routePoints != null && _routePoints!.length > 1) {
      final ambulanceLocation = LatLng(
        _assignedAmbulance!.latitude,
        _assignedAmbulance!.longitude,
      );

      // Find the next point in the route
      int currentPointIndex = _findClosestRoutePoint(ambulanceLocation);
      if (currentPointIndex < _routePoints!.length - 1) {
        final nextPoint = _routePoints![currentPointIndex + 1];
        
        // Calculate bearing between current and next point
        final bearing = _calculateBearing(
          ambulanceLocation.latitude,
          ambulanceLocation.longitude,
          nextPoint.latitude,
          nextPoint.longitude,
        );

        // Calculate camera position behind ambulance
        final distanceBehind = 0.0003; // Approximately 30-40 meters behind
        final bearingRadians = bearing * pi / 180;
        
        // Calculate camera position behind ambulance
        final cameraLat = ambulanceLocation.latitude - 
            (distanceBehind * cos(bearingRadians));
        final cameraLng = ambulanceLocation.longitude - 
            (distanceBehind * sin(bearingRadians));

        // Smooth camera movement to position behind ambulance
        _animateToPosition(
          LatLng(cameraLat, cameraLng),
          bearing,
          16.5, // Slightly lower zoom level for better context
          const Duration(milliseconds: 1000),
        );
      }
    }
  }

  int _findClosestRoutePoint(LatLng position) {
    if (_routePoints == null || _routePoints!.isEmpty) return 0;

    int closestIndex = 0;
    double closestDistance = double.infinity;

    for (int i = 0; i < _routePoints!.length; i++) {
      final distance = _distance.as(
        LengthUnit.Meter,
        position,
        _routePoints![i],
      );

      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  void _focusOnAmbulance() {
    if (_assignedAmbulance != null) {
      final ambulanceLocation = LatLng(
        _assignedAmbulance!.latitude,
        _assignedAmbulance!.longitude,
      );
      
      // Move to ambulance location with high zoom for 3D effect
      _mapController.move(ambulanceLocation, 18);
      
      // Rotate map to show direction of travel
      if (_routePoints != null && _routePoints!.length > 1) {
        final currentPoint = _routePoints![0];
        final nextPoint = _routePoints![1];
        
        // Calculate bearing between points
        final bearing = _calculateBearing(
          currentPoint.latitude,
          currentPoint.longitude,
          nextPoint.latitude,
          nextPoint.longitude,
        );
        
        _mapController.rotate(bearing);
      }
    }
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1);
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360; // Convert to degrees
  }

  List<LatLng> _decodeRouteGeometry(String geometry) {
    // Simple polyline decoding
    List<LatLng> points = [];
    int index = 0;
    int len = geometry.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int result = 0;
      int shift = 0;
      int b;
      do {
        b = geometry.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      result = 0;
      shift = 0;
      do {
        b = geometry.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation ?? const LatLng(33.55725, -7.61667),
                    initialZoom: _currentLocation != null ? 15 : 11.82,
                    initialRotation: 0,
                    enableScrollWheel: true,
                    keepAlive: true,
                    onTap: (_, __) {
                      // Reset pitch and bearing when tapping empty space
                      _mapController.rotate(0);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                      additionalOptions: {
                        'accessToken': 'pk.eyJ1IjoieWFjaW5lbWFuc291ciIsImEiOiJjbTRzbTBuZmowMnAxMnBzZ3ozZWNyMTQ1In0.MuCDPa78D1cgrKqm3LDX2Q',
                        'id': 'mapbox/satellite-streets-v12', // Changed to satellite view with streets
                      },
                    ),
                    if (_routePoints != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints!,
                            color: Colors.blue,
                            strokeWidth: 4.0,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (_currentLocation != null)
                          Marker(
                            point: _currentLocation!,
                            width: 60,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        if (_assignedAmbulance != null)
                          Marker(
                            point: LatLng(_assignedAmbulance!.latitude, _assignedAmbulance!.longitude),
                            width: 60,
                            height: 60,
                            child: AmbulanceMarker(
                              isAvailable: _assignedAmbulance!.available,
                              onTap: () => _showAmbulanceInfo(context),
                            ),
                          ),
                        if (_assignedHospital != null)
                          Marker(
                            point: LatLng(_assignedHospital!.latitude, _assignedHospital!.longitude),
                            width: 60,
                            height: 60,
                            child: HospitalMarker(
                              onTap: () => _showHospitalInfo(context),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (_assignedAmbulance != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: CaseStatusBar(
                      status: _caseStatus,
                    ),
                  ),
                LocationButton(
                  onPressed: () {
                    _getCurrentLocation().then((_) => _centerOnLocation());
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: EmergencyFooter(
                    onEmergencyResponse: _handleEmergencyResponse,
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 120,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.rotate_left),
                              onPressed: () {
                                final currentRotation = _mapController.rotation;
                                _mapController.rotate(currentRotation - 45);
                              },
                              tooltip: 'Rotate Left',
                            ),
                            const Divider(height: 1),
                            IconButton(
                              icon: const Icon(Icons.rotate_right),
                              onPressed: () {
                                final currentRotation = _mapController.rotation;
                                _mapController.rotate(currentRotation + 45);
                              },
                              tooltip: 'Rotate Right',
                            ),
                            const Divider(height: 1),
                            IconButton(
                              icon: const Icon(Icons.navigation),
                              onPressed: () {
                                _mapController.rotate(0);
                              },
                              tooltip: 'Reset Rotation',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final currentZoom = _mapController.zoom;
                                _mapController.move(
                                  _mapController.center,
                                  currentZoom + 1,
                                );
                              },
                              tooltip: 'Zoom In',
                            ),
                            const Divider(height: 1),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                final currentZoom = _mapController.zoom;
                                _mapController.move(
                                  _mapController.center,
                                  currentZoom - 1,
                                );
                              },
                              tooltip: 'Zoom Out',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_assignedAmbulance != null)
                  Positioned(
                    right: 16,
                    top: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.center_focus_strong),
                        onPressed: _focusOnAmbulance,
                        tooltip: 'Focus on Ambulance',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _showAmbulanceInfo(BuildContext context) {
    if (_assignedAmbulance == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ambulance Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver: ${_assignedAmbulance!.driverName}'),
            Text('Status: ${_assignedAmbulance!.available ? 'Available' : 'Busy'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHospitalInfo(BuildContext context) {
    if (_assignedHospital == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hospital Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_assignedHospital!.name}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
