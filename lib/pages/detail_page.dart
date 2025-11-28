import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item_model.dart';
import '../models/favorite_model.dart';
import '../services/api_service.dart';

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);
const Color darkPrimaryColor = Color.fromARGB(255, 66, 37, 37);
const Color secondaryAccentColor = Color.fromARGB(255, 104, 91, 70);
const Color lightBackgroundColor = Color.fromARGB(255, 231, 222, 206);

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final String currentUserEmail;

  const DetailPage({
    super.key,
    required this.item,
    required this.currentUserEmail,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final ApiService _apiService = ApiService();
  late Future<List<String>> _ingredientsFuture;

  int _quantity = 1;
  late double _itemPrice;
  late double _basePrice; // Harga Satuan
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();

    var priceData = widget.item['price'];

    if (priceData is double) {
      _basePrice = priceData;
    } else if (priceData is int) {
      _basePrice = priceData.toDouble();
    } else if (priceData is num) {
      _basePrice = priceData.toDouble();
    } else {
      _basePrice = 0.0;
    }
    _itemPrice = _basePrice;

    // [UPDATE] Muat jumlah pesanan yang sudah ada di keranjang
    _loadExistingQuantity();

    _checkFavoriteStatus();
    _ingredientsFuture = _apiService.fetchMealDetails(widget.item['idMeal']);
  }

  // [NEW FUNCTION] Muat jumlah yang sudah ada di keranjang
  void _loadExistingQuantity() {
    final cartBox = Hive.box<CartItemModel>('cartBox');
    final idMeal = widget.item['idMeal'];

    final existingItem = cartBox.values.firstWhere(
      (e) => e.idMeal == idMeal && e.userEmail == widget.currentUserEmail,
      orElse: () => CartItemModel(
        idMeal: '',
        strMeal: '',
        strMealThumb: '',
        quantity: 0,
        price: 0.0,
        userEmail: '',
      ),
    );

    if (existingItem.quantity > 0) {
      // Jika ditemukan, set _quantity ke jumlah yang ada di keranjang
      _quantity = existingItem.quantity;
    } else {
      // Jika tidak ditemukan, set ke 1 (nilai default pesanan baru)
      _quantity = 1;
    }
  }

  void _checkFavoriteStatus() {
    if (widget.currentUserEmail.isEmpty) return;

    final favoriteBox = Hive.box<FavoriteModel>('favoriteBox');
    final idMeal = widget.item['idMeal'];

    final isFav = favoriteBox.values.cast<FavoriteModel?>().any(
      (fav) =>
          fav != null &&
          fav.idMeal == idMeal &&
          fav.userEmail == widget.currentUserEmail,
    );

    setState(() {
      _isFavorite = isFav;
    });
  }

  void _toggleFavorite() async {
    if (widget.currentUserEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon login untuk menggunakan fitur favorit.'),
          backgroundColor: darkPrimaryColor,
        ),
      );
      return;
    }

    final favoriteBox = Hive.box<FavoriteModel>('favoriteBox');
    final idMeal = widget.item['idMeal'] ?? UniqueKey().toString();

    final existingKey = favoriteBox.keys.cast<int?>().firstWhere((key) {
      final fav = favoriteBox.get(key);
      return fav != null &&
          fav.idMeal == idMeal &&
          fav.userEmail == widget.currentUserEmail;
    }, orElse: () => null);

    if (_isFavorite && existingKey != null) {
      await favoriteBox.delete(existingKey);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.item['strMeal']} dihapus dari Favorit.'),
          backgroundColor: darkPrimaryColor,
        ),
      );
    } else {
      final newItem = FavoriteModel(
        idMeal: idMeal,
        strMeal: widget.item['strMeal'] ?? 'Unknown Item',
        strMealThumb: widget.item['strMealThumb'] ?? '',
        price: _basePrice,
        userEmail: widget.currentUserEmail,
      );
      await favoriteBox.add(newItem);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.item['strMeal']} ditambahkan ke Favorit!'),
          backgroundColor: darkPrimaryColor,
        ),
      );
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _addToCart() async {
    final cartBox = Hive.box<CartItemModel>('cartBox');

    final newItem = CartItemModel(
      idMeal: widget.item['idMeal'] ?? UniqueKey().toString(),
      strMeal: widget.item['strMeal'] ?? 'Unknown Item',
      strMealThumb: widget.item['strMealThumb'] ?? '',
      quantity: _quantity,
      price: _basePrice, // Menggunakan _basePrice (harga satuan)
      userEmail: widget.currentUserEmail,
    );

    // Dapatkan item yang sudah ada, menggunakan pencarian langsung di values (HiveObject)
    final existingItem = cartBox.values.firstWhere(
      (e) => e.idMeal == newItem.idMeal && e.userEmail == newItem.userEmail,
      orElse: () => CartItemModel(
        idMeal: '',
        strMeal: '',
        strMealThumb: '',
        quantity: 0,
        price: 0.0,
        userEmail: '',
      ),
    );

    if (existingItem.quantity > 0) {
      // Jika item sudah ada, update quantity-nya ke nilai _quantity saat ini
      existingItem.quantity = newItem.quantity;
      await existingItem.save();
    } else {
      // Jika item baru, tambahkan
      await cartBox.add(newItem);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_quantity}x ${newItem.strMeal} ditambahkan ke keranjang!',
        ),
        backgroundColor: darkPrimaryColor,
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: secondaryAccentColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: secondaryAccentColor.withOpacity(0.5)),
      ),
      child: IconButton(
        icon: Icon(icon, color: darkPrimaryColor),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildIngredientText(List<String> ingredients) {
    if (ingredients.isEmpty || ingredients[0].startsWith('Gagal')) {
      return Text(
        'Informasi bahan-bahan tidak tersedia. Menu yang Anda pilih siap disajikan dengan cepat dan nikmat!',
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      );
    }

    final ingredientsList = ingredients.join(', ');
    final fullText =
        'Menu ini disajikan menggunakan ingredient: $ingredientsList. Menu yang Anda pilih siap disajikan dengan cepat dan nikmat!';

    return Text(
      fullText,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isLocalAsset =
        (item['type'] == 'Minuman' &&
        (item['strMealThumb'] as String).startsWith('assets/'));
    final imageUrl = isLocalAsset
        ? item['strMealThumb']
        : item['strMealThumb'] ?? 'https://via.placeholder.com/250';

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            width: double.infinity,
            child: isLocalAsset
                ? Image.asset(imageUrl, fit: BoxFit.cover)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image, size: 80)),
                  ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 249, 245, 241),
                borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['strMeal'] ?? 'Unknown Item',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: darkPrimaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Kategori: ${item['type'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const Divider(height: 30),

                  Text(
                    'Jumlah Pesanan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildQuantityButton(Icons.remove, () {
                        setState(() {
                          if (_quantity > 1) _quantity--;
                        });
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildQuantityButton(Icons.add, () {
                        setState(() {
                          _quantity++;
                        });
                      }),
                    ],
                  ),
                  const Divider(height: 30),

                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: SingleChildScrollView(
                      // Menggunakan FutureBuilder untuk menampilkan ingredients
                      child: FutureBuilder<List<String>>(
                        future: _ingredientsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: darkPrimaryColor,
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return _buildIngredientText([
                              'Gagal memuat bahan-bahan: ${snapshot.error}',
                            ]);
                          } else if (snapshot.hasData) {
                            return _buildIngredientText(snapshot.data!);
                          }
                          return const Text(
                            'Memuat detail menu...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 25.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _addToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shopping_cart,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Add to Cart | Rp ${(_basePrice * _quantity).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
