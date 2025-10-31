import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// --- DEFINISI WARNA (Konstanta Desain Coklat) ---
const Color brownColor = Color(0xFF4E342E); // Coklat Tua
const Color accentColor = Color(0xFFFFB300); // Oranye Aksen

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

  // DEKLARASI WIDGET OPTIONS (Diinisialisasi secara langsung/eager initialization)
  // Perbaikan agar 'late' tidak menimbulkan error inisialisasi.
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _menuFuture = _apiService.fetchMenu();

    // INISIALISASI _widgetOptions di dalam initState
    _widgetOptions = <Widget>[
      _buildMenuCatalog(),
      _buildProfilePage(),
      _buildCartPage(),
    ];
  }

  // --- Session Management ---
  void _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'FastFoodie';
    });
  }

  // Fungsi Logout (Memperbaiki Alur Navigasi ke Login)
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    // Navigasi ke root route ('/') dan HAPUS SEMUA route di stack.
    // Ini memaksa FutureBuilder di main.dart berjalan ulang dan menampilkan LoginPage.
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }

  // --- Widget 1: Katalog Menu (TheMealDB) ---
  Widget _buildMenuCatalog() {
    return FutureBuilder<List<dynamic>>(
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
          final menuList = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: menuList.length,
            itemBuilder: (context, index) {
              final item = menuList[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar Menu (Kunci TheMealDB: 'strMealThumb')
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        child: Image.network(
                          item['strMealThumb'] ??
                              'https://via.placeholder.com/150',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
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
                        item['strMeal'] ??
                            'Nama Menu', // Kunci TheMealDB: 'strMeal'
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: brownColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                        child: Icon(Icons.add_shopping_cart, color: brownColor),
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
    );
  }

  // --- Widget 2: Halaman Profil (Sesuai Syarat Tugas Akhir) ---
  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                //
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
    return Center(
      child: Text(
        'Halaman Keranjang Anda',
        style: TextStyle(color: brownColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Fasilitas Pencarian
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              /* TODO */
            },
          ),
          // Fasilitas Notifikasi
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              /* TODO */
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),

      // Bottom Navigation Bar (Sesuai Syarat)
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
