import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../components/async_data_grid.dart';

class InventoryItemsView extends ConsumerWidget {
  const InventoryItemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryItemsProvider);

    return AsyncDataGrid<InventoryItem>(
      asyncValue: state,
      onRefresh: () => ref.read(inventoryItemsProvider.notifier).fetchData(),
      onAdd: () {
        // Show Add Modal
      },
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Stock')),
        DataColumn(label: Text('Price')),
        DataColumn(label: Text('Category ID')),
        DataColumn(label: Text('Supplier ID')),
        DataColumn(label: Text('Actions')),
      ],
      buildRows: (data) => data.map((item) {
        return DataRow(cells: [
          DataCell(Text(item.itemID.toString())),
          DataCell(Text(item.name)),
          DataCell(Text(item.stockQuantity.toString())),
          DataCell(Text('\$${item.unitPrice.toStringAsFixed(2)}')),
          DataCell(Text(item.categoryID.toString())),
          DataCell(Text(item.supplierID.toString())),
          DataCell(Row(
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () {}),
              IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: () {}),
            ],
          )),
        ]);
      }).toList(),
    );
  }
}
