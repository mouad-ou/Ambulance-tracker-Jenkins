import 'package:flutter/material.dart';
import 'package:location/location.dart';
import '../services/api_service.dart';
import '../models/speciality.dart';
import '../models/emergency_request.dart';

class EmergencyFooter extends StatefulWidget {
  final Function(EmergencyResponse) onEmergencyResponse;

  const EmergencyFooter({
    Key? key,
    required this.onEmergencyResponse,
  }) : super(key: key);

  @override
  State<EmergencyFooter> createState() => _EmergencyFooterState();
}

class _EmergencyFooterState extends State<EmergencyFooter> {
  String? selectedSpeciality;
  List<String>? _specialities;
  bool _isLoading = false;
  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _fetchSpecialities();
  }

  Future<void> _fetchSpecialities() async {
    if (_specialities != null) return; // Already fetched

    setState(() => _isLoading = true);
    try {
      final specialities = await ApiService.getSpecialities();
      if (mounted) {
        setState(() {
          _specialities = specialities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _specialities = Speciality.fallbackSpecialities;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using offline speciality list'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<LocationData?> _getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    return await _location.getLocation();
  }

  Future<void> _sendEmergencyRequest(String speciality) async {
    try {
      final locationData = await _getCurrentLocation();
      if (locationData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get location')),
        );
        return;
      }

      final request = EmergencyRequest(
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
        specialization: speciality,
      );

      final response = await ApiService.sendEmergencyRequest(request);
      
      if (!mounted) return;
      
      // Pass the response to the parent widget
      widget.onEmergencyResponse(response);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Emergency request sent: ${response.status}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send emergency request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showSpecialityDialog() async {
    if (_specialities == null && !_isLoading) {
      await _fetchSpecialities();
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Speciality'),
          content: SizedBox(
            width: double.maxFinite,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _specialities?.length ?? 0,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_specialities![index]),
                        onTap: () {
                          Navigator.pop(context);
                          _sendEmergencyRequest(_specialities![index]);
                        },
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Emergency Assistance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showSpecialityDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'Request Emergency',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
