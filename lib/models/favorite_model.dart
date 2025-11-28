// lib/models/favorite_model.dart

import 'package:hive/hive.dart';

part 'favorite_model.g.dart'; // PASTI ada baris ini!

@HiveType(typeId: 2)
class FavoriteModel extends HiveObject {
  @HiveField(0)
  late String idMeal;

  @HiveField(1)
  late String strMeal;

  @HiveField(2)
  late String strMealThumb;

  @HiveField(3)
  late double price;

  @HiveField(4)
  late String userEmail;

  FavoriteModel({
    required this.idMeal,
    required this.strMeal,
    required this.strMealThumb,
    required this.price,
    required this.userEmail,
  });
}
