import 'package:flutter/material.dart';

class AmbulanceMarker extends StatelessWidget {
  final bool isAvailable;
  final VoidCallback? onTap;

  const AmbulanceMarker({
    super.key,
    this.isAvailable = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Stack(
            children: [
              Icon(
                Icons.local_taxi_rounded,
                color: isAvailable ? Colors.blue : Colors.grey,
                size: 35,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  width: 12,
                  height: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
