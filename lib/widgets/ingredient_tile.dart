import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/models/pantry_item.dart';

class IngredientTile extends StatelessWidget {
  final PantryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const IngredientTile({
    Key? key,
    required this.item,
    required this.onTap,
    required this.onDelete, required PantryItem pantryItem, required void Function() onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isExpiringSoon = item.expiryDate != null &&
        item.expiryDate!.difference(DateTime.now()).inDays <= 3;
    final bool isExpired = item.expiryDate != null &&
        item.expiryDate!.isBefore(DateTime.now());

    // Determine the status and color
    String? status;
    Color statusColor = Colors.transparent;

    if (isExpired) {
      status = 'Expired';
      statusColor = Colors.red;
    } else if (isExpiringSoon) {
      status = 'Expiring Soon';
      statusColor = Colors.orange;
    }

    // Format the expiry date
    String? expiryText;
    if (item.expiryDate != null) {
      if (isExpired) {
        final daysDifference = DateTime.now().difference(item.expiryDate!).inDays;
        expiryText = daysDifference == 0
            ? 'Expired today'
            : 'Expired ${daysDifference} ${daysDifference == 1 ? 'day' : 'days'} ago';
      } else {
        final daysDifference = item.expiryDate!.difference(DateTime.now()).inDays;
        expiryText = daysDifference == 0
            ? 'Expires today'
            : 'Expires in ${daysDifference} ${daysDifference == 1 ? 'day' : 'days'}';
      }
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Item'),
              content: Text('Are you sure you want to remove "${item.name}" from your pantry?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('DELETE'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        onDelete();
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(item.category).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(item.category),
                      color: _getCategoryColor(item.category),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (status != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quantity: ${item.quantity} ${item.unit}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (expiryText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            expiryText,
                            style: TextStyle(
                              color: isExpired ? Colors.red : isExpiringSoon ? Colors.orange : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      if (item.notes != null && item.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.note,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.notes!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Edit icon
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'dairy':
        return Icons.breakfast_dining;
      case 'grains':
        return Icons.grain;
      case 'proteins':
        return Icons.egg_alt;
      case 'spices':
        return Icons.soup_kitchen;
      default:
        return Icons.kitchen;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Colors.green;
      case 'fruits':
        return Colors.orange;
      case 'dairy':
        return Colors.blue;
      case 'grains':
        return Colors.amber;
      case 'proteins':
        return Colors.red;
      case 'spices':
        return Colors.deepPurple;
      default:
        return AppColors.primarySaffron;
    }
  }
}