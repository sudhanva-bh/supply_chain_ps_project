import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../components/async_data_grid.dart';
import '../components/base_modal.dart';
import '../components/stock_transaction_form.dart';

class StockTransactionsView extends ConsumerWidget {
  const StockTransactionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stockTransactionsProvider);

    return AsyncDataGrid<StockTransaction>(
      asyncValue: state,
      onRefresh: () => ref.read(stockTransactionsProvider.notifier).fetchData(),
      onAdd: () {
        showGlassModal(
          context,
          title: 'Create Transaction',
          content: const StockTransactionForm(),
        );
      },
      searchFilter: (item, query) {
        final lowerQuery = query.toLowerCase();
        return item.transactionID.toString().contains(lowerQuery) ||
            item.itemID.toString().contains(lowerQuery) ||
            item.transactionType.toLowerCase().contains(lowerQuery) ||
            item.timestamp.toLowerCase().contains(lowerQuery);
      },
      sortValueMapper: (item, columnIndex) {
        switch (columnIndex) {
          case 0: return item.transactionID;
          case 1: return item.itemID;
          case 2: return item.quantityChanged;
          case 3: return item.transactionType;
          case 4: return item.timestamp;
          default: return '';
        }
      },
      columns: const [
        DataColumn(label: Text('TX ID')),
        DataColumn(label: Text('Item ID')),
        DataColumn(label: Text('Quantity Changed')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Timestamp')),
        DataColumn(label: Text('Actions')),
      ],
      buildRows: (data) => data.map((item) {
        return DataRow(cells: [
          DataCell(Text(item.transactionID.toString())),
          DataCell(Text(item.itemID.toString())),
          DataCell(Text(item.quantityChanged.toString())),
          DataCell(Text(item.transactionType)),
          DataCell(Text(item.timestamp)),
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
