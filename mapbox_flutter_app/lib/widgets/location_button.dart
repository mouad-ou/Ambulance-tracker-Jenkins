import 'package:flutter/material.dart';

class LocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LocationButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 96, // Adjusted for smaller footer
      child: FloatingActionButton(
        onPressed: onPressed,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
