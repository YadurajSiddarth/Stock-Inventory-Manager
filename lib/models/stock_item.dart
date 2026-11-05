import 'package:cloud_firestore/cloud_firestore.dart';

class StockItem {
  const StockItem({
    required this.id,
    required this.sku,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.reorderLevel,
    this.createdAt,
  });

  final String id;
  final String sku;
  final String itemName;
  final String category;
  final int quantity;
  final double unitPrice;
  final int reorderLevel;

  /// Null while a freshly written server timestamp is still pending.
  final DateTime? createdAt;

  /// Low stock rule from the brief: quantity <= reorderLevel.
  bool get isLowStock => quantity <= reorderLevel;

  factory StockItem.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAtValue = data['createdAt'];

    return StockItem(
      id: document.id,
      sku: (data['sku'] ?? '').toString(),
      itemName: (data['itemName'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      quantity: _asInt(data['quantity']),
      unitPrice: _asDouble(data['unitPrice']),
      reorderLevel: _asInt(data['reorderLevel']),
      createdAt: createdAtValue is Timestamp ? createdAtValue.toDate() : null,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
