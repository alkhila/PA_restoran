// File: lib/pages/register_page.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart'; // Import UserModel

// Definisi warna yang konsisten
const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  void _register() async {
    final String name = _nameController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata Sandi dan Konfirmasi Kata Sandi tidak cocok!'),
        ),
      );
      return;
    }

    // Cek apakah email sudah terdaftar
    final userBox = Hive.box<UserModel>('userBox');
    if (userBox.values.any((user) => user.email == email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email ini sudah terdaftar. Silakan gunakan email lain.',
          ),
        ),
      );
      return;
    }

    // --- SIMPAN PENGGUNA BARU KE HIVE ---
    final newUser = UserModel(email: email, password: password, username: name);
    await userBox.add(newUser); // Simpan data pengguna baru

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pendaftaran sukses! Silakan Masuk.')),
    );
    Navigator.pop(context); // Kembali ke halaman Login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Buat Akun"),
        backgroundColor: brownColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Daftar Sekarang!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: brownColor,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline, color: accentColor),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.email, color: accentColor),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Kata Sandi (Tanpa Enkripsi - Untuk Contoh TA)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock, color: accentColor),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Kata Sandi',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_reset, color: accentColor),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: brownColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Daftar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Sudah punya akun? Masuk',
                style: TextStyle(color: brownColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
