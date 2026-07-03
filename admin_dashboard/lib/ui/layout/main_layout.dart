import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/glass_container.dart';
import '../../theme/app_theme.dart';
import '../views/suppliers_view.dart';
import '../views/item_categories_view.dart';
import '../views/inventory_items_view.dart';
import '../views/purchase_orders_view.dart';
import '../views/purchase_order_items_view.dart';
import '../views/stock_transactions_view.dart';
import '../views/agent_chat_view.dart';

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int i) => state = i;
}

final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(
  NavigationIndexNotifier.new,
);

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final List<Widget> views = [
      const SuppliersView(),
      const ItemCategoriesView(),
      const InventoryItemsView(),
      const PurchaseOrdersView(),
      const PurchaseOrderItemsView(),
      const StockTransactionsView(),
      const AgentChatView(),
    ];

    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Suppliers', 'icon': Icons.business},
      {'title': 'Item Categories', 'icon': Icons.category},
      {'title': 'Inventory Items', 'icon': Icons.inventory},
      {'title': 'Purchase Orders', 'icon': Icons.shopping_cart},
      {'title': 'Purchase Order Items', 'icon': Icons.list_alt},
      {'title': 'Stock Transactions', 'icon': Icons.swap_horiz},
      {'title': 'AI Analytics', 'icon': Icons.auto_awesome},
    ];

    Widget buildSidebar() {
      return GlassContainer(
        borderRadius: BorderRadius.zero,
        border: Border(
          right: BorderSide(
            color: AppTheme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: SizedBox(
          width: 250,
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text(
                'GILHARI ADMIN',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final isSelected = currentIndex == index;
                    return ListTile(
                      leading: Icon(
                        menuItems[index]['icon'],
                        color: isSelected
                            ? AppTheme.primaryText
                            : AppTheme.secondaryText,
                      ),
                      title: Text(
                        menuItems[index]['title'],
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryText
                              : AppTheme.secondaryText,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: AppTheme.surfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                      onTap: () {
                        ref
                            .read(navigationIndexProvider.notifier)
                            .setIndex(index);
                        if (!isDesktop) {
                          Navigator.pop(context); // Close drawer on mobile
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(menuItems[currentIndex]['title']),
        flexibleSpace: const GlassContainer(
          borderRadius: BorderRadius.zero,
          child: SizedBox.expand(),
        ),
      ),
      drawer: isDesktop ? null : Drawer(child: buildSidebar()),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop) buildSidebar(),
          Expanded(
            child: IndexedStack(index: currentIndex, children: views),
          ),
        ],
      ),
    );
  }
}
