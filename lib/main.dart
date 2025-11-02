import 'package:flutter/material.dart';
import 'package:pa_restoran2/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user_model.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'models/cart_item_model.dart';
import 'models/purchase_history_model.dart';

// Definisi warna yang konsisten
const Color accentColor = Color(0xFFFFB300);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Daftarkan Adapter (Asumsi Cart dan History menggunakan TypeId baru 3 & 4)
  Hive.registerAdapter(UserModelAdapter()); // TypeId 0
  Hive.registerAdapter(
    CartItemModelAdapter(),
  ); // TypeId 3 (Harus dijalankan build_runner!)
  Hive.registerAdapter(
    PurchaseHistoryModelAdapter(),
  ); // TypeId 4 (Harus dijalankan build_runner!)

  // Buka Box
  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<CartItemModel>('cartBox');
  await Hive.openBox<PurchaseHistoryModel>('historyBox');

  // 🔔 Inisialisasi notifikasi lokal
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FastFood App TA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.brown, fontFamily: 'Roboto'),

      // MENGATUR HOME PROPERTY UNTUK CEK SESI (SPLASH SCREEN LOGIC)
      home: FutureBuilder<bool>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }
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
    // Tambahkan juga pemeriksaan apakah email user aktif ada
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userEmailExists = prefs.getString('current_user_email') != null;

    return isLoggedIn && userEmailExists;
  }
}
