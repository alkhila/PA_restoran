import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl =
      'https://free-food-menus-api-production.up.railway.app';

  Future<List<dynamic>> fetchMenu() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/menu'));

      if (response.statusCode == 200) {
        // API mengembalikan List<Map<String, dynamic>>
        return json.decode(response.body);
      } else {
        // Jika server mengembalikan error, lempar exception
        throw Exception(
          'Gagal mengambil menu. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Menangani error koneksi atau parsing
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
