import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

String formatTanggalDanJam(String isoString) {
  final dateTime = DateTime.parse(isoString).toLocal();
  // Pastikan toLocal() supaya sesuai timezone lokal
  return '${dateTime.day} '
      '${_namaBulan(dateTime.month)} '
      '${dateTime.year}, '
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';
}

String _namaBulan(int bulan) {
  const namaBulan = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return namaBulan[bulan];
}

class _HistoryPageState extends State<HistoryPage> {
  DateTimeRange? _selectedRange;
  String? _userRole;

  int _selectedIndex = 2;

  late Future<List<dynamic>> _transactionsFuture;

  String _formatRange(DateTimeRange range) {
    final start = "${range.start.day}-${range.start.month}-${range.start.year}";
    final end = "${range.end.day}-${range.end.month}-${range.end.year}";
    return "$start s/d $end";
  }

  @override
  void initState() {
    super.initState();
    _transactionsFuture = fetchTransactions();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('Role');
    });
  }

  Future<List<dynamic>> fetchTransactions({DateTimeRange? range}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    String url = 'https://be-aplikasi-kasir.vercel.app/api/transactions';
    if (range != null) {
      final start = "${range.start.toIso8601String().split('T')[0]}";
      final end = "${range.end.toIso8601String().split('T')[0]}";
      url += "?startDate=$start&endDate=$end";
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memuat data transaksi (${response.statusCode})');
    }
  }

  void _onNavTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/transactions');
        break;
      case 2:
        // Halaman riwayat aktif
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
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
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Transaksi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/transactions');
              },
            ),
            if (_userRole == 'owner') ...[
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
            ],
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
                              Scaffold.of(context).openDrawer();
                            },
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          "Riwayat Transaksi",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _selectedRange == null
                                ? 'Filter Tanggal'
                                : '${_formatRange(_selectedRange!)}',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                          ),
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange: _selectedRange,
                            );

                            if (picked != null) {
                              setState(() {
                                _selectedRange = picked;
                                _transactionsFuture = fetchTransactions(
                                  range: picked,
                                );
                              });
                            }
                          },
                        ),
                      ),
                      if (_selectedRange != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _selectedRange = null;
                              _transactionsFuture =
                                  fetchTransactions(); // Kembali get all
                            });
                          },
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _transactionsFuture,
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

                      final transactions = snapshot.data!;
                      if (transactions.isEmpty) {
                        return const Center(
                          child: Text(
                            'Belum ada transaksi',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final trx = transactions[index];
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(
                                Icons.receipt_long,
                                color: Colors.green,
                              ),
                              title: Text(
                                formatTanggalDanJam(trx['createdAt']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text('Total: Rp${trx['total']}'),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/transaction-detail',
                                  arguments: {'id': trx['_id']},
                                );
                              },
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
      bottomNavigationBar: ClipRRect(
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
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
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
    );
  }
}
