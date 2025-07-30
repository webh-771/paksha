import 'package:flutter/material.dart';

/// Color constants used throughout the app (Green Themed)
class AppColors {
  // Primary colors
  static const Color primaryMintGreen = Color(0xFF66BB6A);   // Mint Green (main accent)
  static const Color primaryDarkGreen = Color(0xFF2E7D32);   // Dark Green (buttons, text)
  static const Color primary = primaryMintGreen;            // Alias to mint green

  // Secondary colors
  static const Color secondaryMintLight = Color(0xFFB2DFDB); // Soft mint/light accents
  static const Color secondaryDarkMint = Color(0xFF388E3C);  // Slightly darker mint

  // Background colors
  static const Color backgroundDark = Color(0xFF19271A);     // Very dark green background
  static const Color backgroundLight = Color(0xFF243923);    // Dark green for containers/cards

  // Text colors
  static const Color textLight = Color(0xFFF1F8E9);           // Off white / pale greenish (for dark backgrounds)
  static const Color textSubtitle = Color(0xFFA5D6A7);        // Light green text for subtitles
  static const Color textDark = Color(0xFF1B5E20);            // Darker green for text on light background

  // Status colors (adjusted to fit green theme)
  static const Color success = Color(0xFF81C784);            // Light success green
  static const Color error = Color(0xFFE57373);              // Soft red for errors
  static const Color warning = Color(0xFFFFB74D);            // Orange-ish warning
  static const Color info = Color(0xFF4DB6AC);               // Teal info

  // Additional
  static const Color cardBackground = backgroundLight;        // Card color same as light background
  static const Color shadowColor = Color(0xFF1B361E);

  static var darkText;          // Shadow color for dark green
}
class PantryCategories {
  static const List<String> defaultCategories = [
    'Fruits',
    'Vegetables',
    'Dairy',
    'Grains',
    'Meat',
    'Other'
  ];

  static IconData getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return Icons.apple;
      case 'vegetables':
        return Icons.eco;
      case 'dairy':
        return Icons.egg;
      case 'grains':
        return Icons.grain;
      case 'meat':
        return Icons.restaurant;
      default:
        return Icons.category;
    }
  }

  static Color getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return Colors.redAccent;
      case 'vegetables':
        return Colors.greenAccent;
      case 'dairy':
        return Colors.lightBlueAccent;
      case 'grains':
        return Colors.amberAccent;
      case 'meat':
        return Colors.deepOrangeAccent;
      default:
        return Colors.grey;
    }
  }
}