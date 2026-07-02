import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import 'base_modal.dart';

class ItemCategoryForm extends ConsumerStatefulWidget {
  const ItemCategoryForm({super.key});

  @override
  ConsumerState<ItemCategoryForm> createState() => _ItemCategoryFormState();
}

class _ItemCategoryFormState extends ConsumerState<ItemCategoryForm> {
  final _formKey = GlobalKey<FormState>();

  final _idCtrl = TextEditingController(text: (DateTime.now().millisecondsSinceEpoch % 100000).toString());
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final item = ItemCategory(
        categoryID: int.parse(_idCtrl.text),
        categoryName: _nameCtrl.text,
        description: _descCtrl.text,
      );

      final success = await ref.read(itemCategoriesProvider.notifier).create(item);

      if (mounted) {
        if (success) {
          showMonochromaticToast(context, 'Category created successfully!');
          Navigator.of(context).pop();
        } else {
          showMonochromaticToast(context, 'Failed to create Category.', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _idCtrl,
            decoration: const InputDecoration(labelText: 'Category ID', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryText,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Category', style: TextStyle(color: AppTheme.background, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
