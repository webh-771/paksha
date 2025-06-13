import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/pantry_provider.dart';
import '../core/models/pantry_item.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/ingredient_tile.dart';
import 'add_item_page.dart';
import 'image_scan_page.dart';

class PantryPage extends StatefulWidget {
  const PantryPage({Key? key}) : super(key: key);

  @override
  _PantryPageState createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load pantry items when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pantryProvider = Provider.of<PantryProvider>(context, listen: false);
      pantryProvider.loadPantryItems();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddItem([PantryItem? item]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemPage(
          itemToEdit: item,
        ),
      ),
    );
  }

  void _navigateToScanItem() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImageScanPage()),
    );
  }

  void _showSearchBar() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        final pantryProvider = Provider.of<PantryProvider>(context, listen: false);
        final categories = ['All', ...pantryProvider.categories];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
                child: Row(
                  children: [
                    Text(
                      'Filter by Category',
                      style: AppTextStyles.headline3,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ListTile(
                      leading: category != 'All'
                          ? Icon(
                        PantryCategories.getIconForCategory(category),
                        color: PantryCategories.getColorForCategory(category),
                      )
                          : const Icon(Icons.all_inclusive),
                      title: Text(category),
                      selected: _selectedCategory == category,
                      selectedTileColor: AppColors.secondarySaffronLight.withOpacity(0.2),
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.pantryTitle, style: AppTextStyles.headline2.copyWith(color: AppColors.textLight)),
        backgroundColor: AppColors.primarySaffron,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : AppIcons.search),
            onPressed: _showSearchBar,
          ),
          IconButton(
            icon: Icon(AppIcons.filter),
            onPressed: _showFilterOptions,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_isSearchVisible ? 100 : 50),
          child: Column(
            children: [
              if (_isSearchVisible)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textSubtitle),
                        SizedBox(width: AppDimensions.sm),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: AppStrings.search,
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: AppColors.textSubtitle),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'All Items'),
                  Tab(text: 'Low Stock'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_selectedCategory != 'All')
            Container(
              color: AppColors.backgroundLight,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    PantryCategories.getIconForCategory(_selectedCategory),
                    color: PantryCategories.getColorForCategory(_selectedCategory),
                  ),
                  SizedBox(width: AppDimensions.sm),
                  Text(
                    'Filtered by: $_selectedCategory',
                    style: AppTextStyles.subtitle1.copyWith(
                      color: PantryCategories.getColorForCategory(_selectedCategory),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'All';
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: Consumer<PantryProvider>(
              builder: (context, pantryProvider, child) {
                if (pantryProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primarySaffron),
                  ));
                }

                List<PantryItem> filteredItems = _getFilteredItems(pantryProvider.pantryItems);

                if (filteredItems.isEmpty) {
                  return _buildEmptyState();
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // All Items Tab
                    _buildPantryItemsList(filteredItems),

                    // Low Stock Tab
                    _buildPantryItemsList(
                      filteredItems.where((item) => item.isLowStock).toList(),
                      isLowStock: true,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'scan',
            onPressed: _navigateToScanItem,
            backgroundColor: AppColors.primaryMintGreen,
            child: const Icon(AppIcons.scan),
          ),
          const SizedBox(height: AppDimensions.md),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _navigateToAddItem(),
            backgroundColor: AppColors.primarySaffron,
            child: const Icon(AppIcons.add),
          ),
        ],
      ),
    );
  }

  List<PantryItem> _getFilteredItems(List<PantryItem> items) {
    List<PantryItem> filteredItems = List.from(items);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredItems = filteredItems
          .where((item) =>
      item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.notes != null && item.notes!.toLowerCase().contains(_searchQuery.toLowerCase())))
          .toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filteredItems = filteredItems.where((item) => item.category == _selectedCategory).toList();
    }

    // Sort items by name
    filteredItems.sort((a, b) => a.name.compareTo(b.name));

    return filteredItems;
  }

  Widget _buildPantryItemsList(List<PantryItem> items, {bool isLowStock = false}) {
    // Group items by category
    final Map<String, List<PantryItem>> itemsByCategory = {};

    for (var item in items) {
      if (!itemsByCategory.containsKey(item.category)) {
        itemsByCategory[item.category] = [];
      }
      itemsByCategory[item.category]!.add(item);
    }

    // Sort categories alphabetically
    final sortedCategories = itemsByCategory.keys.toList()..sort();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLowStock ? AppIcons.warning : AppIcons.pantry,
              size: 72,
              color: isLowStock ? AppColors.warning : AppColors.primarySaffron,
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              isLowStock
                  ? 'No low stock items'
                  : AppStrings.emptyPantryMessage,
              style: AppTextStyles.subtitle1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.lg),
            if (!isLowStock)
              CustomButton(
                text: 'Add Your First Item',
                icon: AppIcons.add,
                onPressed: () => _navigateToAddItem(),
                backgroundColor: AppColors.primarySaffron,
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.md),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryItems = itemsByCategory[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: AppDimensions.md,
                bottom: AppDimensions.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    PantryCategories.getIconForCategory(category),
                    color: PantryCategories.getColorForCategory(category),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    category,
                    style: AppTextStyles.headline3.copyWith(
                      color: PantryCategories.getColorForCategory(category),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    '(${categoryItems.length})',
                    style: AppTextStyles.subtitle2,
                  ),
                ],
              ),
            ),
            const Divider(),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: categoryItems.length,
              itemBuilder: (context, itemIndex) {
                final item = categoryItems[itemIndex];
                return IngredientTile(
                  pantryItem: item,
                  onTap: () => _showItemDetails(item),
                  onEdit: () => _editItem(item),
                  onDelete: () => _deleteItem(item), item: item,
                );
              },
            ),
            const SizedBox(height: AppDimensions.md),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_pantry.png',
            height: 150,
            // If you don't have this asset, use an icon instead
            errorBuilder: (context, error, stackTrace) => Icon(
              AppIcons.pantry,
              size: 100,
              color: AppColors.primarySaffron.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Text(
            AppStrings.emptyPantryMessage,
            style: AppTextStyles.subtitle1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.xl),
          CustomButton(
            text: 'Add First Item',
            icon: AppIcons.add,
            onPressed: () => _navigateToAddItem(),
            backgroundColor: AppColors.primarySaffron,
          ),
          const SizedBox(height: AppDimensions.md),
          CustomButton(
            text: 'Scan Items',
            icon: AppIcons.scan,
            onPressed: _navigateToScanItem,
            backgroundColor: AppColors.primaryMintGreen,
          ),
        ],
      ),
    );
  }

  void _showItemDetails(PantryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    PantryCategories.getIconForCategory(item.category),
                    color: PantryCategories.getColorForCategory(item.category),
                    size: 32,
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Text(
                      item.name,
                      style: AppTextStyles.headline2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppDimensions.md),
              _buildDetailRow('Category', item.category),
              _buildDetailRow('Quantity', '${item.quantity} ${item.unitString}'),
              if (item.expiryDate != null)
                _buildDetailRow('Expires', _formatDate(item.expiryDate!)),
              _buildDetailRow('Purchased', _formatDate(item.purchaseDate)),
              if (item.cost > 0)
                _buildDetailRow('Cost', '\$${item.cost.toStringAsFixed(2)}'),
              if (item.notes != null && item.notes!.isNotEmpty)
                _buildDetailRow('Notes', item.notes!),
              const SizedBox(height: AppDimensions.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Edit',
                      icon: AppIcons.edit,
                      onPressed: () {
                        Navigator.pop(context);
                        _editItem(item);
                      },
                      backgroundColor: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: CustomButton(
                      text: 'Delete',
                      icon: AppIcons.delete,
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteItem(item);
                      },
                      backgroundColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyText1,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _editItem(PantryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemPage(
          itemToEdit: item,
        ),
      ),
    );
  }

  void _deleteItem(PantryItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Are you sure you want to delete ${item.name}?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
              onPressed: () {
                final pantryProvider = Provider.of<PantryProvider>(context, listen: false);
                pantryProvider.deletePantryItem(item.id);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} has been deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        pantryProvider.addPantryItem(item);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}