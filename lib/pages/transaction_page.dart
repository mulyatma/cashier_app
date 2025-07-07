import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 1;

  late Future<List<dynamic>> _menusFuture;
  final Map<String, int> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _menusFuture = fetchMenus();
  }

  Future<List<dynamic>> fetchMenus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.get(
      Uri.parse('https://be-aplikasi-kasir.vercel.app/api/menus'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memuat data menu (${response.statusCode})');
    }
  }

  void _increment(String id) {
    setState(() {
      _selectedItems[id] = (_selectedItems[id] ?? 0) + 1;
    });
  }

  void _decrement(String id) {
    setState(() {
      if ((_selectedItems[id] ?? 0) > 0) {
        _selectedItems[id] = _selectedItems[id]! - 1;
      }
    });
  }

  void _onNavTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        // Halaman transaksi sedang aktif
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/history');
        break;
    }
  }

  void _showPayment(List<dynamic> menus) {
    final selectedMenus = menus
        .where((m) => (_selectedItems[m['_id']] ?? 0) > 0)
        .toList();

    if (selectedMenus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada item yang dipilih')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Ringkasan Pesanan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...selectedMenus.map((menu) {
                final qty = _selectedItems[menu['_id']]!;
                return ListTile(
                  title: Text(menu['name']),
                  subtitle: Text('Rp${menu['price']} x $qty'),
                  trailing: Text(
                    'Rp${menu['price'] * qty}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  final menus = await _menusFuture;

                  final selectedMenus = menus
                      .where((m) => (_selectedItems[m['_id']] ?? 0) > 0)
                      .map(
                        (m) => {
                          "_id": m['_id'],
                          "name": m['name'],
                          "price": m['price'],
                          "quantity": _selectedItems[m['_id']]!,
                        },
                      )
                      .toList();

                  if (selectedMenus.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Belum ada item yang dipilih'),
                      ),
                    );
                    return;
                  }

                  Navigator.pushNamed(
                    context,
                    '/payment',
                    arguments: selectedMenus,
                  );
                },

                child: const Text("Lanjut Pembayaran"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Center(
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Beranda'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('Menu'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/menus');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Transaksi'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Laporan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/reports');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: Image.asset('assets/bg.jpg', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // HEADER atas
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.black),
                            onPressed: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          "Transaksi",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Expanded list menu
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _menusFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Gagal memuat data: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      final menus = snapshot.data!;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: menus.length,
                        itemBuilder: (context, index) {
                          final menu = menus[index];
                          final qty = _selectedItems[menu['_id']] ?? 0;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      menu['image'] ?? '',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                ),
                                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          menu['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rp${menu['price']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            _decrement(menu['_id']),
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                      ),
                                      Text('$qty'),
                                      IconButton(
                                        onPressed: () =>
                                            _increment(menu['_id']),
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // BottomNavigationBar & button tetap di sini
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.white, width: 3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                onPressed: () async {
                  final menus = await _menusFuture;
                  _showPayment(menus);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Lanjut ke Pembayaran',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Icon(Icons.send, color: Colors.green, size: 24),
                  ],
                ),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.green,
                unselectedItemColor: Colors.grey,
                backgroundColor: Colors.white,
                onTap: _onNavTapped,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_cart),
                    label: 'Transaksi',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history),
                    label: 'Riwayat',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
