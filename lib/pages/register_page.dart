import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brownColor = const Color(0xFF4E342E); // Coklat Tua
    final accentColor = const Color(0xFFFFB300); // Oranye Aksen

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Buat Akun"),
        backgroundColor: brownColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 50),
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
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
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
                  labelText: 'Kata Sandi (Simulasi Enkripsi)',
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
                onPressed: () async {
                  if (_passwordController.text !=
                      _confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Konfirmasi kata sandi tidak cocok!'),
                      ),
                    );
                    return;
                  }

                  final userBox = Hive.box('userBox');

                  // Simpan user baru di Hive
                  await userBox.put(_emailController.text, {
                    'email': _emailController.text,
                    'password': _passwordController
                        .text, // Simpan password (seharusnya di-hash)
                    'name': 'User ' + _emailController.text.split('@').first,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pendaftaran Berhasil! Silahkan Login.'),
                    ),
                  );
                  Navigator.pop(context); // Kembali ke halaman Login
                },
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
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
