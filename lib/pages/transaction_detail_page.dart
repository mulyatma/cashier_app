import 'package:cashier_app/utils/pdf_receipt.dart';
import 'package:cashier_app/utils/print_receipt.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransactionDetailPage extends StatefulWidget {
  const TransactionDetailPage({super.key});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  late Future<Map<String, dynamic>> _transactionFuture;
  late bool isFromPayment;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final transactionId = args['id'] as String;
    isFromPayment = args['isFromPayment'] == true;

    _transactionFuture = fetchTransactionDetail(transactionId);
  }

  Future<Map<String, dynamic>> fetchTransactionDetail(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.get(
      Uri.parse('https://be-aplikasi-kasir.vercel.app/api/transactions/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memuat detail transaksi (${response.statusCode})');
    }
  }

  String formatTanggalDanJam(String isoDate) {
    final date = DateTime.parse(isoDate);
    return "${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (isFromPayment) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/transactions',
            (route) => false,
          );
          return false; // Mencegah pop default
        }
        return true; // Pop biasa
      },
      child: Scaffold(
        backgroundColor: Colors.green,
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text('Detail Transaksi'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (isFromPayment) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/transactions',
                  (route) => false,
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _transactionFuture,
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

              final trx = snapshot.data!;
              final items = trx['items'] as List<dynamic>;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.black,
                        fontSize: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "KasirQu",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Divider(),
                          Text(
                            "Tanggal: ${formatTanggalDanJam(trx['createdAt'])}",
                          ),
                          Text("ID Transaksi: ${trx['_id']}"),
                          Text("Pelanggan: ${trx['customer'] ?? '-'}"),
                          const Divider(),
                          ...items.map((item) {
                            final menu = item['menu'];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(menu['name'])),
                                  Text(
                                    "${item['quantity']} x ${menu['price']}",
                                  ),
                                  Text("= Rp${item['subtotal']}"),
                                ],
                              ),
                            );
                          }),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total"),
                              Text("Rp${trx['total']}"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Bayar"),
                              Text("Rp${trx['amountPaid']}"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Kembalian"),
                              Text("Rp${trx['change']}"),
                            ],
                          ),
                          const Divider(),
                          Center(
                            child: Text(
                              "Terima kasih telah berbelanja!",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: FutureBuilder<Map<String, dynamic>>(
          future: _transactionFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(); // Jangan tampilkan tombol jika belum ada data
            }
            final trx = snapshot.data!;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: TextButton.icon(
                          onPressed: () async {
                            try {
                              await PdfReceiptService.generateAndSharePdf(trx);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Gagal membagikan: $e")),
                              );
                            }
                          },
                          icon: const Icon(Icons.share, color: Colors.white),
                          label: const Text(
                            "Bagikan PDF",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: TextButton.icon(
                          onPressed: () async {
                            try {
                              await PrintReceiptService.printReceipt(trx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Struk berhasil dicetak"),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Gagal mencetak: $e")),
                              );
                            }
                          },
                          icon: const Icon(Icons.print, color: Colors.white),
                          label: const Text(
                            "Cetak Struk",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
