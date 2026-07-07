import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../components/async_data_grid.dart';
import '../components/base_modal.dart';
import '../components/supplier_form.dart';

class SuppliersView extends ConsumerWidget {
  const SuppliersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(suppliersProvider);

    return AsyncDataGrid<Supplier>(
      asyncValue: state,
      onRefresh: () => ref.read(suppliersProvider.notifier).fetchData(),
      onAdd: () {
        showGlassModal(
          context,
          title: 'Create Supplier',
          content: const SupplierForm(),
        );
      },
      searchFilter: (item, query) {
        final lowerQuery = query.toLowerCase();
        return item.supplierID.toString().contains(lowerQuery) ||
            item.companyName.toLowerCase().contains(lowerQuery) ||
            item.contactEmail.toLowerCase().contains(lowerQuery) ||
            item.region.toLowerCase().contains(lowerQuery);
      },
      sortValueMapper: (item, columnIndex) {
        switch (columnIndex) {
          case 0:
            return item.supplierID;
          case 1:
            return item.companyName;
          case 2:
            return item.contactEmail;
          case 3:
            return item.region;
          default:
            return '';
        }
      },
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Company Name')),
        DataColumn(label: Text('Contact Email')),
        DataColumn(label: Text('Region')),
        DataColumn(label: Text('Actions')),
      ],
      buildRows: (data) => data.map((item) {
        return DataRow(
          cells: [
            DataCell(Text(item.supplierID.toString())),
            DataCell(Text(item.companyName)),
            DataCell(Text(item.contactEmail)),
            DataCell(Text(item.region)),
            DataCell(
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
