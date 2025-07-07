import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_menu_page.dart';

class AllMenuPage extends StatefulWidget {
  const AllMenuPage({super.key});

  @override
  State<AllMenuPage> createState() => _AllMenuPageState();
}

class _AllMenuPageState extends State<AllMenuPage> {
  late Future<List<dynamic>> _menusFuture;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Center(
                child: Text(
                  'KasirQu Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Beranda'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('Menu'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/menus');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Transaksi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/transactions');
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
      body: SafeArea(
        child: Column(
          children: [
            // Header dengan tombol menu
            Container(
              color: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'KasirQu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),

            // Konten daftar menu
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _menusFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final menus = snapshot.data!;

                  if (menus.isEmpty) {
                    return const Center(child: Text('Belum ada menu.'));
                  }

                  // Bungkus ListView dengan RefreshIndicator
                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _menusFuture = fetchMenus();
                      });
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                      itemCount: menus.length,
                      itemBuilder: (context, index) {
                        final menu = menus[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditMenuPage(menuId: menu['_id']),
                                ),
                              );
                              // Refresh otomatis setelah kembali dari edit
                              setState(() {
                                _menusFuture = fetchMenus();
                              });
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    menu['image'] ?? '',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 100,
                                              height: 100,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image_not_supported,
                                              ),
                                            ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          menu['name'] ?? 'Tanpa Nama',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rp${menu['price']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if ((menu['description'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          Text(
                                            menu['description'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Menu'),
        onPressed: () {
          Navigator.pushNamed(context, '/add-menu');
        },
      ),
    );
  }
}
