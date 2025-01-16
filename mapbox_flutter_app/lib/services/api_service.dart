import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/emergency_request.dart';
import '../models/ambulance_info.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.156.117:8888';
  static const String dispatchService = '$baseUrl/dispatch-coordination-service/dispatch';
  static const String hospitalsService = '$baseUrl/hospital-management-service/hospitals';
  static const String casesService = '$baseUrl/dispatch-coordination-service/cases';
  static const String ambulanceService = '$baseUrl/ambulance-service/ambulances';

  // Get list of specialities
  static Future<List<String>> getSpecialities() async {
    try {
      print('Fetching specialities from: $hospitalsService/specialities');
      final response = await http.get(
        Uri.parse('$hospitalsService/specialities'),
        headers: {
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item.toString()).toList();
      } else {
        throw Exception('Failed to get specialities: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting specialities: $e');
      throw Exception('Error getting specialities: $e');
    }
  }

  // Send emergency request
  static Future<EmergencyResponse> sendEmergencyRequest(EmergencyRequest request) async {
    try {
      print('Sending request to: $dispatchService/emergency');
      print('Request body: ${json.encode(request.toJson())}');
      
      final response = await http.post(
        Uri.parse('$dispatchService/emergency'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return EmergencyResponse.fromJson(data);
      } else {
        throw Exception('Failed to send emergency request: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending emergency request: $e');
      throw Exception('Error sending emergency request: $e');
    }
  }

  // Get ambulance location
  static Future<AmbulanceInfo?> getAmbulanceLocation(int ambulanceId) async {
    try {
      print('Fetching ambulance location from: $ambulanceService/$ambulanceId/location');
      final response = await http.get(
        Uri.parse('$ambulanceService/$ambulanceId/location'),
        headers: {
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AmbulanceInfo(
          id: data['id'] as int,
          driverName: data['driverName'] as String? ?? 'Unknown Driver',
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          available: data['available'] as bool,
        );
      } else {
        print('Failed to get ambulance location: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting ambulance location: $e');
      return null;
    }
  }
}