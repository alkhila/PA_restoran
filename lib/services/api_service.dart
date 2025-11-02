// File: lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:math'; // Wajib untuk harga acak

class ApiService {
  final String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  Future<List<dynamic>> fetchMenu() async {
    List<dynamic> allMeals = [];
    final Random random = Random(); // Instansiasi untuk harga acak

    // Kategori Makanan Berat/Junk Food: Chicken dan Beef
    List<String> foodCategories = ['Chicken', 'Beef'];

    try {
      for (var category in foodCategories) {
        final response = await http.get(
          Uri.parse('$_baseUrl/filter.php?c=$category'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data != null && data['meals'] is List) {
            // --- PENAMBAHAN HARGA STATIS UNTUK MAKANAN ---
            List<Map<String, dynamic>> categorizedMeals =
                (data['meals'] as List)
                    .map(
                      (meal) => Map<String, dynamic>.from(meal)
                        ..['type'] = 'Makanan'
                        // Harga acak (simulasi) antara 30.000 dan 80.000
                        ..['price'] = (random.nextInt(50) + 30) * 1000.0,
                    )
                    .toList();

            allMeals.addAll(categorizedMeals);
          }
        } else {
          debugPrint('Gagal memuat kategori $category: ${response.statusCode}');
        }
      }

      // --- 2. Tambahkan Minuman (Statis) dan Harga ---
      allMeals.addAll([
        {
          "idMeal": "99901",
          "strMeal": "Coca-Cola Dingin",
          "strMealThumb": "assets/images/cola.jpg",
          "type": "Minuman",
          "price": 15000.0, // Harga Statis Minuman
        },
        {
          "idMeal": "99902",
          "strMeal": "Es Teh Manis Jumbo",
          "strMealThumb": "assets/images/es_teh.jpeg",
          "type": "Minuman",
          "price": 12000.0, // Harga Statis Minuman
        },
        {
          "idMeal": "99903",
          "strMeal": "Air Mineral Sehat",
          "strMealThumb": "assets/images/air_putih.png",
          "type": "Minuman",
          "price": 6000.0, // Harga Statis Minuman
        },
      ]);

      return allMeals;
    } catch (e) {
      debugPrint('Terjadi kesalahan koneksi saat memuat menu: $e');
      throw Exception('Terjadi kesalahan koneksi saat memuat menu: $e');
    }
  }
}
