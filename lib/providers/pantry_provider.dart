import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/pantry_item.dart';
import '../services/pantry_service.dart';

class PantryProvider with ChangeNotifier {
  final PantryService _pantryService;

  List<PantryItem> _pantryItems = [];
  bool _isLoading = false;
  String _error = '';

  // Constructor with dependency injection
  PantryProvider({required PantryService pantryService})
      : _pantryService = pantryService;

  // Getters
  List<PantryItem> get pantryItems => _pantryItems;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Get items by category
  List<PantryItem> getItemsByCategory(String category) {
    if (category == 'All') {
      return _pantryItems;
    }
    return _pantryItems.where((item) => item.category == category).toList();
  }

  // Get low stock items
  List<PantryItem> get lowStockItems {
    return _pantryItems.where((item) => item.isLowStock).toList();
  }

  // Get expiring soon items
  List<PantryItem> get expiringSoonItems {
    return _pantryItems.where((item) => item.isExpiringSoon).toList();
  }

  // Get expired items
  List<PantryItem> get expiredItems {
    return _pantryItems.where((item) => item.isExpired).toList();
  }

  // Load pantry items from database or storage
  Future<void> loadPantryItems() async {
    _setLoading(true);

    try {
      final items = await _pantryService.getPantryItems();
      _pantryItems = items;
      _error = '';
    } catch (e) {
      _error = 'Failed to load pantry items: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Add a new pantry item
  Future<void> addPantryItem(PantryItem item) async {
    _setLoading(true);

    try {
      final newItem = await _pantryService.addPantryItem(item);
      _pantryItems.add(newItem);
      _sortItems();
      _error = '';
    } catch (e) {
      _error = 'Failed to add pantry item: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing pantry item
  Future<void> updatePantryItem(PantryItem updatedItem) async {
    _setLoading(true);

    try {
      await _pantryService.updatePantryItem(updatedItem);

      final index = _pantryItems.indexWhere((item) => item.id == updatedItem.id);
      if (index >= 0) {
        _pantryItems[index] = updatedItem;
        _sortItems();
      }
      _error = '';
    } catch (e) {
      _error = 'Failed to update pantry item: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Update item quantity
  Future<void> updateItemQuantity(String itemId, double newQuantity) async {
    final index = _pantryItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final updatedItem = _pantryItems[index].copyWith(quantity: newQuantity);
      await updatePantryItem(updatedItem);
    }
  }

  // Decrement item quantity by a specific amount
  Future<void> decrementItemQuantity(String itemId, double amount) async {
    final index = _pantryItems.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      final currentItem = _pantryItems[index];
      final newQuantity = (currentItem.quantity - amount).clamp(0.0, double.infinity);
      await updateItemQuantity(itemId, newQuantity);
    }
  }

  // Delete a pantry item
  Future<void> deletePantryItem(String itemId) async {
    _setLoading(true);

    try {
      await _pantryService.deletePantryItem(itemId);
      _pantryItems.removeWhere((item) => item.id == itemId);
      _error = '';
    } catch (e) {
      _error = 'Failed to delete pantry item: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Process items from image scan
  Future<void> processScanResults(List<Map<String, dynamic>> scanResults) async {
    _setLoading(true);

    try {
      for (var result in scanResults) {
        // Check if the item already exists in the pantry
        final existingIndex = _pantryItems.indexWhere(
                (item) => item.name.toLowerCase() == result['name'].toLowerCase()
        );

        if (existingIndex >= 0) {
          // Update the existing item quantity
          final existingItem = _pantryItems[existingIndex];
          final updatedQuantity = existingItem.quantity + (result['quantity'] ?? 1.0);

          await updateItemQuantity(existingItem.id, updatedQuantity);
        } else {
          // Create a new item
          final newItem = PantryItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: result['name'],
            category: result['category'] ?? 'Other',
            quantity: result['quantity'] ?? 1.0,
            unit: MeasurementUnit.values.firstWhere(
                  (unit) => unit.toString().split('.').last == (result['unit'] ?? 'pieces'),
              orElse: () => MeasurementUnit.pieces,
            ),
            lowStockThreshold: 1.0,
            purchaseDate: DateTime.now(),
          );

          await addPantryItem(newItem);
        }
      }

      _error = '';
    } catch (e) {
      _error = 'Failed to process scan results: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Search pantry items by name or category
  List<PantryItem> searchItems(String query) {
    if (query.isEmpty) return _pantryItems;

    final lowerCaseQuery = query.toLowerCase();
    return _pantryItems.where((item) {
      return item.name.toLowerCase().contains(lowerCaseQuery) ||
          item.category.toLowerCase().contains(lowerCaseQuery) ||
          (item.notes != null && item.notes!.toLowerCase().contains(lowerCaseQuery));
    }).toList();
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Helper method to sort items alphabetically
  void _sortItems() {
    _pantryItems.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  // Get all categories from current pantry items
  List<String> get categories {
    final Set<String> categorySet = _pantryItems.map((item) => item.category).toSet();
    final List<String> categories = categorySet.toList();
    categories.sort();
    return categories;
  }

  // Cache pantry data to local storage for offline access
  Future<void> cachePantryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pantryItemsJson = jsonEncode(_pantryItems.map((item) => item.toJson()).toList());
      await prefs.setString('cached_pantry_items', pantryItemsJson);
    } catch (e) {
      debugPrint('Failed to cache pantry data: ${e.toString()}');
    }
  }

  // Load cached pantry data
  Future<void> loadCachedPantryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_pantry_items');

      if (cachedData != null && cachedData.isNotEmpty) {
        final List<dynamic> decodedData = jsonDecode(cachedData);
        _pantryItems = decodedData
            .map((itemJson) => PantryItem.fromJson(itemJson))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load cached pantry data: ${e.toString()}');
    }
  }
}