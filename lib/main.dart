import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Wajib: Hive Flutter
import 'package:path_provider/path_provider.dart'; // Wajib: Path Provider
import 'models/user_model.dart'; // Wajib: Import model Hive
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'models/cart_item_model.dart';
import 'models/purchase_history_model.dart';
import 'pages/time_converter_page.dart';

// Definisi warna yang konsisten
const Color accentColor = Color(0xFFFFB300);

// Ganti main() menjadi async untuk inisialisasi Hive
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Daftarkan Adapter
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(CartItemModelAdapter());
  Hive.registerAdapter(PurchaseHistoryModelAdapter()); // BARU

  // Buka Box
  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<CartItemModel>('cartBox');
  await Hive.openBox<PurchaseHistoryModel>('historyBox'); // BARU

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
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
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
