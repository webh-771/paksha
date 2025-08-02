import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  // Named routes for each tab. Adjust if your GoRouter or routes differ.
  static const List<String> routes = [
    '/home',
    '/recipes',        // <-- Use plural for consistency
    '/shopping-list',
    '/profile',
  ];

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFF1B2B1B);
    const Color primaryGreen = Color(0xFF4CAF50);
    const Color textSecondary = Color(0xFFB0B0B0);

    return BottomNavigationBar(
      backgroundColor: backgroundColor,
      selectedItemColor: primaryGreen,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        // Always notify parent of tab switch:
        onTap(index);

        // OPTIONAL: If you want the BottomNavBar to handle navigation itself,
        // uncomment the code below and make sure your routes are setup:
        // Navigator.of(context).pushNamedAndRemoveUntil(
        //   routes[index],
        //   (route) => false,
        // );

        // For GoRouter usage, you might do (in parent):
        // context.go(BottomNavBar.routes[index]);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: 'Recipes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Shopping',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
