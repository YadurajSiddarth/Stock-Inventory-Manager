import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/stock_item.dart';

class StockService {
  StockService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _stockCollection =>
      _firestore.collection('stockItems');

  /// Adds a new stock record. The returned Future completes when Firestore
  /// acknowledges the write; the UI should show success only after it returns.
  Future<void> addStockItem({
    required String sku,
    required String itemName,
    required String category,
    required int quantity,
    required double unitPrice,
    required int reorderLevel,
  }) async {
    await _stockCollection.add({
      'sku': sku,
      'itemName': itemName,
      'category': category,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'reorderLevel': reorderLevel,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Streams saved Firestore records so the inventory refreshes after writes
  /// and when the screen is reopened or the app is reloaded.
  Stream<List<StockItem>> watchStockItems() {
    return _stockCollection.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((document) => StockItem.fromFirestore(document))
          .toList();

      // Keep the newest records at the top without requiring a Firestore index.
      items.sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) return a.sku.compareTo(b.sku);
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      return items;
    });
  }
}
