import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully!');
    debugPrint('Project ID: ${Firebase.app().options.projectId}');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }
}
