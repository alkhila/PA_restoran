// File: lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'time_converter_page.dart';
import '../services/api_service.dart';
import '../services/location_service.dart'; // Wajib untuk Pelacak Lokasi
import 'cart_page.dart';
import 'lbs_page.dart';
import 'detail_page.dart';

// --- DEFINISI WARNA (Konstanta Desain Coklat) ---
const Color brownColor = Color(0xFF4E342E); // Coklat Tua
const Color accentColor = Color(0xFFFFB300); // Oranye Aksen

// Enum untuk opsi filter
enum MenuFilter { all, makanan, minuman }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _userName = 'Pengguna';
  late Future<List<dynamic>> _menuFuture;

  final ApiService _apiService = ApiService();
  final LocationService _locationService =
      LocationService(); // INSTANCE SERVICE LOKASI

  // State untuk LBS
  String _currentAddress = 'Klik Lacak Lokasi';
  bool _isLocating = false;

  // State untuk Search dan Filter
  String _searchQuery = '';
  MenuFilter _currentFilter = MenuFilter.all;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _menuFuture = _apiService.fetchMenu();
  }

  // --- Session Management ---
  void _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'FastFoodie';
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  // FUNGSI LBS: Lacak Lokasi Saat Ini
  void _trackLocation() async {
    setState(() {
      _isLocating = true;
      _currentAddress = 'Sedang melacak lokasi...';
    });

    try {
      final position = await _locationService.getCurrentPosition();
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentAddress = address;
        _isLocating = false;
      });
    } catch (e) {
      setState(() {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        _currentAddress = 'Error: $errorMsg';
        _isLocating = false;
      });
    }
  }

  // --- Widget 1: Katalog Menu (Simulasi Harga & Filter) ---
  Widget _buildMenuCatalog() {
    return Column(
      children: [
        // --- Search Bar ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: "Cari menu...",
              prefixIcon: Icon(Icons.search, color: brownColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade200,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),

        // --- Filter Chips (Kategori) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFilterChip('Semua', MenuFilter.all),
              _buildFilterChip('Makanan', MenuFilter.makanan),
              _buildFilterChip('Minuman', MenuFilter.minuman),
            ],
          ),
        ),

        // --- Grid View Menu ---
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _menuFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: accentColor),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                // --- Logika Filtering dan Searching ---
                final rawMenuList = snapshot.data!;

                List<dynamic> filteredList = rawMenuList.where((item) {
                  final Map<String, dynamic> itemMap =
                      Map<String, dynamic>.from(item);
                  final String itemName =
                      itemMap['strMeal']?.toLowerCase() ?? '';
                  final bool matchesSearch = itemName.contains(
                    _searchQuery.toLowerCase(),
                  );
                  final String itemType = itemMap['type']?.toLowerCase() ?? '';
                  bool matchesFilter = true;

                  if (_currentFilter == MenuFilter.makanan) {
                    matchesFilter = itemType == 'makanan';
                  } else if (_currentFilter == MenuFilter.minuman) {
                    matchesFilter = itemType == 'minuman';
                  }
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Text(
                      'Menu tidak ditemukan.',
                      style: TextStyle(color: brownColor),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];

                    final isLocalAsset =
                        (item['type'] == 'Minuman' &&
                        (item['strMealThumb'] as String).startsWith('assets/'));

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                              child: isLocalAsset
                                  ? Image.asset(
                                      // Gambar dari Aset Lokal
                                      item['strMealThumb'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    )
                                  : Image.network(
                                      // Gambar dari Jaringan
                                      item['strMealThumb'] ??
                                          'https://via.placeholder.com/150',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              item['strMeal'] ?? 'Nama Menu',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: brownColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              bottom: 4.0,
                            ),
                            child: Text(
                              'Tipe: ${item['type'] ?? 'N/A'}',
                              style: const TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              bottom: 4.0,
                            ),
                            child: Text(
                              // HARGA SIMULASI
                              'Harga: Rp ${item['price']?.toStringAsFixed(0) ?? 'N/A'}',
                              style: const TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 8.0,
                                bottom: 8.0,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.add_shopping_cart,
                                  color: brownColor,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailPage(item: item),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              } else {
                return Center(
                  child: Text(
                    'Tidak ada menu yang tersedia.',
                    style: TextStyle(color: brownColor),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // --- Widget 2: Halaman Profil (FINAL) ---
  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Foto dengan Path
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: brownColor, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/alza.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.person, size: 60, color: brownColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. Nama dan NIM Mahasiswa
                  const Text(
                    'Alkhila Syadza Fariha / 124230090',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: brownColor,
                    ),
                  ),

                  // 3. Status Mahasiswa
                  const Text(
                    'Mahasiswa Pemrograman Aplikasi Mobile',
                    style: TextStyle(color: brownColor, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // --- LBS FEATURE: Lokasi User (BARU) ---
                  Text(
                    'Lokasi Saya:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: brownColor,
                    ),
                  ),
                  Text(
                    _currentAddress,
                    style: TextStyle(
                      fontSize: 14,
                      color: _isLocating
                          ? Colors.blue
                          : brownColor.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _isLocating
                        ? null
                        : _trackLocation, // Tombol disabled saat melacak
                    icon: _isLocating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.location_on),
                    label: Text(
                      _isLocating ? 'Melacak...' : 'Lacak Lokasi Sekarang',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: brownColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // --- AKHIR LBS FEATURE ---

                  // --- CARD KESAN DAN PESAN ---
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kesan:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: brownColor,
                            ),
                          ),
                          const Text(
                            'Saya sangat berkesan dengan mata kuliah mobile ini.',
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Saran:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: brownColor,
                            ),
                          ),
                          const Text(
                            'Tolong dikasih deadline yg lebih panjang.',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- AKHIR CARD KESAN DAN PESAN ---
                  const Divider(height: 40, color: Colors.grey),

                  // 5. Username User yang Login
                  Text(
                    'Username: $_userName',
                    style: TextStyle(
                      fontSize: 16,
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Menu Wajib Tugas Akhir:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: brownColor,
                    ),
                  ),

                  // 6. Konversi Mata Uang
                  ListTile(
                    leading: const Icon(
                      Icons.account_balance_wallet,
                      color: accentColor,
                    ),
                    title: const Text('Konversi Mata Uang (min. 3 mata uang)'),
                    onTap: () {
                      setState(() {
                        _selectedIndex =
                            2; // Pindah ke Keranjang untuk Checkout dan Konversi
                      });
                    },
                  ),

                  // 7. Konversi Waktu
                  ListTile(
                    leading: const Icon(Icons.access_time, color: accentColor),
                    title: const Text(
                      'Konversi Waktu (WIB, WITA, WIT, London)',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TimeConverterPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // 8. Tombol Logout (Dipastikan Selalu Aktif)
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 20), // Padding di bagian bawah
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pembantu untuk Filter Chip
  Widget _buildFilterChip(String label, MenuFilter filter) {
    bool isSelected = _currentFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: accentColor.withOpacity(0.8),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentFilter = filter; // Mengubah state filter
          });
        }
      },
      labelStyle: TextStyle(
        color: isSelected ? brownColor : Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.grey.shade100,
    );
  }

  // --- Widget 3: Halaman Keranjang ---
  Widget _buildCartPage() {
    return const CartPage();
  }

  Widget _buildLBSPage() {
    return const LBSPage();
  }

  @override
  Widget build(BuildContext context) {
    // Definisikan list widget di sini
    final List<Widget> widgetOptions = <Widget>[
      _buildMenuCatalog(),
      _buildProfilePage(),
      _buildCartPage(),
      _buildLBSPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: brownColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("FastFood App", style: TextStyle(fontSize: 14)),
            Text(
              "Halo, $_userName!",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: widgetOptions.elementAt(_selectedIndex),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            label: 'Home',
            icon: const Icon(Icons.home),
            backgroundColor: brownColor,
          ),
          BottomNavigationBarItem(
            label: 'Profil',
            icon: const Icon(Icons.person),
            backgroundColor: brownColor,
          ),
          BottomNavigationBarItem(
            label: 'Keranjang',
            icon: const Icon(Icons.shopping_cart),
            backgroundColor: brownColor,
          ),
          BottomNavigationBarItem(
            label: 'LBS',
            icon: const Icon(Icons.location_on),
            backgroundColor: brownColor,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.white70,
        backgroundColor: brownColor,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
