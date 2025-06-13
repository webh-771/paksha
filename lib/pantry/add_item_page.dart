import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../core/models/pantry_item.dart';
import '../../providers/pantry_provider.dart';
import '../core/constants.dart';
import '../../widgets/custom_dropdown.dart';
import '../services/pantry_service.dart';

class AddItemPage extends ConsumerStatefulWidget {
  final PantryItem? itemToEdit;

  const AddItemPage({Key? key, this.itemToEdit}) : super(key: key);

  @override
  ConsumerState<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends ConsumerState<AddItemPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _notesController;

  late String _selectedCategory;
  late MeasurementUnit _selectedUnit; // Changed to enum type
  late DateTime? _expiryDate;

  final pantryProvider = ChangeNotifierProvider<PantryProvider>((ref) {
    return PantryProvider(pantryService: PantryService());
  });


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.itemToEdit?.name ?? '');
    _quantityController = TextEditingController(
        text: widget.itemToEdit?.quantity.toString() ?? '');
    _notesController = TextEditingController(text: widget.itemToEdit?.notes ?? '');
    _selectedCategory = widget.itemToEdit?.category ?? 'Other';
    _selectedUnit = widget.itemToEdit?.unit ?? MeasurementUnit.pcs; // Use enum or default
    _expiryDate = widget.itemToEdit?.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final double quantity = double.parse(_quantityController.text);

      final PantryItem item = PantryItem(
        id: widget.itemToEdit?.id ?? const Uuid().v4(),
        name: _nameController.text,
        category: _selectedCategory,
        quantity: quantity,
        unit: _selectedUnit,
        lowStockThreshold: widget.itemToEdit?.lowStockThreshold ?? 1.0,
        purchaseDate: widget.itemToEdit?.purchaseDate ?? DateTime.now(),
        expiryDate: _expiryDate,
        cost: widget.itemToEdit?.cost ?? 0.0,
        imageUrl: widget.itemToEdit?.imageUrl,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final pantryNotifier = ref.read(pantryProvider);

      if (widget.itemToEdit == null) {
        pantryNotifier.addPantryItem(item);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added to pantry'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        pantryNotifier.updatePantryItem(item);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item updated'),
            backgroundColor: AppColors.primary,
          ),
        );
      }

      Navigator.pop(context);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _expiryDate ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prepare list of units as enum values
    final List<MeasurementUnit> unitOptions = MeasurementUnit.values;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemToEdit == null ? 'Add Item' : 'Edit Item'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              CustomDropdown(
                label: 'Category',
                value: _selectedCategory,
                items: const ['Vegetables', 'Fruits', 'Dairy', 'Grains', 'Meat', 'Other'],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Quantity
              TextFormField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (value) {
                  if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Unit Dropdown with enum values
              CustomDropdown(
                label: 'Unit',
                value: _selectedUnit.name, // Show the enum name as string
                items: unitOptions.map((e) => e.name).toList(),
                onChanged: (value) {
                  setState(() {
                    // Convert string back to enum
                    _selectedUnit = MeasurementUnit.values.firstWhere((e) => e.name == value);
                  });
                },
              ),
              const SizedBox(height: 16),

              // Expiry Date Picker
              Row(
                children: [
                  const Text('Expiry Date:'),
                  const SizedBox(width: 10),
                  Text(
                    _expiryDate == null
                        ? 'Not set'
                        : DateFormat('yyyy-MM-dd').format(_expiryDate!),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Select Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(widget.itemToEdit == null ? 'Add Item' : 'Update Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
