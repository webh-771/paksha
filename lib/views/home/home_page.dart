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

  // Load user profile data
  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
        if (userDoc.exists) {
          // You can load user preferences here if needed
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  // Load pantry items that are low or out of stock
  Future<void> _loadPantryAlerts() async {
    if (_currentUser != null) {
      try {
        final pantrySnapshot = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('pantry')
            .where('quantity', isLessThanOrEqualTo: 2) // Items with low quantity
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

  // Load quick recipe suggestions
  Future<void> _loadQuickRecipes() async {
    if (_currentUser != null) {
      try {
        // Get user's recent recipe views to suggest similar ones
        final recipesSnapshot = await _firestore
            .collection('recipes')
            .limit(3) // Only get a few recipes for quick display
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
          // Use fallback recipes if needed
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
          ];
        });
      }
    } else {
      setState(() {
        _loadingRecipes = false;
      });
    }
  }

  // Load budget data
  Future<void> _loadBudgetData() async {
    if (_currentUser != null) {
      try {
        // Get the current week's budget
        final now = DateTime.now();
        final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        // Format dates for Firestore query
        final startDate = DateFormat('yyyy-MM-dd').format(startOfWeek);
        final endDate = DateFormat('yyyy-MM-dd').format(endOfWeek);

        // Get budget document
        final budgetDoc = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('budgets')
            .doc(startDate)
            .get();

        // Get expenses within date range
        final expensesSnapshot = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('expenses')
            .where('date', isGreaterThanOrEqualTo: startDate)
            .where('date', isLessThanOrEqualTo: endDate)
            .get();

        // Calculate total expenses
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

  // Add item to shopping list
  Future<void> _addToShoppingList(String itemName) async {
    if (_currentUser != null) {
      try {
        // First check if item already exists in shopping list
        final existingItemQuery = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('shopping_list')
            .where('name', isEqualTo: itemName)
            .limit(1)
            .get();

        if (existingItemQuery.docs.isNotEmpty) {
          // Item exists, update quantity
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
          // Item doesn't exist, add new item
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemName added to shopping list')),
        );
      } catch (e) {
        debugPrint('Error adding to shopping list: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add item to shopping list')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userName = _currentUser?.displayName ?? 'Chef';
    final double budgetPercentage = _weeklyBudget > 0 ? _spentAmount / _weeklyBudget : 0;

    // Theme colors based on style guide
    final Color primaryColor = const Color(0xFFE67E22); // Deep Saffron
    final Color accentColor = const Color(0xFFA3C6A0);  // Mint Green
    final Color neutralBase = const Color(0xFFFDF6EC);  // Soft Beige

    return Scaffold(
      backgroundColor: neutralBase,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: neutralBase,
              elevation: 0,
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.2),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Namaste, $userName!',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        'What would you like to cook today?',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Color(0xFF2C3E50)),
                  onPressed: () {
                    // Notifications page
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Color(0xFF2C3E50)),
                  onPressed: () async {
                    // Settings page
                    await AuthService().logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),

            // Main content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search + Voice/Image input
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search recipes or ingredients...',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                hintStyle: TextStyle(color: Colors.grey[400]),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.mic_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick actions
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'What can I cook with my pantry?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Get smart recipes using what you already have',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickAction(
                                icon: Icons.restaurant_menu,
                                label: 'Recipe\nGenerator',
                                onTap: () => context.push('/recipe-generator'),
                              ),
                              _buildQuickAction(
                                icon: Icons.shopping_basket_outlined,
                                label: 'My\nPantry',
                                onTap: () => context.push('/pantry'),
                              ),
                              _buildQuickAction(
                                icon: Icons.shopping_cart_outlined,
                                label: 'Shopping\nList',
                                onTap: () => context.push('/shopping-list'),
                              ),
                              _buildQuickAction(
                                icon: Icons.calendar_today_outlined,
                                label: 'Meal\nPlanner',
                                onTap: () => context.push('/meal-planner'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Budget section
                    const SizedBox(height: 24),
                    const Text(
                      'Weekly Budget Tracker',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _loadingBudget
                        ? const Center(child: CircularProgressIndicator())
                        : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircularPercentIndicator(
                            radius: 60.0,
                            lineWidth: 10.0,
                            percent: budgetPercentage > 1.0 ? 1.0 : budgetPercentage,
                            center: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(budgetPercentage * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.0,
                                  ),
                                ),
                                Text(
                                  'Used',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            progressColor: budgetPercentage > 0.8
                                ? Colors.red
                                : budgetPercentage > 0.6
                                ? Colors.amber
                                : accentColor,
                            backgroundColor: Colors.grey[200]!,
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
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Spent: ₹${_spentAmount.toInt()}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Remaining: ₹${(_weeklyBudget - _spentAmount).toInt()}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: budgetPercentage > 0.8 ? Colors.red : Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick recipe suggestions
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quick Recipes For You',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/recipes'),
                          child: Text(
                            'See All',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _loadingRecipes
                        ? const Center(child: CircularProgressIndicator())
                        : _quickRecipes.isEmpty
                        ? Center(
                      child: Text(
                        'No recipes available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                        : SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _quickRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _quickRecipes[index];
                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  child: Container(
                                    height: 100,
                                    width: double.infinity,
                                    color: primaryColor.withOpacity(0.2),
                                    child: Center(
                                      child: Icon(
                                        Icons.restaurant,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            recipe['time'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.currency_rupee,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          Text(
                                            recipe['cost'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Pantry alerts
                    if (!_loadingPantry && _pantryAlerts.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Pantry Alerts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 1),
                            ),
                          ],
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
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      _addToShoppingList(alert['item']);
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: primaryColor.withOpacity(0.1),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Add to List',
                                      style: TextStyle(
                                        color: primaryColor,
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

                    // Smart Assistant
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.smart_toy_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Smart Kitchen Assistant',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Get personalized cooking tips & ingredient substitutions',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: () => context.push('/ai-assistant'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket_outlined),
            activeIcon: Icon(Icons.shopping_basket),
            label: 'Pantry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Shopping',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation
          switch (index) {
            case 0: // Already on home
              break;
            case 1:
              context.push('/recipes');
              break;
            case 2:
              context.push('/pantry');
              break;
            case 3:
              context.push('/shopping-list');
              break;
            case 4:
              context.push('/profile');
              break;
          }
        },
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFE67E22),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}