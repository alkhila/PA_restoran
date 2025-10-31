import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _menuFuture = _apiService.fetchMenu();
  }

  // Session Management: Memuat nama user dari Hive
  void _loadUserInfo() async {
    final sessionBox = Hive.box('sessionBox');
    setState(() {
      _userName = sessionBox.get('userName') ?? 'FastFoodie';
    });
  }

  // Session Management: Logout menggunakan Hive
  void _logout() async {
    final sessionBox = Hive.box('sessionBox');
    // Hapus data session
    await sessionBox.put('isLoggedIn', false);
    await sessionBox.delete('userName');

    // Kembali ke halaman login dan hapus rute sebelumnya
    Navigator.of(context).pushReplacementNamed('/');
  }

  // Daftar Widget untuk Body Bottom Navigation Bar
  late final List<Widget> _widgetOptions = <Widget>[
    _buildMenuCatalog(),
    _buildProfilePage(),
    _buildCartPage(),
  ];

  // Widget untuk menampilkan Katalog Menu
  Widget _buildMenuCatalog() {
    final brownColor = const Color(0xFF4E342E);

    return FutureBuilder<List<dynamic>>(
      future: _menuFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFB300)),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: brownColor),
            ),
          );
        } else if (snapshot.hasData) {
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
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        child: Image.network(
                          item['img'] ?? 'https://via.placeholder.com/150',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Icon(Icons.broken_image, size: 50),
                              ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        item['name'] ?? 'Nama Menu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: brownColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                      child: Text(
                        'Rp ${item['price']?.toString() ?? '?.?'}',
                        style: const TextStyle(
                          color: Color(0xFFFFB300),
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
          return const Center(child: Text('Tidak ada menu yang tersedia.'));
        }
      },
    );
  }

  // Widget untuk halaman Profil sesuai Syarat Tugas (Minimalis)
  Widget _buildProfilePage() {
    final brownColor = const Color(0xFF4E342E);
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
                  backgroundColor: const Color(0xFFFFB300),
                  child: Text(
                    _userName.substring(0, 1),
                    style: TextStyle(fontSize: 40, color: brownColor),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: brownColor,
                  ),
                ),
                Text(
                  'Pemrograman Aplikasi Mobile',
                  style: TextStyle(color: brownColor.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          const Divider(height: 40),
          Text(
            'Menu Tugas Akhir',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: brownColor,
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.account_balance_wallet,
              color: const Color(0xFFFFB300),
            ),
            title: const Text('Konversi Mata Uang (3 Mata Uang)'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.access_time, color: const Color(0xFFFFB300)),
            title: const Text('Konversi Waktu (WIB, WITA, WIT, London)'),
            onTap: () {},
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

  Widget _buildCartPage() {
    return const Center(child: Text('Halaman Keranjang Anda'));
  }

  @override
  Widget build(BuildContext context) {
    final brownColor = const Color(0xFF4E342E);
    final accentColor = const Color(0xFFFFB300);

    return Scaffold(
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
          // Fasilitas Pencarian (Sesuai Syarat)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fungsi Pencarian dipanggil!')),
              );
            },
          ),
          // Fasilitas Notifikasi (Sesuai Syarat)
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fungsi Notifikasi dipanggil!')),
              );
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),

      // Bottom Navigation Bar (Sesuai Syarat)
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person), // Menu Profil
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: accentColor,
        unselectedItemColor: brownColor.withOpacity(0.5),
        backgroundColor: brownColor, // Background Bottom Nav Bar
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
