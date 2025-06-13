import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants.dart';
import '../../../core/models/pantry_item.dart';
import '../../../services/image_recognition_service.dart';
import '../../../providers/pantry_provider.dart';
import '../../../widgets/custom_button.dart';
import 'add_item_page.dart';

class ImageScanPage extends ConsumerStatefulWidget {
  const ImageScanPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ImageScanPage> createState() => _ImageScanPageState();
}

class _ImageScanPageState extends ConsumerState<ImageScanPage> {
  File? _image;
  bool _isProcessing = false;
  List<FoodItem> _detectedItems = []; // Changed to use FoodItem class
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _takePicture(); // Automatically open camera when the page loads
  }

  Future<void> _takePicture() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _image = File(image.path);
        _isProcessing = true;
        _detectedItems = []; // Clear previous results
      });

      // Process the image with the image recognition service
      try {
        // First test if the API is accessible
        final foodRecognitionService = FoodRecognitionService(
          huggingFaceApiToken: "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", // Your token
        );

        // Test API connection first
        final isApiAccessible = await foodRecognitionService.testApiConnection();
        if (!isApiAccessible) {
          throw FoodRecognitionException(
            'The Hugging Face API or model is not accessible. Please check your API token and internet connection.',
          );
        }

        // Use the correct method from our fixed service
        final items = await foodRecognitionService.classifyFoodInFile(_image!);

        setState(() {
          _detectedItems = items; // Already in the correct format
          _isProcessing = false;
        });
      } on FoodRecognitionException catch (e) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Food recognition failed: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Scan Items', style: TextStyle(color: AppColors.darkText)),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: Column(
        children: [
          // Image preview
          if (_image != null)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[200],
                image: DecorationImage(
                  image: FileImage(_image!),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Processing indicator
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Identifying items...',
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Detected items list
          if (!_isProcessing && _detectedItems.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detected Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select items to add to your pantry',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _detectedItems.length,
                        itemBuilder: (context, index) {
                          final foodItem = _detectedItems[index];

                          // Convert food category based on label
                          String category = _determineFoodCategory(foodItem.label);

                          // Create a pantry item from the detected item data
                          final PantryItem pantryItem = PantryItem(
                            id: '',  // Will be generated when actually saving
                            name: foodItem.label,
                            category: category,
                            quantity: 1.0,  // Default quantity
                            unit: MeasurementUnit.pieces,    // Default unit
                            lowStockThreshold: 1.0,  // Default threshold
                            purchaseDate: DateTime.now(),
                            cost: 0.0,  // Default cost
                          );

                          return DetectedItemTile(
                            name: foodItem.label,
                            category: category,
                            confidence: foodItem.confidence,
                            onAdd: () {
                              // Navigate to add item page with pre-filled data
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddItemPage(
                                    itemToEdit: pantryItem,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Empty state when no items detected
          if (!_isProcessing && _detectedItems.isEmpty && _image != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No items detected',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try taking another photo or add items manually',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Take Another Photo',
                onPressed: _takePicture,
                icon: Icons.camera_alt,
                backgroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: 'Add Manually',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AddItemPage()),
                  );
                },
                icon: Icons.add,
                isPrimary: false,
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to determine food category based on the food label
  String _determineFoodCategory(String foodLabel) {
    final lowercaseLabel = foodLabel.toLowerCase();

    // Define category mapping patterns
    final Map<String, List<String>> categoryPatterns = {
      'Fruits': ['apple', 'banana', 'orange', 'berry', 'fruit', 'citrus', 'melon'],
      'Vegetables': ['carrot', 'broccoli', 'lettuce', 'vegetable', 'tomato', 'cucumber', 'spinach', 'onion', 'potato', 'garlic'],
      'Dairy': ['milk', 'cheese', 'yogurt', 'butter', 'cream', 'dairy'],
      'Meat': ['beef', 'pork', 'chicken', 'steak', 'meat', 'bacon', 'sausage', 'ham'],
      'Grains': ['bread', 'rice', 'pasta', 'oats', 'cereal', 'grain', 'flour'],
      'Seafood': ['fish', 'shrimp', 'seafood', 'salmon', 'tuna', 'crab', 'lobster'],
      'Snacks': ['chip', 'cookie', 'snack', 'candy', 'chocolate', 'pretzel', 'popcorn'],
      'Beverages': ['water', 'juice', 'soda', 'tea', 'coffee', 'drink', 'beverage'],
      'Condiments': ['sauce', 'oil', 'vinegar', 'spice', 'herb', 'condiment', 'ketchup', 'mustard', 'mayo'],
      'Baked Goods': ['cake', 'bread', 'pie', 'pastry', 'cookie', 'muffin', 'baked'],
    };

    // Check if the food label contains any patterns for each category
    for (final category in categoryPatterns.keys) {
      for (final pattern in categoryPatterns[category]!) {
        if (lowercaseLabel.contains(pattern)) {
          return category;
        }
      }
    }

    // Default category if no patterns match
    return 'Others';
  }
}

class DetectedItemTile extends StatelessWidget {
  final String name;
  final String category;
  final double confidence;
  final VoidCallback onAdd;

  const DetectedItemTile({
    Key? key,
    required this.name,
    required this.category,
    required this.confidence,
    required this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Category: $category',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            LinearProgressIndicator(
              value: confidence,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Add',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}