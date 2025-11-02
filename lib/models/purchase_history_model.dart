// File: lib/models/purchase_history_model.dart (MODIFIED FOR USER-SPECIFIC HISTORY)

import 'package:hive/hive.dart';
import 'cart_item_model.dart';

part 'purchase_history_model.g.dart';

// Ganti TypeId (asumsi 4 adalah TypeId baru untuk model ini)
@HiveType(typeId: 4)
class PurchaseHistoryModel extends HiveObject {
  @HiveField(0)
  late double finalPrice;

  @HiveField(1)
  late String currency;

  @HiveField(2)
  late DateTime purchaseTime;

  @HiveField(3)
  late List<CartItemModel> items;

  @HiveField(4) // FIELD BARU UNTUK KEPEMILIKAN
  late String userEmail;

  PurchaseHistoryModel({
    required this.finalPrice,
    required this.currency,
    required this.purchaseTime,
    required this.items,
    required this.userEmail, // Wajib diisi
  });
}
