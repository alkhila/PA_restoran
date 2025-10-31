// File: lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Wajib untuk debugPrint

class ApiService {
  final String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  Future<List<dynamic>> fetchMenu() async {
    List<dynamic> allMeals = [];

    // Kategori Makanan Berat/Junk Food: Chicken dan Beef
    List<String> foodCategories = ['Chicken', 'Beef'];

    try {
      // --- 1. Ambil Makanan Berat/Junk Food (dan beri tag "Makanan") ---
      for (var category in foodCategories) {
        final response = await http.get(
          Uri.parse('$_baseUrl/filter.php?c=$category'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data != null && data['meals'] is List) {
            // Memberi tag 'type': 'Makanan' pada setiap item
            List<Map<String, dynamic>> categorizedMeals =
                (data['meals'] as List)
                    .map(
                      (meal) =>
                          Map<String, dynamic>.from(meal)..['type'] = 'Makanan',
                    )
                    .toList();

            allMeals.addAll(categorizedMeals);
          }
        } else {
          debugPrint('Gagal memuat kategori $category: ${response.statusCode}');
        }
      }

      // --- 2. Tambahkan Minuman (Statis dan beri tag "Minuman") ---
      allMeals.addAll([
        {
          "idMeal": "99901",
          "strMeal": "Coca-Cola Dingin",
          "strMealThumb":
              "assets/images/cola.jpg", // Ganti dengan nama file Anda
          "type": "Minuman",
        },
        {
          "idMeal": "99902",
          "strMeal": "Es Teh Manis Jumbo",
          "strMealThumb":
              "assets/images/teh.jpg", // Ganti dengan nama file Anda
          "type": "Minuman",
        },
        {
          "idMeal": "99903",
          "strMeal": "Air Mineral Sehat",
          "strMealThumb":
              "assets/images/air_putih.png", // Ganti dengan nama file Anda
          "type": "Minuman",
        },
      ]);

      return allMeals;
    } catch (e) {
      debugPrint('Terjadi kesalahan koneksi saat memuat menu: $e');
      throw Exception('Terjadi kesalahan koneksi saat memuat menu: $e');
    }
  }
}
