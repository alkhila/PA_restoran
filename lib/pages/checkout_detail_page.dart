// File: lib/pages/checkout_detail_page.dart (FINAL)

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart'; // Wajib jika menggunakan LBS
import '../models/cart_item_model.dart';
import '../models/purchase_history_model.dart';
import '../services/currency_service.dart';
import '../services/location_service.dart';

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);

// ======================================================
// Halaman Struk Pembayaran / Riwayat Pembelian (Class ReceiptPage)
// ======================================================
class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key});

  void _backToHome(BuildContext context) async {
    // Navigasi kembali ke Home Page (dan membersihkan stack)
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pembelian'),
        backgroundColor: brownColor,
        automaticallyImplyLeading: false,
      ),
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
                      Text(
                        'Detil Item:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: brownColor,
                        ),
                      ),
                      // Detil item yang dibeli
                      ...record.items
                          .map(
                            (item) =>
                                Text('- ${item.strMeal} (${item.quantity}x)'),
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
// Halaman Detail Pembelian (Checkout Detail)
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
  final LocationService _locationService = LocationService();

  // State Lokasi & Mata Uang
  late Future<Map<String, double>> _ratesFuture;
  bool _isLocating = true;
  String _targetCurrency = 'IDR';
  double _convertedAmount = 0.0;
  String _locationStatus = 'Menentukan mata uang default...';

  @override
  void initState() {
    super.initState();
    _ratesFuture = _currencyService.getExchangeRates();
    _convertedAmount = widget.totalPrice;
    _determineDefaultCurrency(); // Mulai pelacakan lokasi
  }

  void _determineDefaultCurrency() async {
    try {
      final position = await _locationService.getCurrentPosition();
      final locationData = await _locationService.getCountryCode(
        position.latitude,
        position.longitude,
      );

      final countryCode = locationData['code']!;
      final countryName = locationData['name']!;

      final defaultCurrency = _currencyService.getDefaultCurrency(countryCode);

      setState(() {
        _isLocating = false;
        _targetCurrency = defaultCurrency;
        _locationStatus = 'Default Mata Uang: $defaultCurrency ($countryName).';

        _ratesFuture.then((rates) {
          _convertCurrency(rates);
        });
      });
    } catch (e) {
      setState(() {
        _isLocating = false;
        _targetCurrency = 'IDR'; // Default ke IDR jika ada error lokasi
        _locationStatus =
            'Gagal melacak lokasi. Default: IDR. Error: ${e.toString()}';

        _ratesFuture.then((rates) {
          _convertCurrency(rates);
        });
      });
    }
  }

  void _convertCurrency(Map<String, double> rates) {
    if (rates.containsKey(_targetCurrency)) {
      final double targetRate = rates[_targetCurrency]!;

      setState(() {
        // Konversi: Total IDR * Rate IDR ke Mata Uang Target
        _convertedAmount = widget.totalPrice * targetRate;
      });
    }
  }

  void _handlePayment() async {
    // 1. Simpan Riwayat Pembelian
    final historyBox = Hive.box<PurchaseHistoryModel>('historyBox');

    final newRecord = PurchaseHistoryModel(
      finalPrice: _convertedAmount,
      currency: _targetCurrency,
      purchaseTime: DateTime.now(), // Waktu pembayaran ditekan
      items: widget.items.toList(),
    );
    await historyBox.add(newRecord);

    // 2. Bersihkan Keranjang
    await Hive.box<CartItemModel>('cartBox').clear();

    // 3. Navigasi ke Halaman Struk/Riwayat Pembelian
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ReceiptPage()),
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
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLocating) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: accentColor),
                  const SizedBox(height: 10),
                  Text(_locationStatus, style: TextStyle(color: brownColor)),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat rate mata uang: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.hasData) {
            final rates = snapshot.data!;
            final currencyList = rates.keys.toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Lokasi/Mata Uang Default
                  Text(
                    'Status Konversi: $_locationStatus',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),

                  // Daftar item
                  Text(
                    'Ringkasan Pesanan:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: brownColor,
                    ),
                  ),
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
                    'Konversi Mata Uang:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: brownColor,
                    ),
                  ),

                  Row(
                    children: [
                      // Pilihan Dropdown Mata Uang
                      const Text('Ganti Mata Uang: '),
                      DropdownButton<String>(
                        value: _targetCurrency,
                        items: currencyList.map((String currency) {
                          return DropdownMenuItem<String>(
                            value: currency,
                            child: Text(currency),
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
                  const SizedBox(height: 15),

                  // --- Total Akhir ---
                  Text(
                    'Total Bayar Akhir: $_targetCurrency ${_convertedAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
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
