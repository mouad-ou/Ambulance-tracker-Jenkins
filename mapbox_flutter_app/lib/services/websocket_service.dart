import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/ambulance_info.dart';

class WebSocketService {
  static const String wsUrl = 'ws://192.168.156.117:8888/ambulance-service/ws/websocket';
  WebSocketChannel? _channel;
  StreamController<AmbulanceInfo>? _locationController;

  Stream<AmbulanceInfo>? get ambulanceLocations => _locationController?.stream;

  void connectToAmbulanceUpdates(int ambulanceId) {
    // Close existing connection if any
    _channel?.sink.close();
    _locationController?.close();

    // Create new stream controller
    _locationController = StreamController<AmbulanceInfo>.broadcast();

    // Connect to WebSocket
    try {
      print('Connecting to WebSocket: $wsUrl');
      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
      );

      print('Sending CONNECT frame');
      // Send STOMP CONNECT frame
      _channel?.sink.add(json.encode({
        'type': 'CONNECT',
        'headers': {
          'accept-version': '1.2',
          'heart-beat': '10000,10000'
        }
      }));

      // Subscribe to ambulance location topic
      print('Subscribing to ambulance location updates');
      _channel?.sink.add(json.encode({
        'type': 'SUBSCRIBE',
        'id': 'sub-0',
        'destination': '/topic/ambulance/$ambulanceId/location'
      }));

      // Request initial location
      print('Requesting initial location');
      _channel?.sink.add(json.encode({
        'type': 'SEND',
        'destination': '/app/ambulance/$ambulanceId/location',
        'content-type': 'application/json'
      }));

      // Listen to incoming messages
      _channel!.stream.listen(
        (message) {
          try {
            print('WebSocket message received: $message');
            if (message == '\n') return; // Ignore heartbeat messages

            final Map<String, dynamic> frame = json.decode(message);
            if (frame['type'] == 'CONNECTED') {
              print('STOMP connection established');
              return;
            }

            if (frame['type'] == 'MESSAGE') {
              final Map<String, dynamic> data = json.decode(frame['body']);
              final ambulanceInfo = AmbulanceInfo(
                id: data['id'] as int,
                driverName: data['driverName'] as String? ?? 'Unknown Driver',
                latitude: (data['latitude'] as num).toDouble(),
                longitude: (data['longitude'] as num).toDouble(),
                available: data['available'] as bool,
              );
              _locationController?.add(ambulanceInfo);
            }
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          reconnect(ambulanceId);
        },
        onDone: () {
          print('WebSocket connection closed');
          reconnect(ambulanceId);
        },
      );
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      // Try to reconnect after delay
      Future.delayed(const Duration(seconds: 5), () => reconnect(ambulanceId));
    }
  }

  void reconnect(int ambulanceId) {
    Future.delayed(const Duration(seconds: 5), () {
      print('Attempting to reconnect WebSocket...');
      connectToAmbulanceUpdates(ambulanceId);
    });
  }

  void dispose() {
    _channel?.sink.close();
    _locationController?.close();
  }
}
