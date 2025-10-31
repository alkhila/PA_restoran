import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Wajib: Hive Flutter
import 'package:path_provider/path_provider.dart'; // Wajib: Path Provider
import 'models/user_model.dart'; // Wajib: Import model Hive
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';

// Definisi warna yang konsisten
const Color accentColor = Color(0xFFFFB300);

// Ganti main() menjadi async untuk inisialisasi Hive
void main() async {
  // Pastikan binding Flutter sudah diinisialisasi
  WidgetsFlutterBinding.ensureInitialized();

  // --- INISIALISASI HIVE ---
  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());

  // 3. Buka Box yang menyimpan data pengguna
  await Hive.openBox<UserModel>('userBox');

  // --- HAPUS BARIS INI JIKA ANDA SUDAH BERHASIL LOGIN/REGISTER SEKALI ---
  await Hive.box<UserModel>('userBox').clear(); // HAPUS DATA LAMA/RUSAK
  // ----------------------------------------------------------------------

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastFood App TA',
      debugShowCheckedModeBanner: false, // Opsional: menghilangkan banner debug
      theme: ThemeData(primarySwatch: Colors.brown, fontFamily: 'Roboto'),

      // MENGATUR HOME PROPERTY UNTUK CEK SESI (SPLASH SCREEN LOGIC)
      home: FutureBuilder<bool>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Tampilkan CircularProgressIndicator saat menunggu SharedPreferences
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }
          // Logika Penentu Rute Awal:
          // Jika sudah login (true), arahkan ke HomePage. Jika belum, ke LoginPage.
          return snapshot.data == true ? const HomePage() : const LoginPage();
        },
      ),

      // DEFINISI ROUTE BERNAMA
      routes: {
        // Rute yang dapat dipanggil dengan Navigator.pushNamed(context, '/register')
        '/register': (context) => const RegisterPage(),
        // Rute Home, untuk navigasi setelah login sukses
        '/home': (context) => const HomePage(),
      },
    );
  }

  // Fungsi Session Check: Memeriksa status login dari SharedPreferences
  Future<bool> _checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ??
        false; // Default ke false jika belum ada
  }
}
