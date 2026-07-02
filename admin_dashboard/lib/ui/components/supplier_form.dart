import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import 'base_modal.dart';

class SupplierForm extends ConsumerStatefulWidget {
  const SupplierForm({super.key});

  @override
  ConsumerState<SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends ConsumerState<SupplierForm> {
  final _formKey = GlobalKey<FormState>();

  final _idCtrl = TextEditingController(text: (DateTime.now().millisecondsSinceEpoch % 100000).toString());
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final item = Supplier(
        supplierID: int.parse(_idCtrl.text),
        companyName: _nameCtrl.text,
        contactEmail: _emailCtrl.text,
        region: _regionCtrl.text,
      );

      final success = await ref.read(suppliersProvider.notifier).create(item);

      if (mounted) {
        if (success) {
          showMonochromaticToast(context, 'Supplier created successfully!');
          Navigator.of(context).pop();
        } else {
          showMonochromaticToast(context, 'Failed to create Supplier.', isError: true);
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
            decoration: const InputDecoration(labelText: 'Supplier ID', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Contact Email', border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _regionCtrl,
            decoration: const InputDecoration(labelText: 'Region', border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryText,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Supplier', style: TextStyle(color: AppTheme.background, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
