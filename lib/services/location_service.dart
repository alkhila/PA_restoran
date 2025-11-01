// File: lib/services/location_service.dart

import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class LocationService {
  // Nominatim OpenStreetMap Reverse Geocoding API
  static const String _nominatimBaseUrl =
      'https://nominatim.openstreetmap.org/reverse';

  // Header Wajib (sesuai kebijakan Nominatim)
  static const Map<String, String> _headers = {
    // Ganti dengan User-Agent yang unik (wajib)
    'User-Agent': 'FastFoodApp/1.0 (contact@pa-restoran.com)',
  };

  // 1. Dapatkan Koordinat Saat Ini (Termasuk Cek Izin)
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Layanan lokasi tidak diaktifkan.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Izin lokasi ditolak permanen. Mohon aktifkan di pengaturan.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // 2. Konversi Koordinat ke Alamat (Reverse Geocoding)
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl?lat=$latitude&lon=$longitude&format=jsonv2',
      );

      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Nominatim mengembalikan 'display_name' sebagai alamat lengkap
        if (data != null && data['display_name'] != null) {
          return data['display_name'] as String;
        } else {
          return 'Alamat tidak ditemukan.';
        }
      } else {
        debugPrint('Nominatim API error: ${response.statusCode}');
        return 'Gagal memuat alamat (Status: ${response.statusCode})';
      }
    } catch (e) {
      debugPrint('Error Reverse Geocoding: $e');
      return 'Kesalahan koneksi saat melacak lokasi.';
    }
  }
}
