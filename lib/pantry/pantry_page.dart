import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart'; // Make sure colors conform to new theme
import '../../providers/pantry_provider.dart';
import '../core/models/pantry_item.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/ingredient_tile.dart' hide PantryCategories;
import 'add_item_page.dart';
import 'image_scan_page.dart';

class PantryPage extends StatefulWidget {
  const PantryPage({Key? key}) : super(key: key);

  @override
  _PantryPageState createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = "All";
  bool _lowStockOnly = false;

  void _navigateToAddItem([PantryItem? item]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemPage(itemToEdit: item),
      ),
    );
  }

  void _navigateToScanItem() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImageScanPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // New colors (edit to match your brand/desired scheme!)
    const Color background = Color(0xFF19271B);      // Page bg
    const Color cardColor = Color(0xFF233529);       // Card bg
    const Color greenAccent = Color(0xFF4CAF50);     // Monthec green
    const Color yellowAccent = Color(0xFFF7D049);    // For lemons etc.
    const Color darkText = Colors.white;
    const Color subtitle = Color(0xFFB7C4B7);
    const Color searchCardBg = Color(0xFF243424);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 2,
        automaticallyImplyLeading: false,
        title: const Text("My Pantry", style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // Camera Button for Scanning
          IconButton(
            tooltip: 'Scan Item',
            icon: const Icon(Icons.camera_alt_outlined, color: greenAccent, size: 26),
            onPressed: _navigateToScanItem,
          ),
          // Add Item Button
          IconButton(
            tooltip: "+ Add Item",
            icon: const Icon(Icons.add_circle_outline, color: greenAccent, size: 26),
            onPressed: () => _navigateToAddItem(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _pantrySearchAndFilter(context, searchCardBg, greenAccent, darkText, subtitle),
          ),
        ),
      ),
      body: Container(
        color: background,
        child: Consumer<PantryProvider>(
          builder: (context, provider, _) {
            final allItems = provider.pantryItems;
            final filteredItems = allItems
                .where((item) {
              if (_searchQuery.isNotEmpty &&
                  !item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
                return false;
              }
              if (_selectedFilter != "All" && item.category != _selectedFilter) {
                return false;
              }
              if (_lowStockOnly && !item.isLowStock) {
                return false;
              }
              return true;
            })
                .toList();

            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator(color: greenAccent));
            }

            if (filteredItems.isEmpty) {
              return _buildEmptyState(context, greenAccent);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredItems.length,
              itemBuilder: (context, i) {
                final item = filteredItems[i];
                return _PantryItemCard(
                  item: item,
                  onTap: () => _showDetails(context, item),
                  onEdit: () => _navigateToAddItem(item),
                  onDelete: () => _deleteItem(context, item),
                  greenAccent: greenAccent,
                  yellowAccent: yellowAccent,
                  cardColor: cardColor,
                  subtitle: subtitle,
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: null, // Camera and Add are now in AppBar for compactness.
    );
  }

  Widget _pantrySearchAndFilter(
      BuildContext context,
      Color cardBg,
      Color accent,
      Color darkText,
      Color subtitle,
      ) {
    final provider = Provider.of<PantryProvider>(context, listen: false);
    final categories = ["All", ...provider.categories];
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: darkText),
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: subtitle),
                border: InputBorder.none,
                hintText: 'Search',
                hintStyle: const TextStyle(color: Color(0xFFB7C4B7)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Category Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: cardBg,
              value: _selectedFilter,
              icon: Icon(Icons.keyboard_arrow_down, color: accent),
              style: TextStyle(color: darkText),
              items: categories
                  .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat, style: TextStyle(color: cat == "All" ? subtitle : darkText)),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFilter = v!),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Low Stock Toggle
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Show only Low Stock',
                icon: Icon(
                  _lowStockOnly ? Icons.warning : Icons.warning_amber_outlined,
                  color: _lowStockOnly ? Colors.amber : subtitle,
                  size: 22,
                ),
                onPressed: () => setState(() => _lowStockOnly = !_lowStockOnly),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, Color greenAccent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 72),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, color: greenAccent.withOpacity(0.40), size: 90),
            const SizedBox(height: 30),
            const Text(
              "No items found in your pantry.",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: greenAccent,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: const Text("Add Item", style: TextStyle(color: Colors.white, fontSize: 15)),
              onPressed: () => _navigateToAddItem(),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text("Scan Item"),
              style: OutlinedButton.styleFrom(
                foregroundColor: greenAccent,
                side: BorderSide(color: greenAccent, width: 1.7),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _navigateToScanItem,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext ctx, PantryItem item) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: const Color(0xFF233529), // Card color
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
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
                const SizedBox(width: 14),
                Expanded(
                  child: Text(item.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToAddItem(item);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteItem(context, item);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Quantity: ${item.quantity} ${item.unitString}",
              style: const TextStyle(color: Color(0xFFB7C4B7), fontSize: 15),
            ),
            const SizedBox(height: 7),
            if (item.notes != null && item.notes!.isNotEmpty)
              Text(
                item.notes!,
                style: const TextStyle(color: Color(0xFFB7C4B7)),
              ),
          ],
        ),
      ),
    );
  }

  void _deleteItem(BuildContext ctx, PantryItem item) {
    showDialog(
      context: ctx,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF233529),
        title: const Text('Delete Item', style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete '${item.name}'?",
            style: const TextStyle(color: Color(0xFFB7C4B7))),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Provider.of<PantryProvider>(ctx, listen: false).deletePantryItem(item.id);
              Navigator.pop(ctx);
            },
          )
        ],
      ),
    );
  }
}

// --- Pantry Item Card for Modern Look ---
class _PantryItemCard extends StatelessWidget {
  final PantryItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color greenAccent;
  final Color yellowAccent;
  final Color cardColor;
  final Color subtitle;

  const _PantryItemCard({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.greenAccent,
    required this.yellowAccent,
    required this.cardColor,
    required this.subtitle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Optionally use image, else use icon
    Widget leading;
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(item.imagePath!, width: 58, height: 58, fit: BoxFit.cover),
      );
    } else {
      leading = Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: (item.name.toLowerCase().contains('lemon'))
              ? yellowAccent
              : greenAccent.withOpacity(0.17),
        ),
        child: Icon(
          PantryCategories.getIconForCategory(item.category),
          color: PantryCategories.getColorForCategory(item.category),
          size: 32,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(vertical: 9),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 7),
                    Text('${item.quantity} ${item.unitString}',
                        style: TextStyle(color: subtitle, fontSize: 14)),
                  ],
                ),
              ),
              // Low stock badge
              if (item.isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text("Low", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
