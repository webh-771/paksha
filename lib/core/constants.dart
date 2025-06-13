import 'package:flutter/material.dart';

/// Constants file that contains app-wide constants including colors, dimensions,
/// text styles, and icon definitions used throughout the application.

/// Color constants used throughout the app
class AppColors {
  // Primary colors
  static const Color primarySaffron = Color(0xFFFFAB40);
  static const Color primaryMintGreen = Color(0xFF66BB6A);
  static const Color primary = primarySaffron;

  // Secondary colors
  static const Color secondarySaffronLight = Color(0xFFFFECB3);
  static const Color secondaryMintLight = Color(0xFFB2DFDB);

  // Background colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF212121);

  // Text colors
  static const Color textLight = Color(0xFFFAFAFA);
  static const Color textDark = Color(0xFF212121);
  static const Color darkText = Color(0xFF212121);
  static const Color textSubtitle = Color(0xFF757575);

  // Status colors
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);
}

/// Dimension constants for consistent spacing and sizing
class AppDimensions {
  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Border radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // Button sizes
  static const double buttonHeight = 48.0;
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightLg = 56.0;

  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
}

/// Text styles for consistent typography
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textSubtitle,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16.0,
    color: AppColors.textDark,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14.0,
    color: AppColors.textDark,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12.0,
    color: AppColors.textSubtitle,
  );
}

/// App-wide string constants
class AppStrings {
  // App title
  static const String appTitle = 'Pantry Manager';

  // Page titles
  static const String pantryTitle = 'My Pantry';
  static const String addItemTitle = 'Add Item';
  static const String editItemTitle = 'Edit Item';
  static const String scanItemTitle = 'Scan Items';

  // Button texts
  static const String add = 'Add';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String search = 'Search items...';

  // Empty states
  static const String emptyPantryMessage = 'Your pantry is empty.\nAdd items to get started!';
  static const String noLowStockMessage = 'No items are running low';

  // Form labels
  static const String itemName = 'Item Name';
  static const String category = 'Category';
  static const String quantity = 'Quantity';
  static const String unit = 'Unit';
  static const String expiryDate = 'Expiry Date';
  static const String purchaseDate = 'Purchase Date';
  static const String cost = 'Cost';
  static const String notes = 'Notes';
}

/// App icon constants using Material icons
class AppIcons {
  static const IconData add = Icons.add;
  static const IconData delete = Icons.delete_outline;
  static const IconData edit = Icons.edit;
  static const IconData pantry = Icons.kitchen;
  static const IconData recipes = Icons.restaurant_menu;
  static const IconData groceries = Icons.shopping_cart;
  static const IconData settings = Icons.settings;
  static const IconData scan = Icons.camera_alt;
  static const IconData search = Icons.search;
  static const IconData filter = Icons.filter_list;
  static const IconData warning = Icons.warning_amber;
  static const IconData date = Icons.calendar_today;
  static const IconData cost = Icons.attach_money;
  static const IconData notes = Icons.notes;
}

/// Pantry category definitions with associated icons and colors
class PantryCategories {
  static const List<String> defaultCategories = [
    'Fruits',
    'Vegetables',
    'Dairy',
    'Meat',
    'Grains',
    'Canned Goods',
    'Spices',
    'Beverages',
    'Snacks',
    'Baking',
    'Frozen',
    'Condiments',
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
      case 'meat':
        return Icons.restaurant;
      case 'grains':
        return Icons.grass;
      case 'canned goods':
        return Icons.inventory_2;
      case 'spices':
        return Icons.spa;
      case 'beverages':
        return Icons.local_drink;
      case 'snacks':
        return Icons.cookie;
      case 'baking':
        return Icons.cake;
      case 'frozen':
        return Icons.ac_unit;
      case 'condiments':
        return Icons.hourglass_bottom_sharp;
      default:
        return Icons.category;
    }
  }

  static Color getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return Colors.red[400]!;
      case 'vegetables':
        return Colors.green[400]!;
      case 'dairy':
        return Colors.lightBlue[200]!;
      case 'meat':
        return Colors.redAccent[400]!;
      case 'grains':
        return Colors.amber[700]!;
      case 'canned goods':
        return Colors.blueGrey[400]!;
      case 'spices':
        return Colors.deepOrange[300]!;
      case 'beverages':
        return Colors.blue[400]!;
      case 'snacks':
        return Colors.amber[400]!;
      case 'baking':
        return Colors.brown[300]!;
      case 'frozen':
        return Colors.lightBlue[300]!;
      case 'condiments':
        return Colors.yellow[700]!;
      default:
        return Colors.grey[500]!;
    }
  }
}

/// Unit types for pantry items
class UnitTypes {
  static const List<String> units = [
    'piece(s)',
    'g',
    'kg',
    'ml',
    'L',
    'oz',
    'lb',
    'cup(s)',
    'tbsp',
    'tsp',
    'packet(s)',
    'can(s)',
    'bottle(s)',
    'box(es)'
  ];
}