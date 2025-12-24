import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

/// Main entry point of the Flashbook application.
///
/// Flashbook: Instagram-style scrolling interaction with a calm, book-reading aura.
/// Built for GDG Hackathon demo.
///
/// Architecture:
/// - Clean separation of UI, state, and services
/// - Provider for state management
/// - Modular widget structure
/// - Mock services for hackathon demo
///
/// Tech Stack:
/// - Flutter (UI)
/// - Firebase Authentication (mocked for demo)
/// - Firebase Firestore (mocked for demo)
/// - Gemini API (mocked for demo)
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only for book-reading experience)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI style for immersive reading
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Note: Firebase initialization is skipped for hackathon demo.
  // In production, uncomment the following:
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // Run the app
  runApp(const FlashbookApp());
}
