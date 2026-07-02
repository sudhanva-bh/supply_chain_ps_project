import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/gilhari_api_service.dart';

class SuppliersNotifier extends AsyncNotifier<List<Supplier>> {
  @override
  Future<List<Supplier>> build() async {
    final rawData = await gilhariApiService.getEntities('Supplier');
    return rawData.map((e) => Supplier.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> fetchData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  Future<bool> create(Supplier item) async {
    final success = await gilhariApiService.createEntity('Supplier', item.toJson());
    if (success) await fetchData();
    return success;
  }
}

final suppliersProvider = AsyncNotifierProvider<SuppliersNotifier, List<Supplier>>(SuppliersNotifier.new);

class ItemCategoriesNotifier extends AsyncNotifier<List<ItemCategory>> {
  @override
  Future<List<ItemCategory>> build() async {
    final rawData = await gilhariApiService.getEntities('ItemCategory');
    return rawData.map((e) => ItemCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> fetchData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  Future<bool> create(ItemCategory item) async {
    final success = await gilhariApiService.createEntity('ItemCategory', item.toJson());
    if (success) await fetchData();
    return success;
  }
}

final itemCategoriesProvider = AsyncNotifierProvider<ItemCategoriesNotifier, List<ItemCategory>>(ItemCategoriesNotifier.new);

class InventoryItemsNotifier extends AsyncNotifier<List<InventoryItem>> {
  @override
  Future<List<InventoryItem>> build() async {
    final rawData = await gilhariApiService.getEntities('InventoryItem');
    return rawData.map((e) => InventoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> fetchData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  Future<bool> create(InventoryItem item) async {
    final success = await gilhariApiService.createEntity('InventoryItem', item.toJson());
    if (success) await fetchData();
    return success;
  }
}

final inventoryItemsProvider = AsyncNotifierProvider<InventoryItemsNotifier, List<InventoryItem>>(InventoryItemsNotifier.new);

class PurchaseOrdersNotifier extends AsyncNotifier<List<PurchaseOrder>> {
  @override
  Future<List<PurchaseOrder>> build() async {
    final rawData = await gilhariApiService.getEntities('PurchaseOrder');
    return rawData.map((e) => PurchaseOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> fetchData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  Future<bool> create(PurchaseOrder item) async {
    final success = await gilhariApiService.createEntity('PurchaseOrder', item.toJson());
    if (success) await fetchData();
    return success;
  }

  Future<bool> updateItem(PurchaseOrder item) async {
    final success = await gilhariApiService.updateEntity('PurchaseOrder', item.toJson());
    if (success) await fetchData();
    return success;
  }
}

final purchaseOrdersProvider = AsyncNotifierProvider<PurchaseOrdersNotifier, List<PurchaseOrder>>(PurchaseOrdersNotifier.new);

class PurchaseOrderItemsNotifier extends AsyncNotifier<List<PurchaseOrderItem>> {
  @override
  Future<List<PurchaseOrderItem>> build() async {
    final rawData = await gilhariApiService.getEntities('PurchaseOrderItem');
    return rawData.map((e) => PurchaseOrderItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> fetchData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  Future<bool> create(PurchaseOrderItem item) async {
    final success = await gilhariApiService.createEntity('PurchaseOrderItem', item.toJson());
    if (success) await fetchData();
    return success;
  }
}

final purchaseOrderItemsProvider = AsyncNotifierProvider<PurchaseOrderItemsNotifier, List<PurchaseOrderItem>>(PurchaseOrderItemsNotifier.new);

class StockTransactionsNotifier extends AsyncNotifier<List<StockTransaction>> {
  @override
  Future<List<StockTransaction>> build() async {
    final rawData = await gilhariApiService.getEntities('StockTransaction');
    return rawData.map((e) => StockTransaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> fetchData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  Future<bool> create(StockTransaction item) async {
    final success = await gilhariApiService.createEntity('StockTransaction', item.toJson());
    if (success) await fetchData();
    return success;
  }
}

final stockTransactionsProvider = AsyncNotifierProvider<StockTransactionsNotifier, List<StockTransaction>>(StockTransactionsNotifier.new);
