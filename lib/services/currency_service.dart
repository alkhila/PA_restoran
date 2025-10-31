// File: lib/services/currency_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

// Data dari ExchangeRate-API (menggunakan base currency USD untuk Free Plan)
class CurrencyService {
  // Anda bisa ganti dengan API Key jika menggunakan paket berbayar,
  // tetapi untuk contoh, kita gunakan endpoint gratis yang diperbolehkan
  static const String _baseUrl =
      'https://api.exchangerate-api.com/v4/latest/IDR';

  // Daftar mata uang wajib dan umum
  final List<String> supportedCurrencies = [
    'IDR', // Rupiah Indonesia
    'USD', // Dollar Amerika
    'EUR', // Euro
    'JPY', // Yen Jepang
  ];

  Future<Map<String, double>> getExchangeRates() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        // Filter rates yang hanya didukung
        Map<String, double> filteredRates = {};
        for (var code in supportedCurrencies) {
          if (rates.containsKey(code)) {
            // Karena API ini berbasis IDR, 1 IDR = X (Mata uang lain)
            filteredRates[code] = rates[code].toDouble();
          }
        }
        return filteredRates;
      } else {
        throw Exception('Gagal memuat rate mata uang: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kesalahan koneksi saat memuat rate: $e');
    }
  }
}
