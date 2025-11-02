// File: lib/pages/cart_page.dart (MODIFIED - FINAL REVISION)

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item_model.dart';
import 'checkout_detail_page.dart';

// --- DEFINISI WARNA KONSISTEN ---
const Color darkPrimaryColor = Color(0xFF703B3B); // Primary Dark
const Color secondaryAccentColor = Color(0xFFA18D6D); // Secondary Accent
const Color lightBackgroundColor = Color(0xFFE1D0B3); // Main Background

// =========================================================
// 🔄 WIDGET INTERAKTIF UNTUK MENGUBAH KUANTITAS
// =========================================================
class _CartItemInteractive extends StatefulWidget {
  final CartItemModel item;
  final int index;

  const _CartItemInteractive({required this.item, required this.index});

  @override
  State<_CartItemInteractive> createState() => _CartItemInteractiveState();
}

class _CartItemInteractiveState extends State<_CartItemInteractive> {
  // Fungsi untuk menampilkan dialog konfirmasi penghapusan
  Future<void> _confirmDelete(
    BuildContext context,
    int index,
    String itemName,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Item'),
          content: Text('Yakin ingin menghapus "$itemName" dari keranjang?'),
          actions: <Widget>[
            TextButton(
              child: Text('Batal', style: TextStyle(color: darkPrimaryColor)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: darkPrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
              onPressed: () {
                Hive.box<CartItemModel>('cartBox').deleteAt(index);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$itemName berhasil dihapus.'),
                    backgroundColor: darkPrimaryColor,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menambah kuantitas
  void _incrementQuantity() {
    widget.item.quantity++;
    widget.item.save(); // Menyimpan perubahan ke Hive
  }

  // Fungsi untuk mengurangi kuantitas
  void _decrementQuantity() {
    if (widget.item.quantity > 1) {
      widget.item.quantity--;
      widget.item.save(); // Menyimpan perubahan ke Hive
    } else {
      // Jika kuantitas 1, panggil konfirmasi hapus
      _confirmDelete(context, widget.index, widget.item.strMeal);
    }
  }

  // Widget untuk tombol +/-
  Widget _buildQuantityButton(
    IconData icon,
    VoidCallback onPressed,
    bool isMinOne,
  ) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isMinOne ? Colors.grey.shade300 : darkPrimaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(icon, color: Colors.white),
        onPressed: isMinOne ? null : onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Item
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: lightBackgroundColor,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: item.strMealThumb.startsWith('assets/')
                  ? Image.asset(item.strMealThumb, fit: BoxFit.cover)
                  : Image.network(
                      item.strMealThumb,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Icon(Icons.broken_image)),
                    ),
            ),
          ),
          const SizedBox(width: 15),

          // Nama Item dan Harga Satuan/Total
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.strMeal,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: darkPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Total Harga Item
                Text(
                  'Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: darkPrimaryColor,
                  ),
                ),
                Text(
                  'Rp ${(item.price).toStringAsFixed(0)} / pcs', // Harga Satuan
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          // Quantity Selector (Minus/Quantity/Plus)
          Row(
            children: [
              _buildQuantityButton(
                Icons.remove,
                _decrementQuantity,
                item.quantity == 1,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  item.quantity.toString(),
                  style: TextStyle(
                    color: darkPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _buildQuantityButton(Icons.add, _incrementQuantity, false),
            ],
          ),
          // Ikon Hapus item telah dihapus
        ],
      ),
    );
  }
}

// =========================================================
// CLASS CartPage (BACKGROUND DIUBAH SEMUA KE LIGHT)
// =========================================================
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Latar belakang utama: Light Background
      backgroundColor: lightBackgroundColor,
      appBar: AppBar(
        // AppBar Background: Light Background
        backgroundColor: lightBackgroundColor,
        elevation: 0,
        leading: IconButton(
          // Ikon panah kembali
          icon: Icon(Icons.arrow_back_ios, color: darkPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cart',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: darkPrimaryColor,
          ),
        ),
        centerTitle: true,
        actions: const [
          // Ikon silang (close) di atas telah dihapus
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<CartItemModel>('cartBox').listenable(),
        builder: (context, Box<CartItemModel> box, _) {
          final items = box.values.toList();
          final subtotalPrice = items.fold(
            0.0,
            (sum, item) => sum + (item.price * item.quantity),
          );

          if (items.isEmpty) {
            return Center(
              child: Text(
                'Keranjang Anda kosong.',
                style: TextStyle(color: darkPrimaryColor),
              ),
            );
          }

          // Konten Container: Light Background untuk konsistensi "semua background light"
          return Container(
            decoration: const BoxDecoration(color: lightBackgroundColor),
            child: Column(
              children: [
                // --- Daftar Item ---
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _CartItemInteractive(
                        item: items[index],
                        index: index,
                      );
                    },
                    separatorBuilder: (context, index) => Divider(
                      color: secondaryAccentColor.withOpacity(0.5),
                      height: 1,
                    ),
                  ),
                ),

                // --- Divider ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10,
                  ),
                  child: Divider(thickness: 1, color: secondaryAccentColor),
                ),

                // --- Area Rincian Harga (Subtotal & Total) ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25.0,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      // Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Rp ${subtotalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkPrimaryColor,
                            ),
                          ),
                        ],
                      ),

                      // Total
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rp ${subtotalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- Tombol Checkout ---
                Padding(
                  padding: const EdgeInsets.only(
                    left: 25.0,
                    right: 25.0,
                    bottom: 30.0,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutDetailPage(
                            totalPrice: subtotalPrice,
                            items: items,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkPrimaryColor,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'CHECK OUT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
