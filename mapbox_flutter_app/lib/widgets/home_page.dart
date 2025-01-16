import 'package:flutter/material.dart';
import './ai_features_widget.dart';

// Color palette to match the medical chatbot
class MedicalAppColors {
  static const Color primary = Color(0xFF4A90E2);      // Soft Professional Blue
  static const Color secondary = Color(0xFF4ECDC4);    // Calming Teal
  static const Color background = Color(0xFFF5F5F5);   // Light Gray Background
  static const Color lightBackground = Color(0xFFE6F2FF); // Light Blue Background
  static const Color emergencyRed = Color(0xFFD32F2F);  // Strong Emergency Red
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Services'),
        backgroundColor: MedicalAppColors.primary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MedicalAppColors.lightBackground,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'What do you need?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MedicalAppColors.primary,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedicalAppColors.emergencyRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/map');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.emergency, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'Get an Ambulance',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: MedicalAppColors.primary,
                    side: BorderSide(
                      color: MedicalAppColors.primary,
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: const Text('AI Medical Assistant'),
                            backgroundColor: MedicalAppColors.primary,
                          ),
                          body: const AIFeaturesWidget(),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.medical_services, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'Get Medical Advice',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}