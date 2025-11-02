// File: lib/pages/home_page.dart (MODIFIED - USER EMAIL & CONFIRM LOGOUT)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'time_converter_page.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'cart_page.dart';
import 'lbs_page.dart';
import 'detail_page.dart';
import '../models/cart_item_model.dart';
import 'login_page.dart';

// --- DEFINISI WARNA ---
const Color darkPrimaryColor = Color(0xFF703B3B);
const Color secondaryAccentColor = Color(0xFFA18D6D);
const Color lightBackgroundColor = Color(0xFFE1D0B3);

enum MenuFilter { all, makanan, minuman }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _userName = 'Pengguna';
  String _currentUserEmail = ''; // State untuk menyimpan email user aktif
  late Future<List<dynamic>> _menuFuture;

  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  final Box<CartItemModel> _cartBox = Hive.box<CartItemModel>('cartBox');

  String _currentAddress = 'Klik Lacak Lokasi';
  bool _isLocating = false;

  String _searchQuery = '';
  MenuFilter _currentFilter = MenuFilter.all;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _menuFuture = _apiService.fetchMenu();
  }

  // --- Session Management & Email Load ---
  void _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'FastFoodie';
      // Load email user yang aktif
      _currentUserEmail = prefs.getString('current_user_email') ?? '';
    });
  }

  // ✅ FUNGSI BARU: Konfirmasi Logout
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Batal',
                style: TextStyle(color: darkPrimaryColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _logout(); // Lanjutkan proses logout
              },
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('current_user_email'); // Hapus email user aktif

    // Navigasi ke halaman login
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  // --- LOGIKA ADD TO CART (Diperbarui untuk Detail Page) ---
  void _openDetailPage(Map<String, dynamic> item) {
    if (_currentUserEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon login terlebih dahulu.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetailPage(item: item, currentUserEmail: _currentUserEmail),
      ),
    );
  }

  // --- LBS Logic (Tetap) ---
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

  // --- Widget 1: Katalog Menu ---
  Widget _buildMenuCatalog() {
    return FutureBuilder<List<dynamic>>(
      future: _menuFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: darkPrimaryColor),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada menu yang tersedia.',
              style: TextStyle(color: darkPrimaryColor),
            ),
          );
        }

        final rawMenuList = snapshot.data!;

        List<dynamic> filteredList = rawMenuList.where((item) {
          final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
          final String itemName = itemMap['strMeal']?.toLowerCase() ?? '';
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

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header Welcome (Tanpa Foto User) ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Selamat Datang,",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              _userName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: darkPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.notifications_none,
                          color: darkPrimaryColor,
                          size: 28,
                        ),
                      ],
                    ),
                  ),

                  // --- Search Bar ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _currentFilter = MenuFilter.all;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Cari menu...",
                        prefixIcon: Icon(
                          Icons.search,
                          color: secondaryAccentColor,
                        ),
                        suffixIcon: Icon(Icons.menu, color: darkPrimaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --- Filter Chips (Kategori) ---
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkPrimaryColor,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children:
                          [
                            _buildFilterChip('Semua', MenuFilter.all),
                            _buildFilterChip('Makanan', MenuFilter.makanan),
                            _buildFilterChip('Minuman', MenuFilter.minuman),
                          ].map((widget) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: widget,
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Judul Grid ---
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, bottom: 10),
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'Hasil Pencarian (${filteredList.length} item)'
                          : 'Semua Menu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkPrimaryColor,
                      ),
                    ),
                  ),

                  // Handle Empty List after filter/search
                  if (_searchQuery.isNotEmpty && filteredList.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Text(
                          'Menu tidak ditemukan untuk "$_searchQuery".',
                          style: TextStyle(color: darkPrimaryColor),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // --- Grid View (Menu Utama) ---
            if (filteredList.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = filteredList[index];
                    return _buildGridItemCard(context, item);
                  }, childCount: filteredList.length),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildGridItemCard(BuildContext context, dynamic item) {
    final isLocalAsset =
        (item['type'] == 'Minuman' &&
        (item['strMealThumb'] as String).startsWith('assets/'));
    final imageUrl = isLocalAsset
        ? item['strMealThumb']
        : item['strMealThumb'] ?? 'https://via.placeholder.com/150';

    return GestureDetector(
      onTap: () => _openDetailPage(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: isLocalAsset
                    ? Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(Icons.broken_image, size: 50),
                            ),
                      ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      item['strMeal'] ?? 'Nama Menu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: darkPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rp ${item['price']?.toStringAsFixed(0) ?? 'N/A'}',
                          style: TextStyle(
                            color: secondaryAccentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        // Tombol add to cart langsung (shortcut ke DetailPage)
                        GestureDetector(
                          onTap: () => _openDetailPage(item),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: darkPrimaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, MenuFilter filter) {
    bool isSelected = _currentFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: darkPrimaryColor,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentFilter = filter;
            _searchQuery = '';
          });
        }
      },
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : darkPrimaryColor,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: lightBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? darkPrimaryColor : secondaryAccentColor,
        ),
      ),
    );
  }

  // --- Widget 2, 3, 4 (Profile, Cart, LBS) ---
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
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: darkPrimaryColor, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/alza.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          size: 60,
                          color: darkPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Alkhila Syadza Fariha / 124230090',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkPrimaryColor,
                    ),
                  ),
                  Text(
                    'Mahasiswa Pemrograman Aplikasi Mobile',
                    style: TextStyle(color: darkPrimaryColor, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Lokasi Saya:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkPrimaryColor,
                    ),
                  ),
                  Text(
                    _currentAddress,
                    style: TextStyle(
                      fontSize: 14,
                      color: _isLocating
                          ? secondaryAccentColor
                          : darkPrimaryColor.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _isLocating ? null : _trackLocation,
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
                      backgroundColor: secondaryAccentColor,
                      foregroundColor: darkPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kesan:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: darkPrimaryColor,
                            ),
                          ),
                          const Text(
                            'Saya sangat berkesan dengan mata kuliah mobile ini.',
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Saran:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: darkPrimaryColor,
                            ),
                          ),
                          const Text(
                            'Tolong dikasih deadline yg lebih panjang.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 40, color: Colors.grey),
                  Text(
                    'Username: $_userName',
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryAccentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Menu Wajib Tugas Akhir:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkPrimaryColor,
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.account_balance_wallet,
                      color: secondaryAccentColor,
                    ),
                    title: const Text('Konversi Mata Uang'),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.access_time,
                      color: secondaryAccentColor,
                    ),
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
                  ElevatedButton.icon(
                    onPressed: _confirmLogout, // Panggil Konfirmasi Logout
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPage() {
    return const CartPage();
  }

  Widget _buildLBSPage() {
    return const LBSPage();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      _buildMenuCatalog(),
      _buildProfilePage(),
      _buildCartPage(),
      _buildLBSPage(),
    ];

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      body: widgetOptions.elementAt(_selectedIndex),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(label: 'Home', icon: Icon(Icons.home)),
          const BottomNavigationBarItem(
            label: 'Person',
            icon: Icon(Icons.person),
          ),
          const BottomNavigationBarItem(
            label: 'Cart',
            icon: Icon(Icons.shopping_cart),
          ),
          const BottomNavigationBarItem(
            label: 'LBS',
            icon: Icon(Icons.location_on),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: darkPrimaryColor,
        unselectedItemColor: secondaryAccentColor,
        backgroundColor: lightBackgroundColor,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
