// File: lib/pages/time_converter_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);

class TimeConverterPage extends StatefulWidget {
  const TimeConverterPage({super.key});

  @override
  State<TimeConverterPage> createState() => _TimeConverterPageState();
}

class _TimeConverterPageState extends State<TimeConverterPage> {
  // Zona Waktu yang didukung (WIB, WITA, WIT, London/GMT)
  final List<Map<String, dynamic>> timeZones = [
    {'name': 'WIB (Jakarta)', 'offset': 7},
    {'name': 'WITA (Makassar)', 'offset': 8},
    {'name': 'WIT (Jayapura)', 'offset': 9},
    {'name': 'London (GMT)', 'offset': 0},
  ];

  DateTime _currentTime = DateTime.now().toUtc().add(
    const Duration(hours: 7),
  ); // Default WIB

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    // Memperbarui waktu setiap detik untuk efek jam
    setState(() {
      _currentTime = DateTime.now().toUtc().add(const Duration(hours: 7));
    });
    // Gunakan Future.delayed untuk memanggil kembali fungsi (membuat loop)
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  String _formatTime(DateTime time, int targetOffset) {
    // Hitung offset dari WIB (UTC+7) ke target
    const int wibOffset = 7;
    final int diff = targetOffset - wibOffset;

    final targetTime = time.add(Duration(hours: diff));

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
