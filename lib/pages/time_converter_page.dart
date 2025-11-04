import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);

class TimeConverterPage extends StatefulWidget {
  const TimeConverterPage({super.key});

  @override
  State<TimeConverterPage> createState() => _TimeConverterPageState();
}

class _TimeConverterPageState extends State<TimeConverterPage> {
  DateTime _currentTime = DateTime.now();

  Timer? _timer;

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
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  String _formatTime(DateTime wibTime, int targetOffset) {
    const int wibOffsetHours = 7;
    final utcTime = wibTime.subtract(const Duration(hours: wibOffsetHours));
    final targetTime = utcTime.add(Duration(hours: targetOffset));
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
