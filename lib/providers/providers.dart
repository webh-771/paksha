// Create this file as providers.dart in your lib/ directory

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/image_recognition_service.dart'; // Adjust the import path as needed

// Create a provider for the FoodRecognitionService
final foodRecognitionServiceProvider = Provider<FoodRecognitionService>((ref) {
  return FoodRecognitionService(
    huggingFaceApiToken: "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", // Consider moving this to an environment variable
  );
});

// You can add other providers here as your app grows