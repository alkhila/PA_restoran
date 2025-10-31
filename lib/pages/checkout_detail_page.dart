// File: lib/pages/checkout_detail_page.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item_model.dart';

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);

// ======================================================
// Halaman Struk Pembayaran
// ======================================================
class ReceiptPage extends StatelessWidget {
  final double totalPrice;

  const ReceiptPage({super.key, required this.totalPrice});

  void _finishPurchase(BuildContext context) async {
    // 1. Bersihkan Keranjang (CartBox)
    await Hive.box<CartItemModel>('cartBox').clear();

    // 2. Navigasi kembali ke Home Page (dan hapus semua route di stack)
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk Pembayaran'),
        backgroundColor: brownColor,
        automaticallyImplyLeading: false, // Jangan tampilkan tombol back
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                'Pembelian Berhasil!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: brownColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Total yang Dibayarkan: Rp ${totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),

              // --- Button Kembali ke Home ---
              ElevatedButton.icon(
                onPressed: () => _finishPurchase(context),
                icon: const Icon(Icons.home),
                label: const Text('Kembali ke Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: brownColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// Halaman Detail Pembelian (Checkout Detail)
// ======================================================
class CheckoutDetailPage extends StatelessWidget {
  final double totalPrice;
  final List<CartItemModel> items;

  const CheckoutDetailPage({
    super.key,
    required this.totalPrice,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detil Pembelian'),
        backgroundColor: brownColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Pesanan:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: brownColor,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Text(
                    '- ${item.strMeal} (${item.quantity}x) = Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
                  );
                },
              ),
            ),
            const Divider(),
            Text(
              'Total Bayar: Rp ${totalPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 30),

            // --- Button Pembayaran ---
            ElevatedButton.icon(
              onPressed: () {
                // Langsung menuju halaman struk (simulasi pembayaran sukses)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReceiptPage(totalPrice: totalPrice),
                  ),
                );
              },
              icon: const Icon(Icons.payment),
              label: const Text('Bayar Sekarang (Simulasi)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: brownColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
