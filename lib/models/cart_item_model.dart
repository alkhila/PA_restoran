// File: lib/models/cart_item_model.dart

import 'package:hive/hive.dart';

part 'cart_item_model.g.dart'; // Jangan lupa generate file ini

@HiveType(typeId: 1) // typeId harus unik (0 sudah dipakai UserModel)
class CartItemModel extends HiveObject {
  @HiveField(0)
  late String idMeal;

  @HiveField(1)
  late String strMeal;

  @HiveField(2)
  late String strMealThumb;

  @HiveField(3)
  late int quantity;

  // Harga disimulasikan karena API tidak menyediakan harga
  @HiveField(4)
  late double price;

  CartItemModel({
    required this.idMeal,
    required this.strMeal,
    required this.strMealThumb,
    required this.quantity,
    required this.price,
  });
}
