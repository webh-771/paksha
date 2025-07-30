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
  List<FoodItem> _detectedItems = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // No automatic camera launch
  }

  Future<void> _takePicture() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> _chooseFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _image = File(image.path);
          _isProcessing = true;
          _detectedItems = [];
        });

        final foodRecognitionService = FoodRecognitionService(
          huggingFaceApiToken: "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",
        );

        final isApiAccessible = await foodRecognitionService.testApiConnection();
        if (!isApiAccessible) {
          throw FoodRecognitionException(
            'The Hugging Face API or model is not accessible. Please check your API token and internet connection.',
          );
        }

        final items = await foodRecognitionService.classifyFoodInFile(_image!);

        setState(() {
          _detectedItems = items;
          _isProcessing = false;
        });
      }
    } on FoodRecognitionException catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Food recognition failed: ${e.message}');
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Error processing image: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardBgColor = Color(0xFF2A3B2A); // Dark green card background
    const primaryGreen = AppColors.primary;
    final darkText = AppColors.textLight;
    final greyText = Colors.grey[400];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          'Scan Items',
          style: TextStyle(
            color: darkText,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_image != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  image: DecorationImage(
                    image: FileImage(_image!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          if (_isProcessing)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                    const SizedBox(height: 16),
                    Text(
                      'Identifying items...',
                      style: TextStyle(
                        color: darkText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!_isProcessing && _detectedItems.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detected Items',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select items to add to your pantry',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _detectedItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final foodItem = _detectedItems[index];
                          final category = _determineFoodCategory(foodItem.label);

                          final pantryItem = PantryItem(
                            id: '',
                            name: foodItem.label,
                            category: category,
                            quantity: 1.0,
                            unit: MeasurementUnit.pieces,
                            lowStockThreshold: 1.0,
                            purchaseDate: DateTime.now(),
                            cost: 0.0,
                          );

                          return _DetectedItemCard(
                            name: foodItem.label,
                            category: category,
                            confidence: foodItem.confidence,
                            onAdd: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddItemPage(itemToEdit: pantryItem),
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

          if (!_isProcessing && _detectedItems.isEmpty && _image != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 72,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No items detected',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try taking another photo or add items manually',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_image == null && !_isProcessing)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomButton(
                      text: 'Take a photo',
                      icon: Icons.camera_alt_outlined,
                      backgroundColor: primaryGreen,
                      onPressed: _takePicture,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Choose from Gallery',
                      icon: Icons.photo_library,
                      backgroundColor: primaryGreen,
                      isPrimary: false,
                      onPressed: _chooseFromGallery,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Add Manually',
                      icon: Icons.add,
                      backgroundColor: primaryGreen,
                      isPrimary: false,
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const AddItemPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: (_image != null)
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: CustomButton(
                    text: 'Take Another Photo',
                    onPressed: _takePicture,
                    icon: Icons.camera_alt,
                    backgroundColor: primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: CustomButton(
                    text: 'Choose from Gallery',
                    onPressed: _chooseFromGallery,
                    icon: Icons.photo_library,
                    backgroundColor: primaryGreen,
                    isPrimary: false,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: CustomButton(
                    text: 'Add Manually',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const AddItemPage()),
                      );
                    },
                    icon: Icons.add,
                    backgroundColor: primaryGreen,
                    isPrimary: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }

  String _determineFoodCategory(String foodLabel) {
    final label = foodLabel.toLowerCase();

    final Map<String, List<String>> categories = {
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

    for (final category in categories.keys) {
      for (final pattern in categories[category]!) {
        if (label.contains(pattern)) {
          return category;
        }
      }
    }
    return 'Others';
  }
}

class _DetectedItemCard extends StatelessWidget {
  final String name;
  final String category;
  final double confidence;
  final VoidCallback onAdd;

  const _DetectedItemCard({
    Key? key,
    required this.name,
    required this.category,
    required this.confidence,
    required this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Colors for card theme
    const cardBgColor = Color(0xFF2A3B2A);
    const primaryGreen = AppColors.primary;

    return Material(
      elevation: 4,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          title: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category: $category',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: confidence.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade700,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          trailing: ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              elevation: 0,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text(
              'Add',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
