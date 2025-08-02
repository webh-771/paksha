import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// App configuration and core services
import 'config/routes.dart';
import 'firebase_options.dart';

// Riverpod Providers
import 'providers/pantry_provider.dart'; // Needs to be a Riverpod provider!!
import 'services/pantry_service.dart';
import 'services/image_recognition_service.dart';

// 1. Riverpod providers for Pantry & FoodRecognition
final pantryProvider = ChangeNotifierProvider<PantryProvider>((ref) {
  return PantryProvider(pantryService: PantryService());
});

final foodRecognitionServiceProvider = Provider<FoodRecognitionService>((ref) {
  return FoodRecognitionService(
    huggingFaceApiToken: "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",
  );
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ProviderScope(
      // If you want to override providers for testing, etc, add overrides here
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      title: 'Paksha',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFF1B2B1B),
        fontFamily: 'Roboto',
        useMaterial3: true, // If using Material 3
      ),
    );
  }
}
