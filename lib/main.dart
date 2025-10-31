import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';

void main() async {
  // Pastikan binding sudah siap sebelum memanggil native code (Hive)
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Hive
  await Hive.initFlutter();

  // Buka Box untuk User data (key: email, value: data user)
  await Hive.openBox('userBox');
  // Buka Box untuk Session (key: isLoggedIn/userName, value: status/nama)
  await Hive.openBox('sessionBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Session Check: Memeriksa status login dari Hive
  Future<bool> _checkLoginStatus() async {
    final sessionBox = Hive.box('sessionBox');
    return sessionBox.get('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Warna Aksen
    final accentColor = const Color(0xFFFFB300);

    return MaterialApp(
      title: 'FastFood App TA',
      theme: ThemeData(primarySwatch: Colors.brown, fontFamily: 'Roboto'),
      // Cek status login di Hive saat aplikasi dimulai
      home: FutureBuilder<bool>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accentColor));
          }
          // Jika sudah login, langsung ke HomePage, jika belum ke LoginPage
          return snapshot.data == true ? const HomePage() : const LoginPage();
        },
      ),
      // Definisikan routes lain (tidak menyertakan '/' karena sudah ada properti 'home')
      routes: {
        '/register': (context) => RegisterPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
