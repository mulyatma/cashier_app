import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _amountPaidController = TextEditingController();
  int total = 0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items =
        ModalRoute.of(context)!.settings.arguments
            as List<Map<String, dynamic>>;

    total = items
        .fold<num>(0, (sum, item) => sum + (item['price'] * item['quantity']))
        .toInt();

    final int amountPaid =
        int.tryParse(_amountPaidController.text.replaceAll('.', '')) ?? 0;
    final int kembalian = amountPaid - total;

    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Pembayaran'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(item['name']),
                      subtitle: Text(
                        'Rp${item['price']} x ${item['quantity']}',
                      ),
                      trailing: Text(
                        'Rp${item['price'] * item['quantity']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Jumlah Bayar',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _amountPaidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                hintText: 'Masukkan jumlah bayar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: Rp$total',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  'Kembalian: Rp${kembalian < 0 ? 0 : kembalian}',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (amountPaid < total) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Jumlah bayar kurang dari total'),
                          ),
                        );
                        return;
                      }

                      setState(() => _isSubmitting = true);

                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('token');

                      if (token == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Token tidak ditemukan. Silakan login ulang.',
                            ),
                          ),
                        );
                        setState(() => _isSubmitting = false);
                        return;
                      }

                      final body = {
                        "items": items.map((item) {
                          return {
                            "menu": item['_id'],
                            "quantity": item['quantity'],
                          };
                        }).toList(),
                        "amountPaid": amountPaid,
                      };

                      final response = await http.post(
                        Uri.parse(
                          'https://be-aplikasi-kasir.vercel.app/api/transactions',
                        ),
                        headers: {
                          'Content-Type': 'application/json',
                          'Authorization': 'Bearer $token',
                        },
                        body: jsonEncode(body),
                      );

                      setState(() => _isSubmitting = false);

                      if (response.statusCode == 201 ||
                          response.statusCode == 200) {
                        final data = jsonDecode(response.body);
                        final transactionId = data['transaction']['_id'];

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Pembayaran Berhasil'),
                            content: Text(
                              'Kembalian: Rp${data['transaction']['change']}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Tutup dialog
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/transaction-detail',
                                    arguments: {
                                      'id': transactionId,
                                      'isFromPayment': true,
                                    },
                                  );
                                },
                                child: const Text('Lihat Detail'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Gagal menyimpan transaksi (${response.statusCode})',
                            ),
                          ),
                        );
                      }
                    },
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Konfirmasi Pembayaran',
                      style: TextStyle(color: Colors.green),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
