// File: lib/pages/home_page.dart (LENGKAP)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Wajib: Untuk format waktu
import 'time_converter_page.dart'; // Import halaman Time Converter
import '../services/api_service.dart';
import '../services/time_service.dart'; // Import service waktu
import 'cart_page.dart';
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
  final TimeService _timeService = TimeService(); // Inisialisasi TimeService

  // State untuk Search dan Filter
  String _searchQuery = '';
  MenuFilter _currentFilter = MenuFilter.all;

  // State untuk Konversi Waktu
  String _currentTimezoneDisplay = 'WIB (Jakarta)';
  String _currentConvertedTime = 'Memuat waktu...';

  // Hapus deklarasi _widgetOptions dari sini

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _menuFuture = _apiService.fetchMenu();
    // Panggil fungsi konversi waktu saat initState
    _updateConvertedTime(_timeService.timeZones[_currentTimezoneDisplay]!);
  }

  // Fungsi untuk memuat dan menampilkan waktu
  void _updateConvertedTime(String timezoneEndpoint) async {
    final time = await _timeService.fetchTime(timezoneEndpoint);
    setState(() {
      _currentConvertedTime = time;
    });
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
    ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }

  // --- Widget 1: Katalog Menu ---
  Widget _buildMenuCatalog() {
    // ... (Kode _buildMenuCatalog() tetap sama dengan yang terakhir diperbaiki)
    // ...
    // [Keterangan: Karena kode ini sangat panjang, saya biarkan Anda menggunakan kode yang sudah ada,
    // tetapi asumsikan kode ini sudah benar dari respons sebelumnya]
    // ...

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
                                      item['strMealThumb'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : Image.network(
                                      item['strMealThumb'] ??
                                          'https://via.placeholder.com/150',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
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
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0, bottom: 4.0),
                            child: Text(
                              'Harga: N/A',
                              style: TextStyle(
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
            _currentFilter = filter;
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

  // --- Widget 2: Halaman Profil (Revisi Total) ---
  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  // 1. Foto dengan Path alza.jpg
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: brownColor, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/alza.jpg', // Ganti dengan path file Anda
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

                  // Garis pemisah sebelum Card
                  const Divider(height: 1, color: Colors.grey),
                  const SizedBox(height: 20),

                  // 5. Username User yang Login
                  Text(
                    'Username: $_userName',
                    style: TextStyle(
                      fontSize: 16,
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Card Kesan dan Saran
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
                    const Text('Tolong dikasih deadline yg lebih panjang.'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 6. Konversi Waktu (Dropdown API)
            Text(
              'Konversi Waktu (4 Zona):',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: brownColor,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _currentTimezoneDisplay,
                  items: _timeService.timeZones.keys.map((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(key, style: TextStyle(color: brownColor)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _currentTimezoneDisplay = newValue;
                        _updateConvertedTime(
                          _timeService.timeZones[newValue]!,
                        ); // Panggil API
                      });
                    }
                  },
                ),
                Text(
                  _currentConvertedTime,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 7. Tombol Logout (Mengarah ke /login)
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
          ],
        ),
      ),
    );
  }

  // --- Widget 3: Halaman Keranjang ---
  Widget _buildCartPage() {
    return const CartPage();
  }

  @override
  Widget build(BuildContext context) {
    // FIX CACHING: Definisikan list widget di sini, di dalam build()
    final List<Widget> widgetOptions = <Widget>[
      _buildMenuCatalog(),
      _buildProfilePage(),
      _buildCartPage(),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Ikon search di AppBar
            },
          ),
        ],
      ),
      body: widgetOptions.elementAt(_selectedIndex),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'Home',
            backgroundColor: brownColor,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'Profil',
            backgroundColor: brownColor,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart),
            label: 'Keranjang',
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
