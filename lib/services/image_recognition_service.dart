import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// A service that uses Hugging Face's food classification model for food image recognition.
class FoodRecognitionService {
  /// The Hugging Face API URL for inference
  /// Using a more reliable food classification model: "nateraw/food"
  static const String _huggingFaceApiUrl = 'https://api-inference.huggingface.co/models/nateraw/food';

  /// Alternate models that could be used if the primary one fails:
  /// - 'swiss-ai-center/food-classification'
  /// - 'Kaludi/food101-vit-base-patch16-224'

  /// API token for Hugging Face
  final String huggingFaceApiToken;

  /// Creates a new [FoodRecognitionService].
  ///
  /// The [huggingFaceApiToken] is required to authenticate with Hugging Face's API.
  FoodRecognitionService({
    required this.huggingFaceApiToken,
  });

  /// Recognizes food in an image file.
  ///
  /// Returns a list of food items with their confidence scores.
  Future<List<FoodItem>> classifyFoodInFile(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return await _classifyFood(bytes);
    } catch (e) {
      throw FoodRecognitionException(
        'Failed to classify food in image file: $e',
      );
    }
  }

  /// Recognizes food in an image from an asset.
  ///
  /// [assetPath] is the path to the asset in the pubspec.yaml file.
  /// Returns a list of food items with their confidence scores.
  Future<List<FoodItem>> classifyFoodInAsset(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      return await _classifyFood(bytes.buffer.asUint8List());
    } catch (e) {
      throw FoodRecognitionException(
        'Failed to classify food in asset: $e',
      );
    }
  }

  /// Recognizes food in an image from a URL.
  ///
  /// [imageUrl] is the URL of the image to classify.
  /// Returns a list of food items with their confidence scores.
  Future<List<FoodItem>> classifyFoodInUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw FoodRecognitionException(
          'Failed to download image: ${response.statusCode}',
        );
      }
      return await _classifyFood(response.bodyBytes);
    } catch (e) {
      throw FoodRecognitionException(
        'Failed to classify food in URL: $e',
      );
    }
  }

  /// Recognizes food in an image represented as bytes.
  ///
  /// This is the core method that communicates with the Hugging Face API.
  Future<List<FoodItem>> _classifyFood(Uint8List imageBytes) async {
    try {
      // Process the image to ensure it's in an acceptable format and size
      final processedImage = await _processImage(imageBytes);

      // Create request to Hugging Face API
      final uri = Uri.parse(_huggingFaceApiUrl);
      final request = http.Request('POST', uri);

      // Add the API token as a header
      request.headers['Authorization'] = 'Bearer $huggingFaceApiToken';

      // Important: Set the correct content type for binary data
      request.headers['Content-Type'] = 'application/octet-stream';

      // Set the binary image data as the request body
      request.bodyBytes = processedImage;

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Handle API responses
      if (response.statusCode == 503) {
        // The model is loading, wait and retry
        final Map<String, dynamic> errorResponse = jsonDecode(response.body);
        final int? estimatedTime = errorResponse['estimated_time'];

        if (estimatedTime != null) {
          // Wait for the model to load and retry
          await Future.delayed(Duration(seconds: estimatedTime + 1));
          return _classifyFood(imageBytes);
        } else {
          // If no estimated time is provided, wait a default time
          await Future.delayed(const Duration(seconds: 20));
          return _classifyFood(imageBytes);
        }
      } else if (response.statusCode != 200) {
        // Log more details about non-200 responses for debugging
        throw FoodRecognitionException(
          'API request failed with status: ${response.statusCode}, body: ${response.body}',
        );
      }

      // Parse the response and return the recognized food items
      return _parseFoodClassificationResponse(response.body);
    } catch (e) {
      throw FoodRecognitionException(
        'Food classification request failed: $e',
      );
    }
  }

  /// Processes the image to ensure it meets the API requirements.
  ///
  /// Resizes and converts the image to an appropriate format for the model.
  Future<Uint8List> _processImage(Uint8List imageBytes) async {
    return compute(_processImageIsolate, imageBytes);
  }

  /// Parses the Hugging Face API response and converts it to a list of [FoodItem].
  List<FoodItem> _parseFoodClassificationResponse(String responseBody) {
    try {
      // The response format can vary between models, so we need to handle different formats
      final dynamic decodedResponse = jsonDecode(responseBody);

      if (decodedResponse is List) {
        // Format: [{"label": "pizza", "score": 0.98}, ...]
        return decodedResponse.map((prediction) {
          return FoodItem(
            label: prediction['label'],
            confidence: prediction['score'].toDouble(),
          );
        }).toList()
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
      } else if (decodedResponse is Map) {
        // Some models return: {"labels": ["pizza", ...], "scores": [0.98, ...]}
        if (decodedResponse.containsKey('labels') && decodedResponse.containsKey('scores')) {
          final List<dynamic> labels = decodedResponse['labels'];
          final List<dynamic> scores = decodedResponse['scores'];

          final result = <FoodItem>[];
          for (int i = 0; i < labels.length && i < scores.length; i++) {
            result.add(FoodItem(
              label: labels[i],
              confidence: scores[i].toDouble(),
            ));
          }
          return result..sort((a, b) => b.confidence.compareTo(a.confidence));
        }
      }

      // Fallback for unknown response formats
      throw FoodRecognitionException('Unexpected API response format: $responseBody');
    } catch (e) {
      throw FoodRecognitionException('Failed to parse API response: $e');
    }
  }

  /// Provides a method to check if the API is accessible
  Future<bool> testApiConnection() async {
    try {
      final uri = Uri.parse(_huggingFaceApiUrl);
      final response = await http.head(
        uri,
        headers: {'Authorization': 'Bearer $huggingFaceApiToken'},
      );

      // 200 OK means the API is accessible
      // 401/403 means authentication issues
      // 404 means the model doesn't exist
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Processes an image in an isolate to avoid blocking the main thread.
Uint8List _processImageIsolate(Uint8List imageBytes) {
  // Decode the image
  final image = img.decodeImage(imageBytes);
  if (image == null) {
    throw FoodRecognitionException('Failed to decode image');
  }

  // Resize the image to match the expected input size for the model
  // Most vision models expect 224x224 or 299x299 images
  final resized = img.copyResize(
    image,
    width: 224,
    height: 224,
  );

  // Convert to JPEG format with appropriate quality
  return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
}

/// Represents a food item recognized in an image.
class FoodItem {
  /// The label or food name of the recognized item.
  final String label;

  /// The confidence score (0.0 to 1.0) for the recognition.
  final double confidence;

  /// Creates a new [FoodItem].
  FoodItem({
    required this.label,
    required this.confidence,
  });

  @override
  String toString() => '$label (${(confidence * 100).toStringAsFixed(1)}%)';
}

/// An exception thrown when food recognition fails.
class FoodRecognitionException implements Exception {
  /// The error message.
  final String message;

  /// Creates a new [FoodRecognitionException].
  FoodRecognitionException(this.message);

  @override
  String toString() => 'FoodRecognitionException: $message';
}

/// Example usage of the [FoodRecognitionService].
class FoodRecognitionExample {
  static Future<void> demonstrateUsage() async {
    // Create an instance of the service
    final foodRecognitionService = FoodRecognitionService(
      huggingFaceApiToken: 'your_huggingface_api_token_here',
    );

    try {
      // Test the API connection first
      final isApiAccessible = await foodRecognitionService.testApiConnection();
      if (!isApiAccessible) {
        print('WARNING: The Hugging Face API or model is not accessible. Please check your API token and internet connection.');
        return;
      }

      // Classify food in an image file
      final file = File('/path/to/your/food_image.jpg');
      final fileResults = await foodRecognitionService.classifyFoodInFile(file);
      print('Recognized food items in file:');
      for (final food in fileResults) {
        print('- $food');
      }

      // Classify food in an asset
      final assetResults = await foodRecognitionService.classifyFoodInAsset(
        'assets/images/food_sample.jpg',
      );
      print('Recognized food items in asset:');
      for (final food in assetResults) {
        print('- $food');
      }

      // Classify food in an image from a URL
      final urlResults = await foodRecognitionService.classifyFoodInUrl(
        'https://example.com/food_image.jpg',
      );
      print('Recognized food items in URL:');
      for (final food in urlResults) {
        print('- $food');
      }
    } on FoodRecognitionException catch (e) {
      print('Food recognition failed: $e');
    } catch (e) {
      print('An unexpected error occurred: $e');
    }
  }
}