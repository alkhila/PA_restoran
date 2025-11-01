// File: lib/services/currency_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl =
      'https://api.exchangerate-api.com/v4/latest/IDR';

  // --- PEMETAAN NEGARA KE MATA UANG ---
  final Map<String, String> countryToCurrency = {
    'ID': 'IDR',
    'US': 'USD',
    'EU': 'EUR', // Kode ISO untuk Eurozone
    'GB': 'GBP', // Poundsterling
    'JP': 'JPY',
    // ... bisa ditambahkan negara lain
  };

  // Daftar mata uang yang didukung (Wajib ada IDR, USD, EUR, JPY)
  final List<String> supportedCurrencies = ['IDR', 'USD', 'EUR', 'JPY'];

  // FUNGSI UTAMA UNTUK MENDAPATKAN RATE
  Future<Map<String, double>> getExchangeRates() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        Map<String, double> filteredRates = {};
        for (var code in supportedCurrencies) {
          if (rates.containsKey(code)) {
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

  // FUNGSI BARU: Mendapatkan Currency Default dari Country Code
  String getDefaultCurrency(String countryCode) {
    // Menggunakan pemetaan; jika tidak ditemukan, default ke IDR
    return countryToCurrency[countryCode] ?? 'IDR';
  }
}
