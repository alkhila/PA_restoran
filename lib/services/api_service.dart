import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:math';

class ApiService {
  final String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  // Daftar kategori statis untuk minuman
  final List<Map<String, dynamic>> _drinkCategory = [
    {'strCategory': 'Minuman', 'type': 'Minuman'},
  ];

  // Data minuman statis
  final List<Map<String, dynamic>> _staticDrinks = [
    {
      "idMeal": "99901",
      "strMeal": "Coca-Cola Dingin",
      "strMealThumb": "assets/images/cola.jpg",
      "type": "Minuman",
      "price": 15000.0,
    },
    {
      "idMeal": "99902",
      "strMeal": "Es Teh Manis Jumbo",
      "strMealThumb": "assets/images/es_teh.jpeg",
      "type": "Minuman",
      "price": 12000.0,
    },
    {
      "idMeal": "99903",
      "strMeal": "Air Mineral Sehat",
      "strMealThumb": "assets/images/air_putih.png",
      "type": "Minuman",
      "price": 6000.0,
    },
  ];

  // MODIFIKASI BARU: Mengambil daftar kategori dari TheMealDB
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/list.php?c=list'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['meals'] is List) {
          List<Map<String, dynamic>> apiCategories = (data['meals'] as List)
              .map(
                (category) =>
                    Map<String, dynamic>.from(category)..['type'] = 'Makanan',
              )
              .toList();

          // Tambahkan kategori minuman statis di awal
          apiCategories.insert(0, _drinkCategory[0]);

          return apiCategories;
        }
      }
      // Fallback jika API gagal
      return [
        ..._drinkCategory,
        {'strCategory': 'Chicken', 'type': 'Makanan'},
        {'strCategory': 'Beef', 'type': 'Makanan'},
      ];
    } catch (e) {
      debugPrint('Terjadi kesalahan koneksi saat memuat kategori: $e');
      // Fallback jika terjadi error
      return [
        ..._drinkCategory,
        {'strCategory': 'Chicken', 'type': 'Makanan'},
        {'strCategory': 'Beef', 'type': 'Makanan'},
      ];
    }
  }

  // MODIFIKASI: Mengambil detail resep (termasuk ingredients) berdasarkan ID
  Future<List<String>> fetchMealDetails(String idMeal) async {
    // Cek jika menu adalah minuman statis (tidak perlu panggil API)
    if (_staticDrinks.any((meal) => meal['idMeal'] == idMeal)) {
      return ['Air Murni', 'Es Batu (opsional)', 'Kemasasn Ramah Lingkungan'];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/lookup.php?i=$idMeal'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['meals'] is List && data['meals'].isNotEmpty) {
          final meal = data['meals'][0];
          List<String> ingredients = [];

          // API TheMealDB menggunakan 20 pasang strIngredient dan strMeasure
          for (int i = 1; i <= 20; i++) {
            final ingredient = meal['strIngredient$i'];
            final measure = meal['strMeasure$i'];

            if (ingredient != null &&
                ingredient.isNotEmpty &&
                ingredient.trim().toLowerCase() != 'null') {
              // Format ingredient: "Measure Ingredient"
              ingredients.add('$ingredient');
            }
          }
          return ingredients;
        }
      }
      return ['Gagal memuat bahan-bahan.'];
    } catch (e) {
      debugPrint('Terjadi kesalahan koneksi saat memuat detail resep: $e');
      return ['Gagal memuat bahan-bahan.'];
    }
  }

  @override
  Future<List<dynamic>> fetchMenu() async {
    List<dynamic> allMeals = [];
    final Random random = Random();

    // Mengambil daftar kategori dinamis (kecuali Minuman yang sudah ada di _staticDrinks)
    final categories = await fetchCategories();
    final foodCategories = categories
        .where((cat) => cat['type'] == 'Makanan')
        .map((cat) => cat['strCategory'] as String)
        .toList();

    try {
      for (var category in foodCategories) {
        final response = await http.get(
          Uri.parse('$_baseUrl/filter.php?c=$category'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data != null && data['meals'] is List) {
            List<Map<String, dynamic>> categorizedMeals =
                (data['meals'] as List)
                    .map(
                      (meal) => Map<String, dynamic>.from(meal)
                        ..['type'] =
                            category // Menggunakan kategori API
                        ..['price'] = (random.nextInt(50) + 30) * 1000.0,
                    )
                    .toList();

            // Batasi jumlah menu per kategori agar tidak terlalu banyak
            allMeals.addAll(categorizedMeals.take(4));
          }
        } else {
          debugPrint('Gagal memuat kategori $category: ${response.statusCode}');
        }
      }

      // Tambahkan menu minuman statis
      allMeals.addAll(_staticDrinks);

      return allMeals;
    } catch (e) {
      debugPrint('Terjadi kesalahan koneksi saat memuat menu: $e');
      // Jika error, kembalikan hanya menu minuman statis
      return _staticDrinks;
    }
  }
}
