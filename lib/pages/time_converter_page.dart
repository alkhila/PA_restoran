// File: lib/pages/time_converter_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Wajib untuk Timer

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);

class TimeConverterPage extends StatefulWidget {
  const TimeConverterPage({super.key});

  @override
  State<TimeConverterPage> createState() => _TimeConverterPageState();
}

class _TimeConverterPageState extends State<TimeConverterPage> {
  // Waktu dasar diinisialisasi ke waktu perangkat (diasumsikan sudah WIB)
  DateTime _currentTime = DateTime.now();

  // Timer untuk pembaruan waktu berkala
  Timer? _timer;

  // Zona Waktu yang didukung (Offset dihitung relatif terhadap UTC)
  final List<Map<String, dynamic>> timeZones = [
    {'name': 'WIB (Jakarta)', 'offset': 7},
    {'name': 'WITA (Makassar)', 'offset': 8},
    {'name': 'WIT (Jayapura)', 'offset': 9},
    {'name': 'London (GMT)', 'offset': 0},
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Pastikan timer dibatalkan saat widget dihancurkan
    super.dispose();
  }

  // --- PERBAIKAN: Menggunakan Timer yang lebih andal ---
  void _startTimer() {
    // Memulai pembaruan waktu setiap 1 detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Mengambil waktu WIB saat ini
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  String _formatTime(DateTime wibTime, int targetOffset) {
    // Offset WIB adalah 7 jam dari UTC
    const int wibOffsetHours = 7;

    // 1. Konversi WIB (waktu lokal perangkat) ke UTC
    final utcTime = wibTime.subtract(const Duration(hours: wibOffsetHours));

    // 2. Konversi UTC ke Waktu Target
    final targetTime = utcTime.add(Duration(hours: targetOffset));

    // 3. Format tampilan waktu
    return DateFormat('HH:mm:ss').format(targetTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konversi Waktu & Zona'),
        backgroundColor: brownColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Waktu Lokal (WIB) Saat Ini:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: brownColor,
              ),
            ),
            Text(
              // Menampilkan tanggal dan waktu WIB dari perangkat
              DateFormat('dd MMMM yyyy, HH:mm:ss').format(_currentTime),
              style: const TextStyle(
                fontSize: 24,
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 30),

            Text(
              'Perbandingan Zona Waktu:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: brownColor,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: timeZones.length,
                itemBuilder: (context, index) {
                  final zone = timeZones[index];
                  // Panggil fungsi konversi dengan waktu WIB saat ini
                  final displayTime = _formatTime(
                    _currentTime,
                    zone['offset'] as int,
                  );

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        zone['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: brownColor,
                        ),
                      ),
                      subtitle: Text(
                        'UTC ${zone['offset'] > 0 ? '+' : ''}${zone['offset']}',
                      ),
                      trailing: Text(
                        displayTime,
                        style: const TextStyle(
                          fontSize: 24,
                          color: accentColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
