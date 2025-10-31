// File: lib/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart'; // Import UserModel

// Definisi warna yang konsisten
const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    final String email = _emailController.text;
    final String password = _passwordController.text;

    // --- LOGIKA VERIFIKASI HIVE DINAMIS ---
    final userBox = Hive.box<UserModel>('userBox');

    // Cari pengguna berdasarkan email dan password
    final user = userBox.values.firstWhere(
      (user) => user.email == email && user.password == password,
      orElse: () => UserModel(
        email: '',
        password: '',
        username: '',
      ), // Mengembalikan dummy jika tidak ditemukan
    );

    // Cek apakah user valid (email tidak kosong)
    if (user.email.isNotEmpty) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Set Session (simpan status login dan username)
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString(
        'userName',
        user.username,
      ); // Simpan username dinamis

      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Tampilkan error jika gagal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email atau kata sandi salah atau pengguna tidak terdaftar!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Masuk Akun',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: brownColor,
                ),
              ),
              const SizedBox(height: 50),
              TextField(
                controller: _emailController,
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
    );
  }
}
