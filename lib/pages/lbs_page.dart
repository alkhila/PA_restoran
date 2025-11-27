import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

const Color brownColor = Color(0xFF4E342E);
const Color accentColor = Color(0xFFFFB300);
const Color darkPrimaryColor = Color(0xFF703B3B);

// Daftar cabang
final List<Map<String, dynamic>> branches = [
  {
    'name': 'Resto UPN (Pusat)',
    'lat': -7.760166,
    'lon': 110.407981,
    'address': 'Jl. Ringroad Utara, Sleman',
  },
  {
    'name': 'Resto Malioboro',
    'lat': -7.791550,
    'lon': 110.366479,
    'address': 'Jl. Malioboro No.175, Kota Yogyakarta',
  },
  {
    'name': 'Resto Jakal KM 5',
    'lat': -7.765636,
    'lon': 110.384661,
    'address': 'Jl. Kaliurang KM 5, Sleman',
  },
  {
    'name': 'Resto Ring Road Selatan',
    'lat': -7.838426,
    'lon': 110.370500,
    'address': 'Jl. Ring Road Selatan, Bantul',
  },
  {
    'name': 'Resto Wates',
    'lat': -7.842777,
    'lon': 110.155734,
    'address': 'Jl. Wates KM 1, Kulon Progo',
  },
  {
    'name': 'Resto Wonosari',
    'lat': -7.940501,
    'lon': 110.609435,
    'address': 'Jl. Wonosari Raya, Gunung Kidul',
  },
];

class LBSPage extends StatefulWidget {
  const LBSPage({super.key});

  @override
  State<LBSPage> createState() => _LBSPageState();
}

class _LBSPageState extends State<LBSPage> {
  LatLng _userLocation = const LatLng(-7.80, 110.37);
  bool _isLoading = true;
  String _status = 'Mencari lokasi Anda...';
  String _currentAddress = 'Sedang melacak lokasi...';
  bool _isLocating = true;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _trackLocation();
  }

  Future<void> _trackLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
        _status = 'Lokasi ditemukan & peta siap.';
        _currentAddress = address;
        _isLocating = false;
      });
    } catch (e) {
      setState(() {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        _status = 'Gagal mendapatkan lokasi: $errorMsg';
        _currentAddress = 'Error: $errorMsg';
        _isLoading = false;
        _isLocating = false;
      });
    }
  }

  String findNearestBranch() {
    if (_isLoading || _isLocating) return 'Menunggu lokasi...';

    double minDistance = double.infinity;
    String nearestBranchName = 'N/A';

    for (var branch in branches) {
      double distance = Geolocator.distanceBetween(
        _userLocation.latitude,
        _userLocation.longitude,
        branch['lat'] as double,
        branch['lon'] as double,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestBranchName =
            '${branch['name']} (${(minDistance / 1000).toStringAsFixed(2)} km)';
      }
    }

    return nearestBranchName;
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    for (var branch in branches) {
      markers.add(
        Marker(
          width: 100.0,
          height: 100.0,
          point: LatLng(branch['lat'] as double, branch['lon'] as double),
          child: InkWell(
            onTap: () {
              // Hitung jarak saat marker diklik (jika lokasi pengguna sudah ditemukan)
              String distanceText = 'N/A';
              if (!_isLoading && !_isLocating) {
                final double distanceInMeters = Geolocator.distanceBetween(
                  _userLocation.latitude,
                  _userLocation.longitude,
                  branch['lat'] as double,
                  branch['lon'] as double,
                );
                distanceText = (distanceInMeters / 1000).toStringAsFixed(2);
              }

              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                      branch['name'] as String,
                      style: TextStyle(color: darkPrimaryColor),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alamat: ${branch['address']}'),
                        const SizedBox(height: 10),
                        Text('Jarak dari Anda: $distanceText km'),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text(
                          'Tutup',
                          style: TextStyle(color: darkPrimaryColor),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Column(
              children: [
                Icon(Icons.store, color: brownColor, size: 35),
                Text(
                  branch['name'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: brownColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Tambahkan marker untuk lokasi pengguna
    markers.add(
      Marker(
        width: 80.0,
        height: 80.0,
        point: _userLocation,
        child: Icon(Icons.person_pin_circle, color: darkPrimaryColor, size: 40),
      ),
    );

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status Peta
                Text(
                  'Status Peta:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: brownColor,
                  ),
                ),
                Text(
                  _status,
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
                const Divider(height: 20),

                // 2. Lokasi Anda (Detail)
                Text(
                  'Lokasi Anda (Detail):',
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
                        ? darkPrimaryColor
                        : darkPrimaryColor.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.start,
                ),
                const Divider(height: 20),

                // 3. Cabang Terdekat
                Text(
                  'Resto Terdekat:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: brownColor,
                  ),
                ),
                Text(
                  findNearestBranch(),
                  style: TextStyle(
                    fontSize: 20,
                    color: darkPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
              ],
            ),
          ),

          Expanded(
            child: (_isLoading || _isLocating)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: accentColor),
                        const SizedBox(height: 10),
                        Text(
                          _status,
                          style: TextStyle(color: darkPrimaryColor),
                        ),
                      ],
                    ),
                  )
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: _userLocation,
                      initialZoom: 11.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: 'com.example.pa_restoran2',
                      ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
