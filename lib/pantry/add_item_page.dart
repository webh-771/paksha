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
  late MeasurementUnit _selectedUnit; // Enum type
  DateTime? _expiryDate;

  final pantryProvider = ChangeNotifierProvider<PantryProvider>((ref) {
    return PantryProvider(pantryService: PantryService());
  });

  // Dark theme colors
  final Color _backgroundColor = const Color(0xFF1B2B1B);
  final Color _cardColor = const Color(0xFF2A3B2A);
  final Color _textPrimary = Colors.white;
  final Color _textSecondary = const Color(0xFFB0B0B0);
  final Color _inputBackground = const Color(0xFF3A4B3A);
  final Color _primaryGreen = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.itemToEdit?.name ?? '');
    _quantityController = TextEditingController(
      text: widget.itemToEdit?.quantity.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget.itemToEdit?.notes ?? '');
    _selectedCategory = widget.itemToEdit?.category ?? 'Other';
    _selectedUnit = widget.itemToEdit?.unit ?? MeasurementUnit.pcs;
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
        name: _nameController.text.trim(),
        category: _selectedCategory,
        quantity: quantity,
        unit: _selectedUnit,
        lowStockThreshold: widget.itemToEdit?.lowStockThreshold ?? 1.0,
        purchaseDate: widget.itemToEdit?.purchaseDate ?? DateTime.now(),
        expiryDate: _expiryDate,
        cost: widget.itemToEdit?.cost ?? 0.0,
        imageUrl: widget.itemToEdit?.imageUrl,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      final pantryNotifier = ref.read(pantryProvider);

      if (widget.itemToEdit == null) {
        pantryNotifier.addPantryItem(item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item added to pantry'),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        pantryNotifier.updatePantryItem(item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item updated'),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
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
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        // Dark mode styling for date picker
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              surface: Color(0xFF2A3B2A),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _primaryGreen),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MeasurementUnit> unitOptions = MeasurementUnit.values;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.itemToEdit == null ? 'Add Item' : 'Edit Item',
          style: TextStyle(color: _textPrimary),
        ),
        backgroundColor: _cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryGreen),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name
              _buildInputField(
                controller: _nameController,
                labelText: 'Item Name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

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
                dropdownColor: _cardColor,
                textColor: _textPrimary,
                iconEnabledColor: _primaryGreen,
                iconDisabledColor: _textSecondary,
              ),
              const SizedBox(height: 20),

              // Quantity
              _buildInputField(
                controller: _quantityController,
                labelText: 'Quantity',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Unit Dropdown (enum)
              CustomDropdown(
                label: 'Unit',
                value: _selectedUnit.name,
                items: unitOptions.map((e) => e.name).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = MeasurementUnit.values.firstWhere((e) => e.name == value);
                  });
                },
                dropdownColor: _cardColor,
                textColor: _textPrimary,
                iconEnabledColor: _primaryGreen,
                iconDisabledColor: _textSecondary,
              ),
              const SizedBox(height: 20),

              // Expiry Date Picker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _inputBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      'Expiry Date:',
                      style: TextStyle(color: _textPrimary, fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _expiryDate == null
                          ? 'Not set'
                          : DateFormat('yyyy-MM-dd').format(_expiryDate!),
                      style: TextStyle(color: _textSecondary, fontSize: 16),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      style: TextButton.styleFrom(
                        foregroundColor: _primaryGreen,
                      ),
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Notes
              _buildInputField(
                controller: _notesController,
                labelText: 'Notes (optional)',
                maxLines: 4,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    widget.itemToEdit == null ? 'Add Item' : 'Update Item',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: _textPrimary),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: _textSecondary),
        filled: true,
        fillColor: _inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryGreen, width: 2),
        ),
        errorStyle: TextStyle(color: Colors.redAccent.shade100),
      ),
      cursorColor: _primaryGreen,
    );
  }
}
