import 'package:flutter/material.dart';
import '../home/home_page.dart';
import '../../recipes/recipes_page.dart';
import '../../shopping_list/shopping_list_page.dart';
import '../../profile/profile_page.dart';
import 'bottom_nav_bar.dart';

class MainNav extends StatefulWidget {
  const MainNav({Key? key, required Widget child}) : super(key: key);

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    RecipesPage(),
  ];

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    // If using named navigation (e.g., GoRouter or Navigator), you can also:
    // context.go(BottomNavBar.routes[index]); // (if using GoRouter)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
