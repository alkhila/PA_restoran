// File: lib/models/purchase_history_model.dart

import 'package:hive/hive.dart';
import 'cart_item_model.dart'; // Impor CartItemModel untuk menyimpan detil item

part 'purchase_history_model.g.dart';

@HiveType(typeId: 2) // typeId harus unik (0=User, 1=Cart)
class PurchaseHistoryModel extends HiveObject {
  @HiveField(0)
  late double finalPrice;

  @HiveField(1)
  late String currency; // Mata uang yang digunakan (e.g., IDR, USD)

  @HiveField(2)
  late DateTime purchaseTime;

  @HiveField(3)
  late List<CartItemModel> items; // Detil barang yang dibeli

  PurchaseHistoryModel({
    required this.finalPrice,
    required this.currency,
    required this.purchaseTime,
    required this.items,
  });
}
