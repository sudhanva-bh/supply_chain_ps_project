import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import 'base_modal.dart';
import 'foreign_key_autocomplete.dart';

class InventoryItemForm extends ConsumerStatefulWidget {
  const InventoryItemForm({super.key});

  @override
  ConsumerState<InventoryItemForm> createState() => _InventoryItemFormState();
}

class _InventoryItemFormState extends ConsumerState<InventoryItemForm> {
  final _formKey = GlobalKey<FormState>();

  final _idCtrl = TextEditingController(text: (DateTime.now().millisecondsSinceEpoch % 100000).toString());
  final _nameCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final item = InventoryItem(
        itemID: int.parse(_idCtrl.text),
        name: _nameCtrl.text,
        stockQuantity: int.parse(_stockCtrl.text),
        unitPrice: double.parse(_priceCtrl.text),
        categoryID: int.parse(_categoryCtrl.text),
        supplierID: int.parse(_supplierCtrl.text),
      );

      final success = await ref.read(inventoryItemsProvider.notifier).create(item);

      if (mounted) {
        if (success) {
          showMonochromaticToast(context, 'Inventory Item created successfully!');
          Navigator.of(context).pop();
        } else {
          showMonochromaticToast(context, 'Failed to create Inventory Item.', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(itemCategoriesProvider).value ?? [];
    final suppliers = ref.watch(suppliersProvider).value ?? [];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _idCtrl,
            decoration: const InputDecoration(labelText: 'Item ID', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _stockCtrl,
            decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceCtrl,
            decoration: const InputDecoration(labelText: 'Unit Price', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          ForeignKeyAutocomplete<ItemCategory>(
            items: categories,
            displayStringForOption: (c) => '${c.categoryID} - ${c.categoryName}',
            idForOption: (c) => c.categoryID.toString(),
            controller: _categoryCtrl,
            labelText: 'Category',
          ),
          const SizedBox(height: 16),
          ForeignKeyAutocomplete<Supplier>(
            items: suppliers,
            displayStringForOption: (s) => '${s.supplierID} - ${s.companyName}',
            idForOption: (s) => s.supplierID.toString(),
            controller: _supplierCtrl,
            labelText: 'Supplier',
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryText,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Item', style: TextStyle(color: AppTheme.background, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
