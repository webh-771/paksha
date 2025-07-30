import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paksha/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Budget data
  double _weeklyBudget = 2500;
  double _spentAmount = 0;

  // Data loading states
  bool _loadingPantry = true;
  bool _loadingRecipes = true;
  bool _loadingBudget = true;

  // Data lists
  List<Map<String, dynamic>> _quickRecipes = [];
  List<Map<String, dynamic>> _pantryAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPantryAlerts();
    _loadQuickRecipes();
    _loadBudgetData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      try {
        await _firestore.collection('users').doc(_currentUser!.uid).get();
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  Future<void> _loadPantryAlerts() async {
    if (_currentUser != null) {
      try {
        final pantrySnapshot = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('pantry')
            .where('quantity', isLessThanOrEqualTo: 2)
            .get();

        final List<Map<String, dynamic>> alerts = [];

        for (var doc in pantrySnapshot.docs) {
          final data = doc.data();
          final int quantity = data['quantity'] ?? 0;

          alerts.add({
            'id': doc.id,
            'item': data['name'] ?? 'Unknown Item',
            'status': quantity <= 0 ? 'Out' : 'Low',
            'icon': quantity <= 0 ? Icons.cancel_outlined : Icons.error_outline,
            'color': quantity <= 0 ? Colors.red : Colors.amber,
          });
        }

        setState(() {
          _pantryAlerts = alerts;
          _loadingPantry = false;
        });
      } catch (e) {
        debugPrint('Error loading pantry alerts: $e');
        setState(() {
          _loadingPantry = false;
        });
      }
    } else {
      setState(() {
        _loadingPantry = false;
      });
    }
  }

  Future<void> _loadQuickRecipes() async {
    if (_currentUser != null) {
      try {
        final recipesSnapshot = await _firestore
            .collection('recipes')
            .limit(3)
            .get();

        final List<Map<String, dynamic>> recipes = [];

        for (var doc in recipesSnapshot.docs) {
          final data = doc.data();
          recipes.add({
            'id': doc.id,
            'name': data['name'] ?? 'Recipe',
            'time': '${data['prepTime'] ?? 30} min',
            'cost': '₹${data['cost'] ?? 100}',
            'image': data['imageUrl'] ?? 'https://via.placeholder.com/150',
          });
        }

        setState(() {
          _quickRecipes = recipes;
          _loadingRecipes = false;
        });
      } catch (e) {
        debugPrint('Error loading recipes: $e');
        setState(() {
          _loadingRecipes = false;
          _quickRecipes = [
            {
              'id': '1',
              'name': 'Paneer Tikka',
              'time': '25 min',
              'cost': '₹90',
              'image': 'https://via.placeholder.com/150',
            },
            {
              'id': '2',
              'name': 'Mushroom Pulao',
              'time': '30 min',
              'cost': '₹65',
              'image': 'https://via.placeholder.com/150',
            },
            {
              'id': '3',
              'name': 'Veg Soup',
              'time': '18 min',
              'cost': '₹45',
              'image': 'https://via.placeholder.com/150',
            },
          ];
        });
      }
    } else {
      setState(() {
        _loadingRecipes = false;
      });
    }
  }

  Future<void> _loadBudgetData() async {
    if (_currentUser != null) {
      try {
        final now = DateTime.now();
        final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        final startDate = DateFormat('yyyy-MM-dd').format(startOfWeek);
        final endDate = DateFormat('yyyy-MM-dd').format(endOfWeek);

        final budgetDoc = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('budgets')
            .doc(startDate)
            .get();

        final expensesSnapshot = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('expenses')
            .where('date', isGreaterThanOrEqualTo: startDate)
            .where('date', isLessThanOrEqualTo: endDate)
            .get();

        double totalExpenses = 0;
        for (var doc in expensesSnapshot.docs) {
          totalExpenses += (doc.data()['amount'] ?? 0).toDouble();
        }

        setState(() {
          if (budgetDoc.exists) {
            _weeklyBudget = (budgetDoc.data()?['amount'] ?? 2500).toDouble();
          }
          _spentAmount = totalExpenses;
          _loadingBudget = false;
        });
      } catch (e) {
        debugPrint('Error loading budget data: $e');
        setState(() {
          _loadingBudget = false;
        });
      }
    } else {
      setState(() {
        _loadingBudget = false;
      });
    }
  }

  Future<void> _addToShoppingList(String itemName) async {
    if (_currentUser != null) {
      try {
        final existingItemQuery = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('shopping_list')
            .where('name', isEqualTo: itemName)
            .limit(1)
            .get();

        if (existingItemQuery.docs.isNotEmpty) {
          final docId = existingItemQuery.docs.first.id;
          final currentQuantity = existingItemQuery.docs.first.data()['quantity'] ?? 0;

          await _firestore
              .collection('users')
              .doc(_currentUser!.uid)
              .collection('shopping_list')
              .doc(docId)
              .update({
            'quantity': currentQuantity + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          await _firestore
              .collection('users')
              .doc(_currentUser!.uid)
              .collection('shopping_list')
              .add({
            'name': itemName,
            'quantity': 1,
            'checked': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$itemName added to shopping list')),
          );
        }
      } catch (e) {
        debugPrint('Error adding to shopping list: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add item to shopping list')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userName = _currentUser?.displayName ?? 'Chef';
    final double budgetPercentage = _weeklyBudget > 0 ? _spentAmount / _weeklyBudget : 0;

    // Theme colors matching the new dark green design:
    const Color backgroundColor = Color(0xFF1B2B1B);        // Outer background
    const Color cardColor = Color(0xFF2A3B2A);              // Main container color
    const Color primaryGreen = Color(0xFF4CAF50);           // Bright accent
    const Color textPrimary = Colors.white;
    const Color textSecondary = Color(0xFFB0B0B0);
    const Color inputBackground = Color(0xFF3A4B3A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryGreen,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paksha',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Hello, $userName!',
                        style: const TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: textPrimary),
                    onPressed: () async {
                      await AuthService().logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // QUICK ACTION BUTTONS ROW
              _QuickActionsBar(),

              const SizedBox(height: 32),

              // BUDGET TRACKER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Budget Tracker',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _loadingBudget
                        ? const Center(child: CircularProgressIndicator())
                        : Row(
                      children: [
                        CircularPercentIndicator(
                          radius: 48.0,
                          lineWidth: 8.0,
                          percent: budgetPercentage.clamp(0.0, 1.0),
                          center: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(budgetPercentage * 100).toInt()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Used',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                          progressColor: budgetPercentage > 0.8
                              ? Colors.red
                              : budgetPercentage > 0.6
                              ? Colors.amber
                              : primaryGreen,
                          backgroundColor: inputBackground,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Budget: ₹${_weeklyBudget.toInt()}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Spent: ₹${_spentAmount.toInt()}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Remain: ₹${(_weeklyBudget - _spentAmount).toInt()}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: budgetPercentage > 0.8 ? Colors.red : primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // QUICK RECIPES
              const Text(
                'Quick Recipes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              _loadingRecipes
                  ? const Center(child: CircularProgressIndicator())
                  : _quickRecipes.isEmpty
                  ? const Center(
                child: Text(
                  'No recipes available',
                  style: TextStyle(color: textSecondary),
                ),
              )
                  : Row(
                children: _quickRecipes.take(3).map((recipe) {
                  final index = _quickRecipes.indexOf(recipe);
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < 2 ? 12 : 0,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: inputBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.restaurant,
                                color: textSecondary,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            recipe['name'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Pantry alerts
              if (!_loadingPantry && _pantryAlerts.isNotEmpty) ...[
                const Text(
                  'Pantry Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: _pantryAlerts.map((alert) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Icon(
                              alert['icon'] as IconData,
                              color: alert['color'] as Color,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${alert['item']} is ${alert['status']}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                _addToShoppingList(alert['item']);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: primaryGreen.withOpacity(0.18),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Add to List',
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
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
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.push('/recipes');
              break;
            case 2:
              context.push('/shopping-list');
              break;
            case 3:
              context.push('/profile');
              break;
          }
        },
      ),
    );
  }
}

class _QuickActionsBar extends StatelessWidget {
  const _QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFF2A3B2A);
    const Color inputBackground = Color(0xFF3A4B3A);
    const Color primaryGreen = Color(0xFF4CAF50);
    const Color textPrimary = Colors.white;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickActionBtn(
          icon: Icons.auto_awesome,
          label: "Generator",
          onTap: () => context.push('/recipe-generator'),
        ),
        _QuickActionBtn(
          icon: Icons.shopping_basket_outlined,
          label: "My Pantry",
          onTap: () => context.push('/pantry'),
        ),
        _QuickActionBtn(
          icon: Icons.shopping_cart_outlined,
          label: "Shop List",
          onTap: () => context.push('/shopping-list'),
        ),
        _QuickActionBtn(
          icon: Icons.calendar_today_outlined,
          label: "Meal Plan",
          onTap: () => context.push('/meal-planner'),
        ),
        _QuickActionBtn(
          icon: Icons.smart_toy_outlined,
          label: "Assistant",
          onTap: () => context.push('/ai-assistant'),
        ),
      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color inputBackground = Color(0xFF3A4B3A);
    const Color primaryGreen = Color(0xFF4CAF50);
    const Color textPrimary = Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: inputBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryGreen, size: 26),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 64,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
