import 'package:flutter/foundation.dart';

// Enum for the unit of measurement
enum MeasurementUnit {
  grams,
  kilograms,
  milliliters,
  liters,
  pieces,
  tablespoons,
  teaspoons,
  cups,
  ounces,
  pounds,
  other, pcs
}

class PantryItem {
  final String id;
  final String name;
  final String category;
  double quantity;
  final MeasurementUnit unit;
  final double lowStockThreshold;
  final DateTime? expiryDate;
  final DateTime purchaseDate;
  final double cost;
  final String? imageUrl;
  final String? notes;

  PantryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.lowStockThreshold,
    this.expiryDate,
    required this.purchaseDate,
    this.cost = 0.0,
    this.imageUrl,
    this.notes,
  });

  // Convert unit enum to string for display
  String get unitString {
    switch (unit) {
      case MeasurementUnit.grams:
        return 'g';
      case MeasurementUnit.kilograms:
        return 'kg';
      case MeasurementUnit.milliliters:
        return 'ml';
      case MeasurementUnit.liters:
        return 'L';
      case MeasurementUnit.pieces:
        return 'pcs';
      case MeasurementUnit.tablespoons:
        return 'tbsp';
      case MeasurementUnit.teaspoons:
        return 'tsp';
      case MeasurementUnit.cups:
        return 'cups';
      case MeasurementUnit.ounces:
        return 'oz';
      case MeasurementUnit.pounds:
        return 'lbs';
      case MeasurementUnit.other:
        return '';
      case MeasurementUnit.pcs:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  // Check if the item is low in stock
  bool get isLowStock => quantity <= lowStockThreshold;

  // Check if the item is expiring soon (within 3 days)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final difference = expiryDate!.difference(now).inDays;
    return difference >= 0 && difference <= 3;
  }

  // Check if the item is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  // Get days until expiry
  int get daysUntilExpiry {
    if (expiryDate == null) return -1;
    final now = DateTime.now();
    return expiryDate!.difference(now).inDays;
  }

  // Factory method to create from JSON
  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      quantity: json['quantity'].toDouble(),
      unit: MeasurementUnit.values.firstWhere(
            (e) => e.toString() == 'MeasurementUnit.${json['unit']}',
        orElse: () => MeasurementUnit.other,
      ),
      lowStockThreshold: json['lowStockThreshold'].toDouble(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      purchaseDate: DateTime.parse(json['purchaseDate']),
      cost: json['cost']?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'],
      notes: json['notes'],
    );
  }

  get imagePath => null;

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit.toString().split('.').last,
      'lowStockThreshold': lowStockThreshold,
      'expiryDate': expiryDate?.toIso8601String(),
      'purchaseDate': purchaseDate.toIso8601String(),
      'cost': cost,
      'imageUrl': imageUrl,
      'notes': notes,
    };
  }

  // Create a copy of the item with updated fields
  PantryItem copyWith({
    String? id,
    String? name,
    String? category,
    double? quantity,
    MeasurementUnit? unit,
    double? lowStockThreshold,
    DateTime? expiryDate,
    DateTime? purchaseDate,
    double? cost,
    String? imageUrl,
    String? notes,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      expiryDate: expiryDate ?? this.expiryDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      cost: cost ?? this.cost,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'PantryItem(id: $id, name: $name, quantity: $quantity ${unitString})';
  }
}