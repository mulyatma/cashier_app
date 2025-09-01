import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EditMenuPage extends StatefulWidget {
  final String menuId;

  const EditMenuPage({super.key, required this.menuId});

  @override
  State<EditMenuPage> createState() => _EditMenuPageState();
}

class _EditMenuPageState extends State<EditMenuPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _ingredients = [];
  List<dynamic> _availableStocks = [];

  @override
  void initState() {
    super.initState();
    _fetchStocks().then((_) {
      _fetchMenuDetail();
    });
  }

  Future<void> _fetchStocks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://be-aplikasi-kasir.vercel.app/api/stocks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      setState(() {
        _availableStocks = decoded['data'] ?? []; // ✅ ambil data list
      });
    } else {
      debugPrint("Gagal fetch stocks: ${response.statusCode}");
    }
  }

  Future<void> _fetchMenuDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan. Silakan login ulang.'),
        ),
      );
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    final response = await http.get(
      Uri.parse(
        'https://be-aplikasi-kasir.vercel.app/api/menus/${widget.menuId}',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _nameController.text = data['name'] ?? '';
        _priceController.text = data['price'].toString();
        _descriptionController.text = data['description'] ?? '';
        _ingredients = (data['ingredients'] as List? ?? [])
            .map((ing) {
              final stock = ing['stock'];
              return {
                'stockId': stock is Map
                    ? stock['_id'].toString()
                    : stock.toString(),
                'stockName': stock is Map ? stock['name'] ?? '' : '',
                'quantity': (ing['quantity'] as num).toDouble(),
              };
            })
            .toList()
            .cast<Map<String, dynamic>>();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat detail menu (${response.statusCode})'),
        ),
      );
      Navigator.pop(context);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateMenu() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan. Silakan login ulang.'),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final body = jsonEncode({
      'name': _nameController.text.trim(),
      'price': int.parse(_priceController.text.trim()),
      'description': _descriptionController.text.trim(),
      'ingredients': _ingredients,
    });

    final response = await http.put(
      Uri.parse(
        'https://be-aplikasi-kasir.vercel.app/api/menus/${widget.menuId}',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Menu berhasil diperbarui')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui menu (${response.statusCode})'),
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add({'stockId': null, 'quantity': 1});
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Menu'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Nama Menu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan nama menu',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Nama menu wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Harga',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan harga',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Harga wajib diisi';
                        if (int.tryParse(value) == null)
                          return 'Harga harus berupa angka';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Deskripsi (opsional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan deskripsi menu',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Bahan / Ingredients',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._ingredients.asMap().entries.map((entry) {
                      final index = entry.key;
                      final ingredient = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  value:
                                      _availableStocks.any(
                                        (s) =>
                                            s['_id'].toString() ==
                                            ingredient['stockId'].toString(),
                                      )
                                      ? ingredient['stockId'].toString()
                                      : null,
                                  items: _availableStocks
                                      .map<DropdownMenuItem<String>>((stock) {
                                        return DropdownMenuItem<String>(
                                          value: stock['_id'].toString(),
                                          child: Text(stock['name']),
                                        );
                                      })
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _ingredients[index]['stockId'] = value!;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Bahan',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      value == null ? 'Pilih bahan' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: ingredient['quantity']
                                      .toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Jumlah',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (val) {
                                    _ingredients[index]['quantity'] =
                                        double.tryParse(val) ?? 1.0;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeIngredient(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: _addIngredient,
                      icon: const Icon(Icons.add, color: Colors.green),
                      label: const Text(
                        'Tambah Bahan',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _updateMenu,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.save),
        label: const Text('Simpan'),
      ),
    );
  }
}
