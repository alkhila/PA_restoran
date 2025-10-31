// File: lib/pages/cart_page.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item_model.dart';
import 'checkout_detail_page.dart';

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Belanja'),
        backgroundColor: brownColor,
        foregroundColor: Colors.white,
      ),
      // Hive WatchBoxBuilder agar list otomatis update saat item ditambahkan/dihapus
      body: ValueListenableBuilder(
        valueListenable: Hive.box<CartItemModel>('cartBox').listenable(),
        builder: (context, Box<CartItemModel> box, _) {
          final items = box.values.toList();
          final totalPrice = items.fold(
            0.0,
            (sum, item) => sum + (item.price * item.quantity),
          );

          if (items.isEmpty) {
            return Center(
              child: Text(
                'Keranjang Anda kosong.',
                style: TextStyle(color: brownColor),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: SizedBox(
                        width: 50,
                        height: 50,
                        // Menampilkan gambar (asumsi semua item keranjang sudah berupa aset atau network link yang valid)
                        child: item.strMealThumb.startsWith('assets/')
                            ? Image.asset(item.strMealThumb, fit: BoxFit.cover)
                            : Image.network(
                                item.strMealThumb,
                                fit: BoxFit.cover,
                              ),
                      ),
                      title: Text(item.strMeal),
                      subtitle: Text(
                        '${item.quantity} x Rp ${item.price.toStringAsFixed(0)}',
                      ),
                      trailing: Text(
                        'Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),

              // --- Checkout Button Area ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Total Pembelian: Rp ${totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: brownColor,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigasi ke Halaman Detail Pembelian (Checkout)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutDetailPage(
                              totalPrice: totalPrice,
                              items: items,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Lanjutkan Checkout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: brownColor,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
