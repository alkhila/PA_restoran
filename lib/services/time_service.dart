// File: lib/services/time_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TimeService {
  final String _baseUrl = 'http://worldtimeapi.org/api/timezone/';

  // Daftar zona waktu yang diwajibkan: WIB, WITA, WIT, dan London
  final Map<String, String> timeZones = {
    'WIB (Jakarta)': 'Asia/Jakarta',
    'WITA (Makassar)': 'Asia/Makassar',
    'WIT (Jayapura)': 'Asia/Jayapura',
    'London (UTC)': 'Europe/London',
  };

  Future<String> fetchTime(String timezoneEndpoint) async {
    try {
      final response = await http.get(Uri.parse(_baseUrl + timezoneEndpoint));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Ambil waktu mentah dan konversi ke format yang lebih rapi
        final dateTime = DateTime.parse(data['datetime']);
        final formatter = DateFormat('dd MMM yyyy, HH:mm:ss');

        return formatter.format(dateTime);
      } else {
        return 'Gagal memuat waktu: ${response.statusCode}';
      }
    } catch (e) {
      return 'Kesalahan koneksi: $e';
    }
  }
}
