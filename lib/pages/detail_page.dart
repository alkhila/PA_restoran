// File: lib/pages/detail_page.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item_model.dart';

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> item; // Menerima data menu

  const DetailPage({super.key, required this.item});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _quantity = 1;

  // Simulasi Harga
  final double _basePrice = 15000.0;

  // Fungsi untuk menambah item ke keranjang
  void _addToCart() async {
    final cartBox = Hive.box<CartItemModel>('cartBox');

    final newItem = CartItemModel(
      idMeal: widget.item['idMeal'] ?? UniqueKey().toString(),
      strMeal: widget.item['strMeal'] ?? 'Unknown Item',
      strMealThumb: widget.item['strMealThumb'] ?? '',
      quantity: _quantity,
      price: _basePrice, // Gunakan harga simulasi
    );

    // Logika sederhana: cek jika item sudah ada, update kuantitasnya
    final existingItemIndex = cartBox.values.toList().indexWhere(
      (e) => e.idMeal == newItem.idMeal,
    );

    if (existingItemIndex != -1) {
      final existingItem = cartBox.getAt(existingItemIndex)!;
      existingItem.quantity += _quantity;
      await existingItem.save();
    } else {
      await cartBox.add(newItem);
    }

    // Beri feedback dan kembali ke home
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${newItem.quantity}x ${newItem.strMeal} ditambahkan ke keranjang!',
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isLocalAsset =
        (item['type'] == 'Minuman' &&
        (item['strMealThumb'] as String).startsWith('assets/'));

    return Scaffold(
      appBar: AppBar(
        title: Text(item['strMeal'] ?? 'Detail Menu'),
        backgroundColor: brownColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Gambar Menu ---
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: isLocalAsset
                  ? Image.asset(
                      item['strMealThumb'],
                      fit: BoxFit.cover,
                      height: 250,
                      width: double.infinity,
                    )
                  : Image.network(
                      item['strMealThumb'] ?? 'https://via.placeholder.com/250',
                      fit: BoxFit.cover,
                      height: 250,
                      width: double.infinity,
                    ),
            ),
            const SizedBox(height: 20),

            // --- Nama dan Harga ---
            Text(
              item['strMeal'] ?? 'Unknown Item',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: brownColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Harga Satuan: Rp ${_basePrice.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 20,
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Kategori: ${item['type'] ?? 'N/A'}',
              style: TextStyle(
                fontSize: 16,
                color: brownColor.withOpacity(0.7),
              ),
            ),
            const Divider(height: 30),

            // --- Kuantitas ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Jumlah Pesanan:', style: TextStyle(fontSize: 18)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() {
                          if (_quantity > 1) _quantity--;
                        });
                      },
                    ),
                    Text('$_quantity', style: const TextStyle(fontSize: 20)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setState(() {
                          _quantity++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- Tombol Tambah ke Keranjang ---
            ElevatedButton.icon(
              onPressed: _addToCart,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(
                'Tambah ke Keranjang (Total: Rp ${(_basePrice * _quantity).toStringAsFixed(0)})',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: brownColor,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
