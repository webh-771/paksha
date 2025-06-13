import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/pantry_item.dart';

class PantryService {
  // This could be your API endpoint in production
  // For development, we'll use local storage with SharedPreferences
  final bool _useLocalStorage;
  final String? _apiBaseUrl;

  PantryService({bool useLocalStorage = true, String? apiBaseUrl})
      : _useLocalStorage = useLocalStorage,
        _apiBaseUrl = apiBaseUrl;

  // Get all pantry items
  Future<List<PantryItem>> getPantryItems() async {
    try {
      if (_useLocalStorage) {
        return _getItemsFromLocalStorage();
      } else {
        // Use API
        final response = await http.get(Uri.parse('$_apiBaseUrl/pantry'));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          return data.map((item) => PantryItem.fromJson(item)).toList();
        } else {
          throw Exception('Failed to load pantry items: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Error in getPantryItems: $e');
      // Return empty list if an error occurs
      return [];
    }
  }

  // Add a new pantry item
  Future<PantryItem> addPantryItem(PantryItem item) async {
    try {
      if (_useLocalStorage) {
        // Add to local storage
        await _saveItemToLocalStorage(item);
        return item;
      } else {
        // Use API
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/pantry'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(item.toJson()),
        );

        if (response.statusCode == 201) {
          return PantryItem.fromJson(json.decode(response.body));
        } else {
          throw Exception('Failed to add pantry item: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Error in addPantryItem: $e');
      rethrow;
    }
  }

  // Update an existing pantry item
  Future<void> updatePantryItem(PantryItem item) async {
    try {
      if (_useLocalStorage) {
        // Update in local storage
        await _updateItemInLocalStorage(item);
      } else {
        // Use API
        final response = await http.put(
          Uri.parse('$_apiBaseUrl/pantry/${item.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(item.toJson()),
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to update pantry item: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Error in updatePantryItem: $e');
      rethrow;
    }
  }

  // Delete a pantry item
  Future<void> deletePantryItem(String itemId) async {
    try {
      if (_useLocalStorage) {
        // Delete from local storage
        await _deleteItemFromLocalStorage(itemId);
      } else {
        // Use API
        final response = await http.delete(
          Uri.parse('$_apiBaseUrl/pantry/$itemId'),
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to delete pantry item: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Error in deletePantryItem: $e');
      rethrow;
    }
  }

  // Local storage implementation
  Future<List<PantryItem>> _getItemsFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString('pantry_items');

    if (itemsJson == null || itemsJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedItems = json.decode(itemsJson);
      return decodedItems
          .map((item) => PantryItem.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error parsing pantry items from storage: $e');
      return [];
    }
  }

  Future<void> _saveItemToLocalStorage(PantryItem newItem) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PantryItem> items = await _getItemsFromLocalStorage();

    items.add(newItem);

    await prefs.setString(
      'pantry_items',
      json.encode(items.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _updateItemInLocalStorage(PantryItem updatedItem) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PantryItem> items = await _getItemsFromLocalStorage();

    final index = items.indexWhere((item) => item.id == updatedItem.id);
    if (index >= 0) {
      items[index] = updatedItem;

      await prefs.setString(
        'pantry_items',
        json.encode(items.map((item) => item.toJson()).toList()),
      );
    }
  }

  Future<void> _deleteItemFromLocalStorage(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<PantryItem> items = await _getItemsFromLocalStorage();

    items.removeWhere((item) => item.id == itemId);

    await prefs.setString(
      'pantry_items',
      json.encode(items.map((item) => item.toJson()).toList()),
    );
  }

  // Method to insert sample data (for development or demo purposes)
  Future<void> insertSampleData() async {
    final sampleItems = [
      PantryItem(
        id: '1',
        name: 'Apples',
        category: 'Fruits',
        quantity: 5,
        unit: MeasurementUnit.pieces,
        lowStockThreshold: 2,
        expiryDate: DateTime.now().add(const Duration(days: 7)),
        purchaseDate: DateTime.now().subtract(const Duration(days: 2)),
        cost: 3.99,
      ),
      PantryItem(
        id: '2',
        name: 'Milk',
        category: 'Dairy',
        quantity: 1.5,
        unit: MeasurementUnit.liters,
        lowStockThreshold: 0.5,
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        purchaseDate: DateTime.now().subtract(const Duration(days: 1)),
        cost: 2.49,
      ),
      PantryItem(
        id: '3',
        name: 'Chicken Breast',
        category: 'Meat',
        quantity: 0.5,
        unit: MeasurementUnit.kilograms,
        lowStockThreshold: 0.2,
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        purchaseDate: DateTime.now().subtract(const Duration(days: 1)),
        cost: 5.99,
      ),
      PantryItem(
        id: '4',
        name: 'Rice',
        category: 'Grains',
        quantity: 2,
        unit: MeasurementUnit.kilograms,
        lowStockThreshold: 0.5,
        purchaseDate: DateTime.now().subtract(const Duration(days: 10)),
        cost: 4.50,
      ),
      PantryItem(
        id: '5',
        name: 'Tomatoes',
        category: 'Vegetables',
        quantity: 4,
        unit: MeasurementUnit.pieces,
        lowStockThreshold: 2,
        expiryDate: DateTime.now().add(const Duration(days: 4)),
        purchaseDate: DateTime.now().subtract(const Duration(days: 2)),
        cost: 2.99,
      ),
      PantryItem(
        id: '6',
        name: 'Black Pepper',
        category: 'Spices',
        quantity: 100,
        unit: MeasurementUnit.grams,
        lowStockThreshold: 20,
        purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
        cost: 3.29,
      ),
    ];

    if (_useLocalStorage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'pantry_items',
        json.encode(sampleItems.map((item) => item.toJson()).toList()),
      );
    } else {
      // For API-based implementations, you could do a batch insert here
      for (final item in sampleItems) {
        await addPantryItem(item);
      }
    }
  }

  // Clear all data (useful for testing and debugging)
  Future<void> clearAllData() async {
    if (_useLocalStorage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pantry_items');
    } else {
      // For API-based implementations, you might have a dedicated endpoint
      try {
        await http.delete(Uri.parse('$_apiBaseUrl/pantry/all'));
      } catch (e) {
        debugPrint('Error clearing all data: $e');
        rethrow;
      }
    }
  }

  // Recognize ingredients from an image
  Future<List<Map<String, dynamic>>> recognizeIngredientsFromImage(String imagePath) async {
    // In a real app, this would call a vision API or ML model
    // For demo, we'll return some mock data
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    // This would be the result of image recognition
    return [
      {'name': 'Apples', 'category': 'Fruits', 'quantity': 3},
      {'name': 'Bananas', 'category': 'Fruits', 'quantity': 5},
    ];
  }
}