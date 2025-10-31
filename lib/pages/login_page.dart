import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    final userBox = Hive.box('userBox');
    final sessionBox = Hive.box('sessionBox');

    final email = _emailController.text;
    final password = _passwordController.text;

    // 1. Ambil data user dari userBox Hive berdasarkan email
    final userData = userBox.get(email);

    // 2. Validasi Kredensial
    if (userData != null && userData['password'] == password) {
      // --- LOGIN BERHASIL ---

      // Set Session di Hive
      await sessionBox.put('isLoggedIn', true);
      await sessionBox.put('userName', userData['name'] ?? 'FastFoodie');

      // Navigasi ke Homepage
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // --- LOGIN GAGAL ---
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email atau kata sandi salah!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brownColor = const Color(0xFF4E342E); // Coklat Tua
    final accentColor = const Color(0xFFFFB300); // Oranye Aksen

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Selamat Datang!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: brownColor,
                  ),
                ),
                const SizedBox(height: 50),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person, color: accentColor),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock, color: accentColor),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brownColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Masuk',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(
                    'Belum punya akun? Daftar',
                    style: TextStyle(color: brownColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
