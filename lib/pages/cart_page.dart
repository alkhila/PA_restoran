import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import 'checkout_detail_page.dart';

const Color darkPrimaryColor = Color.fromARGB(255, 66, 37, 37);
const Color secondaryAccentColor = Color.fromARGB(255, 104, 91, 70);
const Color lightBackgroundColor = Color.fromARGB(255, 231, 222, 206);

class _CartItemInteractive extends StatefulWidget {
  final CartItemModel item;
  final int index;
  final String currentUserEmail;

  const _CartItemInteractive({
    required this.item,
    required this.index,
    required this.currentUserEmail,
  });

  @override
  State<_CartItemInteractive> createState() => _CartItemInteractiveState();
}

class _CartItemInteractiveState extends State<_CartItemInteractive> {
  final Box<CartItemModel> cartBox = Hive.box<CartItemModel>('cartBox');

  void _incrementQuantity() {
    widget.item.quantity++;
    widget.item.save();
  }

  // [UPDATE] Logika untuk mengurangi jumlah (menghapus jika kuantitas = 1)
  void _decrementQuantity() {
    if (widget.item.quantity > 1) {
      // Case 1: Jumlah > 1, kurangi normal
      widget.item.quantity--;
      widget.item.save();
    } else {
      // Case 2: Jumlah == 1, hapus item dari keranjang
      final String itemName = widget.item.strMeal;
      final itemKey = widget.item.key;

      if (itemKey != null) {
        cartBox.delete(itemKey);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemName berhasil dihapus dari keranjang.'),
            backgroundColor: darkPrimaryColor,
          ),
        );
      }
    }
  }

  Widget _buildQuantityButton(
    IconData icon,
    VoidCallback onPressed,
    // Parameter isMinOne dihapus karena kita selalu menggunakan Icons.remove
  ) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: darkPrimaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
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
                Text(
                  'Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: darkPrimaryColor,
                  ),
                ),
                Text(
                  'Rp ${(item.price).toStringAsFixed(0)} / pcs',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          Row(
            children: [
              _buildQuantityButton(
                Icons.remove, // [UPDATE] Ikon selalu minus
                _decrementQuantity,
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
              _buildQuantityButton(Icons.add, _incrementQuantity),
            ],
          ),
        ],
      ),
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String _currentUserEmail = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }

  Future<void> _loadCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('current_user_email') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserEmail.isEmpty) {
      return Scaffold(
        backgroundColor: lightBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: darkPrimaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      body: ValueListenableBuilder(
        valueListenable: Hive.box<CartItemModel>('cartBox').listenable(),
        builder: (context, Box<CartItemModel> box, _) {
          final allItems = box.values.toList();
          final userItems = allItems
              .where((item) => item.userEmail == _currentUserEmail)
              .toList();

          final subtotalPrice = userItems.fold(
            0.0,
            (sum, item) => sum + (item.price * item.quantity),
          );

          if (userItems.isEmpty) {
            return Center(
              child: Text(
                'Keranjang Anda kosong.',
                style: TextStyle(color: darkPrimaryColor),
              ),
            );
          }

          return Container(
            decoration: const BoxDecoration(color: lightBackgroundColor),
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: userItems.length,
                    itemBuilder: (context, index) {
                      final item = userItems[index];
                      // Menemukan kunci asli item di Hive Box (bukan index dari list yang difilter)
                      final originalIndex = box.values.toList().indexOf(item);

                      // Cek jika itemKey adalah null, kita tidak bisa membuat widget, tapi secara teori itemKey tidak boleh null di sini
                      if (originalIndex == -1) return const SizedBox.shrink();

                      return _CartItemInteractive(
                        item: item,
                        index: originalIndex,
                        currentUserEmail: _currentUserEmail,
                      );
                    },
                    separatorBuilder: (context, index) => Divider(
                      color: secondaryAccentColor.withOpacity(0.5),
                      height: 1,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10,
                  ),
                  child: Divider(thickness: 1, color: secondaryAccentColor),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25.0,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
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
                            items: userItems,
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
