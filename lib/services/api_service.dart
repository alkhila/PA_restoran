import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL TheMealDB dan test key '1'
  final String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  Future<List<dynamic>> fetchMenu() async {
    try {
      // Mengambil menu dari kategori "Dessert" sebagai contoh menu fast food/manisan
      // Anda bisa ganti 'Dessert' dengan 'Chicken', 'Seafood', atau 'Beef'
      final response = await http.get(
        Uri.parse('$_baseUrl/filter.php?c=Dessert'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // TheMealDB mengembalikan data di bawah kunci 'meals'
        if (data != null && data['meals'] is List) {
          return data['meals'];
        } else {
          // Jika 'meals' kosong, kembalikan list kosong
          return [];
        }
      } else {
        throw Exception(
          'Gagal mengambil menu. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi: $e');
    }
  }
}
