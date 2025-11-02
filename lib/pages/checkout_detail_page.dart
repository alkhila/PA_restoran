// File: lib/pages/checkout_detail_page.dart (MODIFIED - USER FILTERING FOR HISTORY)

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [BARU]
import '../models/cart_item_model.dart';
import '../models/purchase_history_model.dart';
import '../services/currency_service.dart';
import '../services/location_service.dart';

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);
const Color darkPrimaryColor = Color(0xFF703B3B);
const Color secondaryAccentColor = Color(0xFFA18D6D);

// ======================================================
// Halaman Struk Pembayaran / Riwayat Pembelian (Class ReceiptPage)
// ======================================================
class ReceiptPage extends StatefulWidget {
  const ReceiptPage({super.key});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
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

  void _backToHome(BuildContext context) async {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading jika email belum dimuat
    if (_currentUserEmail.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Riwayat Pembelian')),
        body: Center(child: CircularProgressIndicator(color: brownColor)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pembelian'),
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<PurchaseHistoryModel>(
          'historyBox',
        ).listenable(),
        builder: (context, Box<PurchaseHistoryModel> box, _) {
          // Filter history hanya untuk user saat ini
          final history = box.values
              .where((record) => record.userEmail == _currentUserEmail)
              .toList()
              .reversed
              .toList();

          if (history.isEmpty) {
            return Center(
              child: Text(
                'Belum ada riwayat pembelian.',
                style: TextStyle(color: darkPrimaryColor),
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
                          color: darkPrimaryColor,
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
                          color: darkPrimaryColor,
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
        backgroundColor: darkPrimaryColor,
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

  late Future<Map<String, double>> _ratesFuture;
  bool _isLocating = true;
  String _targetCurrency = 'IDR';
  double _convertedAmount = 0.0;
  String _locationStatus = 'Menentukan mata uang default...';
  String _currentUserEmail = ''; // State untuk menyimpan email user aktif

  @override
  void initState() {
    super.initState();
    _ratesFuture = _currencyService.getExchangeRates();
    _convertedAmount = widget.totalPrice;
    _loadCurrentUserEmailAndDetermineCurrency();
  }

  Future<void> _loadCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = prefs.getString('current_user_email') ?? '';
  }

  void _loadCurrentUserEmailAndDetermineCurrency() async {
    await _loadCurrentUserEmail();
    _determineDefaultCurrency();
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
        _targetCurrency = 'IDR';
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
    if (_currentUserEmail.isEmpty) {
      // Harus tidak terjadi karena ini dipanggil setelah login
      return;
    }

    // 1. Simpan Riwayat Pembelian
    final historyBox = Hive.box<PurchaseHistoryModel>('historyBox');

    final newRecord = PurchaseHistoryModel(
      finalPrice: _convertedAmount,
      currency: _targetCurrency,
      purchaseTime: DateTime.now(),
      items: widget.items.toList(),
      userEmail: _currentUserEmail, // [REVISI] Simpan email user
    );
    await historyBox.add(newRecord);

    // 2. Bersihkan Keranjang HANYA untuk user ini
    final cartBox = Hive.box<CartItemModel>('cartBox');
    final keysToDelete = cartBox.keys
        .where((key) => cartBox.get(key)?.userEmail == _currentUserEmail)
        .toList();

    await cartBox.deleteAll(keysToDelete);

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
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _ratesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLocating) {
            // ... (loading state)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: accentColor),
                  const SizedBox(height: 10),
                  Text(_locationStatus, style: TextStyle(color: brownColor)),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            // ... (error state)
            return Center(
              child: Text(
                'Gagal memuat rate mata uang: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.hasData) {
            // ... (success state)
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
                      color: darkPrimaryColor,
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
                      color: darkPrimaryColor,
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
                              _convertCurrency(rates);
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
                      backgroundColor: darkPrimaryColor,
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
