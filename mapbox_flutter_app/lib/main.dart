import 'package:flutter/material.dart';
import 'package:mapbox_flutter_app/screens/map_screen.dart';
import 'package:mapbox_flutter_app/widgets/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ambulance Tracker',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}