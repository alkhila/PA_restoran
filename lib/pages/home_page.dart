// File: lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
// Import halaman-halaman baru
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

  // State untuk Search dan Filter
  String _searchQuery = '';
  MenuFilter _currentFilter = MenuFilter.all;

  // Hapus deklarasi _widgetOptions dari sini (Inisialisasi dilakukan di build())

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

    // Kembali ke root dan hapus stack untuk memaksa login
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }

  // --- Widget 1: Katalog Menu (FIX CACHING & Fungsionalitas) ---
  Widget _buildMenuCatalog() {
    return Column(
      children: [
        // --- Search Bar ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value; // Mengubah state search
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

                  // Pengecekan Search
                  final String itemName =
                      itemMap['strMeal']?.toLowerCase() ?? '';
                  final bool matchesSearch = itemName.contains(
                    _searchQuery.toLowerCase(),
                  );

                  // Pengecekan Filter
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
                                // Navigasi ke Detail Menu
                                icon: Icon(
                                  Icons.add_shopping_cart,
                                  color: brownColor,
                                ),
                                onPressed: () {
                                  // Navigasi ke DetailPage (Membawa data item)
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

  // --- Widget 2: Halaman Profil ---
  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: accentColor,
                  child: Text(
                    _userName.substring(0, 1),
                    style: const TextStyle(fontSize: 40, color: brownColor),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: brownColor,
                  ),
                ),
                Text(
                  'Mahasiswa Pemrograman Aplikasi Mobile',
                  style: TextStyle(color: brownColor.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          const Divider(height: 40),
          const Text(
            'Menu Profil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: brownColor,
            ),
          ),

          // Menu Wajib Tugas Akhir
          ListTile(
            leading: const Icon(Icons.menu_book, color: accentColor),
            title: const Text('Materi Kuliah (Contoh menu tugas)'),
            onTap: () {
              /* TODO: Navigasi ke Materi */
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.account_balance_wallet,
              color: accentColor,
            ),
            title: const Text('Konversi Mata Uang (min. 3 mata uang)'),
            onTap: () {
              /* TODO: Navigasi ke Konversi Mata Uang */
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time, color: accentColor),
            title: const Text('Konversi Waktu (WIB, WITA, WIT, London)'),
            onTap: () {
              /* TODO: Navigasi ke Konversi Waktu */
            },
          ),

          const Spacer(),
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
    );
  }

  // --- Widget 3: Halaman Keranjang ---
  Widget _buildCartPage() {
    // Navigasi ke CartPage yang sebenarnya
    return const CartPage();
  }

  @override
  Widget build(BuildContext context) {
    // FIX CACHING: Definisikan list widget di sini, di dalam build()
    final List<Widget> widgetOptions = <Widget>[
      _buildMenuCatalog(), // Index 0: Memastikan selalu di-rebuild
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
              // Ikon search di AppBar kini menjadi bagian dari visual Home Menu
            },
          ),
        ],
      ),
      body: widgetOptions.elementAt(
        _selectedIndex,
      ), // Menggunakan list yang baru
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
