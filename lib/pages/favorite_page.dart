import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_model.dart';
import 'detail_page.dart';
import 'checkout_detail_page.dart';

const Color darkPrimaryColor = Color.fromARGB(255, 66, 37, 37);
const Color secondaryAccentColor = Color.fromARGB(255, 104, 91, 70);
const Color lightBackgroundColor = Color.fromARGB(255, 231, 222, 206);

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  String _currentUserEmail = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('current_user_email') ?? '';
    });
  }

  void _removeFavorite(dynamic key, String title) async {
    final favoriteBox = Hive.box<FavoriteModel>('favoriteBox');

    await favoriteBox.delete(key);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title berhasil dihapus dari Favorit.'),
        backgroundColor: darkPrimaryColor,
      ),
    );
  }

  void _navigateToDetail(FavoriteModel item) {
    // Memetakan FavoriteModel kembali ke Map<String, dynamic> untuk DetailPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(
          item: {
            'idMeal': item.idMeal,
            'strMeal': item.strMeal,
            'strMealThumb': item.strMealThumb,
            'price': item.price,
            'type': item.strMealThumb.startsWith('assets/')
                ? 'Minuman'
                : 'Makanan',
          },
          currentUserEmail: _currentUserEmail,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserEmail.isEmpty) {
      return Center(
        child: Text(
          'Anda harus login untuk melihat daftar favorit.',
          style: TextStyle(color: darkPrimaryColor, fontSize: 16),
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      // AppBar dipindah ke sini karena ini adalah halaman tab baru
      body: ValueListenableBuilder(
        valueListenable: Hive.box<FavoriteModel>('favoriteBox').listenable(),
        builder: (context, Box<FavoriteModel> box, _) {
          final favorites = box.values
              .where((fav) => fav.userEmail == _currentUserEmail)
              .toList();

          if (favorites.isEmpty) {
            return Center(
              child: Text(
                'Belum ada menu yang ditambahkan ke favorit.',
                textAlign: TextAlign.center,
                style: TextStyle(color: secondaryAccentColor, fontSize: 16),
              ),
            );
          }

          // Menggunakan GridView.builder
          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favoriteItem = favorites[index];
              final itemKey = box.keyAt(
                box.values.toList().indexOf(favoriteItem),
              );

              final isLocalAsset = favoriteItem.strMealThumb.startsWith(
                'assets/',
              );

              return InkWell(
                onTap: () => _navigateToDetail(favoriteItem),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: darkPrimaryColor.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                              child: isLocalAsset
                                  ? Image.asset(
                                      favoriteItem.strMealThumb,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : Image.network(
                                      favoriteItem.strMealThumb,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Center(
                                                child: Icon(Icons.broken_image),
                                              ),
                                    ),
                            ),
                            // Tombol Hapus Favorit di pojok kiri atas
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: () => _removeFavorite(
                                  itemKey,
                                  favoriteItem.strMeal,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            // [UPDATE] Hapus mainAxisAlignment: MainAxisAlignment.spaceBetween
                            children: [
                              Text(
                                favoriteItem.strMeal,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkPrimaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(
                                height: 20,
                              ), // [UPDATE] Tambahkan jarak kecil
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rp ${favoriteItem.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: darkPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox.shrink(),
                                ],
                              ),
                              const Spacer(), // [UPDATE] Mendorong konten ke atas
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
