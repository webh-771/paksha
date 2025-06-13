import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/routes.dart';
import 'firebase_options.dart';

import 'services/image_recognition_service.dart';
import 'providers/pantry_provider.dart';
import 'services/pantry_service.dart'; // Rename your routes file to `router.dart` or import AppRouter correctly

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PantryProvider(
            pantryService: PantryService(), // ✅ Pass required argument
          ),
        ),
        Provider<FoodRecognitionService>(
          create: (_) => FoodRecognitionService(
            huggingFaceApiToken: "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",
          ),
        ),
      ],
      child: const MyApp(), // ✅ Add this class below
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router, // ✅ Using your GoRouter setup
      title: 'Paksha',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
    );
  }
}
