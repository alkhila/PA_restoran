// File: lib/pages/checkout_detail_page.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // Wajib: Tambahkan dependency: intl di pubspec.yaml
import '../models/cart_item_model.dart';
import '../models/purchase_history_model.dart';
import '../services/currency_service.dart'; // Wajib: File service mata uang
import 'cart_page.dart'; // Import CartPage untuk memuat ulang keranjang

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);

// ======================================================
// Halaman Struk Pembayaran (Riwayat Pembelian)
// ======================================================
class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key});

  // Navigasi yang kembali ke Home Page (dan membersihkan stack)
  void _backToHome(BuildContext context) async {
    // Kembali ke /home (root app) dan hapus semua rute di atasnya
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pembelian'),
        backgroundColor: brownColor,
        automaticallyImplyLeading: false, // Jangan tampilkan tombol back
      ),
      // Memantau historyBox untuk menampilkan riwayat
      body: ValueListenableBuilder(
        valueListenable: Hive.box<PurchaseHistoryModel>(
          'historyBox',
        ).listenable(),
        builder: (context, Box<PurchaseHistoryModel> box, _) {
          final history = box.values
              .toList()
              .reversed
              .toList(); // Terbaru di atas

          if (history.isEmpty) {
            return Center(
              child: Text(
                'Belum ada riwayat pembelian.',
                style: TextStyle(color: brownColor),
              ),
            );
          }

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final record = history[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waktu Pembelian: ${DateFormat('dd MMM yyyy, HH:mm:ss').format(record.purchaseTime)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: brownColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Mata Uang Akhir: ${record.currency}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Total Bayar: ${record.currency} ${record.finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const Divider(height: 15),
                      // Tampilkan Detil Item yang Dibeli
                      ...record.items
                          .map(
                            (item) =>
                                Text('${item.strMeal} (${item.quantity}x)'),
                          )
                          .toList(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // Tombol Struk Kembali ke Home (Sesuai Permintaan)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _backToHome(context),
        label: const Text('Kembali ke Home'),
        icon: const Icon(Icons.home),
        backgroundColor: brownColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ======================================================
// Halaman Detail Pembelian (Checkout Detail) - Dengan Konverter
// ======================================================
class CheckoutDetailPage extends StatefulWidget {
  final double totalPrice;
  final List<CartItemModel> items;

  const CheckoutDetailPage({
    super.key,
    required this.totalPrice,
    required this.items,
  });

  @override
  State<CheckoutDetailPage> createState() => _CheckoutDetailPageState();
}

class _CheckoutDetailPageState extends State<CheckoutDetailPage> {
  final CurrencyService _currencyService = CurrencyService();
  late Future<Map<String, double>> _ratesFuture;

  String _targetCurrency = 'IDR'; // Default ke IDR
  double _convertedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _ratesFuture = _currencyService.getExchangeRates();
    _convertedAmount = widget.totalPrice;
  }

  // Fungsi Konversi Mata Uang
  void _convertCurrency(Map<String, double> rates) {
    // Logika Konversi (Base IDR)
    if (rates.containsKey(_targetCurrency)) {
      final rateToTarget = rates[_targetCurrency]!; // Rate dari IDR ke Target
      setState(() {
        // Konversi: Total IDR * Rate IDR ke Target
        _convertedAmount = widget.totalPrice * rateToTarget;
      });
    }
  }

  // Fungsi Pembayaran dan Penyimpanan Riwayat
  void _handlePayment() async {
    // Cek apakah keranjang kosong (pencegahan double checkout)
    if (widget.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang kosong! Tidak ada yang bisa dibayar.'),
        ),
      );
      return;
    }

    // 1. Simpan Riwayat Pembelian
    final historyBox = Hive.box<PurchaseHistoryModel>('historyBox');

    final newRecord = PurchaseHistoryModel(
      finalPrice: _convertedAmount,
      currency: _targetCurrency,
      purchaseTime: DateTime.now(), // Waktu pembelian
      items: widget.items.toList(),
    );
    await historyBox.add(newRecord);

    // 2. Bersihkan Keranjang (CartBox)
    await Hive.box<CartItemModel>('cartBox').clear();

    // 3. Navigasi ke Halaman Struk/Riwayat Pembelian
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ReceiptPage(),
      ), // <-- Menuju halaman struk
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detil Pembelian & Konversi'),
        backgroundColor: brownColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _ratesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Gagal memuat rate mata uang. Tampilkan default IDR. Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final rates = snapshot.data!;

            // Konversi awal ke IDR saat data rates tersedia
            if (_convertedAmount == widget.totalPrice &&
                _targetCurrency == 'IDR') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _convertCurrency(rates);
              });
            }

            return Padding(
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

                  // Daftar item
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        return Text(
                          '- ${item.strMeal} (${item.quantity}x) @ Rp ${item.price.toStringAsFixed(0)}',
                        );
                      },
                    ),
                  ),
                  const Divider(),

                  // --- Konversi Mata Uang ---
                  Text(
                    'Konversi Pembayaran:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: brownColor,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Konversi ke:',
                        style: TextStyle(fontSize: 16),
                      ),
                      DropdownButton<String>(
                        value: _targetCurrency,
                        items: rates.keys.map((String currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(
                              currency,
                              style: TextStyle(color: brownColor),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _targetCurrency = newValue;
                              _convertCurrency(
                                rates,
                              ); // Konversi saat dropdown berubah
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // --- Total Akhir ---
                  Text(
                    'Total Bayar Akhir:',
                    style: TextStyle(
                      fontSize: 18,
                      color: brownColor.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    '$_targetCurrency ${NumberFormat.currency(locale: 'en_US', symbol: '').format(_convertedAmount)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Button Pembayaran ---
                  ElevatedButton.icon(
                    onPressed: _handlePayment,
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
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
