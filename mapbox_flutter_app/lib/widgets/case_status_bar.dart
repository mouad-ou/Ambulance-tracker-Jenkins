import 'package:flutter/material.dart';

enum EmergencyCaseStatus {
  waitingForAmbulance,
  ambulanceDispatched,
  ambulanceArrived,
  enRouteToHospital,
  arrivedAtHospital,
  completed,
}

class CaseStatusBar extends StatelessWidget {
  final EmergencyCaseStatus status;

  const CaseStatusBar({
    super.key,
    required this.status,
  });

  String get statusText {
    switch (status) {
      case EmergencyCaseStatus.waitingForAmbulance:
        return 'Waiting for Ambulance';
      case EmergencyCaseStatus.ambulanceDispatched:
        return 'Ambulance on the Way';
      case EmergencyCaseStatus.ambulanceArrived:
        return 'Ambulance Arrived';
      case EmergencyCaseStatus.enRouteToHospital:
        return 'En Route to Hospital';
      case EmergencyCaseStatus.arrivedAtHospital:
        return 'Arrived at Hospital';
      case EmergencyCaseStatus.completed:
        return 'Case Completed';
    }
  }

  Color get statusColor {
    switch (status) {
      case EmergencyCaseStatus.waitingForAmbulance:
        return Colors.orange;
      case EmergencyCaseStatus.ambulanceDispatched:
        return Colors.blue;
      case EmergencyCaseStatus.ambulanceArrived:
        return Colors.green;
      case EmergencyCaseStatus.enRouteToHospital:
        return Colors.blue;
      case EmergencyCaseStatus.arrivedAtHospital:
        return Colors.green;
      case EmergencyCaseStatus.completed:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case EmergencyCaseStatus.waitingForAmbulance:
        return Icons.access_time;
      case EmergencyCaseStatus.ambulanceDispatched:
        return Icons.local_taxi;
      case EmergencyCaseStatus.ambulanceArrived:
        return Icons.location_on;
      case EmergencyCaseStatus.enRouteToHospital:
        return Icons.local_hospital;
      case EmergencyCaseStatus.arrivedAtHospital:
        return Icons.check_circle;
      case EmergencyCaseStatus.completed:
        return Icons.done_all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
