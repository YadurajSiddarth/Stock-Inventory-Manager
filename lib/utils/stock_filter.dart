import '../models/stock_item.dart';

const List<String> stockCategories = [
  'Electronics',
  'Stationery',
  'Hardware',
  'Grocery',
];

enum QuantitySort { newest, ascending, descending }

/// Applies the keyword, category and low-stock controls to a list of items
/// retrieved from Firestore, then sorts the result.
///
/// Active controls are combined with AND:
/// * keyword  - case-insensitive partial match on itemName OR sku
/// * category - 'All' disables the filter
/// * lowStockOnly - keeps items where quantity <= reorderLevel
///
/// [QuantitySort.newest] keeps the incoming order (the service already
/// returns newest first). Ties in quantity are broken by SKU so the order is
/// stable.
List<StockItem> filterAndSortStock(
  List<StockItem> items, {
  String keyword = '',
  String category = 'All',
  bool lowStockOnly = false,
  QuantitySort sort = QuantitySort.newest,
}) {
  final query = keyword.trim().toLowerCase();

  final results = items.where((item) {
    final matchesKeyword =
        query.isEmpty ||
        item.itemName.toLowerCase().contains(query) ||
        item.sku.toLowerCase().contains(query);
    final matchesCategory = category == 'All' || item.category == category;
    final matchesLowStock = !lowStockOnly || item.isLowStock;
    return matchesKeyword && matchesCategory && matchesLowStock;
  }).toList();

  switch (sort) {
    case QuantitySort.newest:
      break;
    case QuantitySort.ascending:
      results.sort((a, b) {
        final byQuantity = a.quantity.compareTo(b.quantity);
        return byQuantity != 0 ? byQuantity : a.sku.compareTo(b.sku);
      });
    case QuantitySort.descending:
      results.sort((a, b) {
        final byQuantity = b.quantity.compareTo(a.quantity);
        return byQuantity != 0 ? byQuantity : a.sku.compareTo(b.sku);
      });
  }

  return results;
}
