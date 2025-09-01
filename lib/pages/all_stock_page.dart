import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AllStockPage extends StatefulWidget {
  const AllStockPage({super.key});

  @override
  State<AllStockPage> createState() => _AllStockPageState();
}

class _AllStockPageState extends State<AllStockPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Future<List<dynamic>> _stocksFuture;
  final Map<String, double> _editedQuantities = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _stocksFuture = fetchStocks();
  }

  Future<List<dynamic>> fetchStocks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.get(
      Uri.parse('https://be-aplikasi-kasir.vercel.app/api/stocks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Gagal memuat data stok (${response.statusCode})');
    }
  }

  void _increment(String id, double current) {
    setState(() {
      _editedQuantities[id] = (current + 0.1);
      _hasChanges = true;
    });
  }

  void _decrement(String id, double current) {
    if (current > 0) {
      setState(() {
        _editedQuantities[id] = (current - 0.1).clamp(0, double.infinity);
        _hasChanges = true;
      });
    }
  }

  Future<void> _deleteStock(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Token tidak ditemukan.')));
      return;
    }

    final response = await http.delete(
      Uri.parse('https://be-aplikasi-kasir.vercel.app/api/stocks/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal menghapus stok')));
    }
  }

  Future<void> _saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Token tidak ditemukan.')));
      return;
    }

    for (final entry in _editedQuantities.entries) {
      final id = entry.key;
      final qty = entry.value;

      final response = await http.put(
        Uri.parse('https://be-aplikasi-kasir.vercel.app/api/stocks/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"quantity": qty}),
      );

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update stok dengan ID $id')),
        );
      }
    }

    setState(() {
      _stocksFuture = fetchStocks();
      _editedQuantities.clear();
      _hasChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perubahan stok berhasil disimpan')),
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
                  'Manajemen Stok',
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
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Transaksi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/transactions');
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
              leading: const Icon(Icons.receipt_long),
              title: const Text('Laporan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/reports');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Karyawan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/employees');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Stok'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/stocks');
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');
                await prefs.remove('Role');

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
                      "Data Stok",
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
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _stocksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Gagal memuat data: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final stocks = snapshot.data!;

                  return RefreshIndicator(
                    color: Colors.green,
                    onRefresh: () async {
                      setState(() {
                        _stocksFuture = fetchStocks();
                        _editedQuantities.clear();
                        _hasChanges = false;
                      });
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: stocks.length,
                      itemBuilder: (context, index) {
                        final stock = stocks[index];
                        final id = stock['_id'];
                        final baseQty = stock['quantity'] ?? 0.toDouble();
                        final qty = _editedQuantities[id] ?? baseQty;

                        return Dismissible(
                          key: Key(id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            // Tampilkan dialog konfirmasi
                            return await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Konfirmasi Hapus'),
                                content: const Text(
                                  'Apakah Anda yakin ingin menghapus stok ini?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            // Panggil API hapus
                            await _deleteStock(id);
                            setState(() {
                              stocks.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Stok berhasil dihapus'),
                              ),
                            );
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          stock['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Satuan: ${stock['unit']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _decrement(id, qty),
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                      ),
                                      Text(qty.toStringAsFixed(1)),
                                      IconButton(
                                        onPressed: () => _increment(id, qty),
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
        label: const Text('Tambah Stok'),
        onPressed: () {
          Navigator.pushNamed(context, '/add-stock');
        },
      ),
      bottomNavigationBar: _hasChanges
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan Perubahan'),
                  onPressed: _saveChanges,
                ),
              ),
            )
          : null,
    );
  }
}
