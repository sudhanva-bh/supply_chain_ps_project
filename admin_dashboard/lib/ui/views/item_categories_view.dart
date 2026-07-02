import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../components/async_data_grid.dart';
import '../components/base_modal.dart';
import '../components/item_category_form.dart';

class ItemCategoriesView extends ConsumerWidget {
  const ItemCategoriesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itemCategoriesProvider);

    return AsyncDataGrid<ItemCategory>(
      asyncValue: state,
      onRefresh: () => ref.read(itemCategoriesProvider.notifier).fetchData(),
      onAdd: () {
        showGlassModal(
          context,
          title: 'Create Item Category',
          content: const ItemCategoryForm(),
        );
      },
      searchFilter: (item, query) {
        final lowerQuery = query.toLowerCase();
        return item.categoryID.toString().contains(lowerQuery) ||
            item.categoryName.toLowerCase().contains(lowerQuery) ||
            item.description.toLowerCase().contains(lowerQuery);
      },
      sortValueMapper: (item, columnIndex) {
        switch (columnIndex) {
          case 0: return item.categoryID;
          case 1: return item.categoryName;
          case 2: return item.description;
          default: return '';
        }
      },
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Category Name')),
        DataColumn(label: Text('Description')),
        DataColumn(label: Text('Actions')),
      ],
      buildRows: (data) => data.map((item) {
        return DataRow(cells: [
          DataCell(Text(item.categoryID.toString())),
          DataCell(Text(item.categoryName)),
          DataCell(Text(item.description)),
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
