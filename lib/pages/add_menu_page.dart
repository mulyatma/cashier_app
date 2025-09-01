import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddMenuPage extends StatefulWidget {
  const AddMenuPage({super.key});

  @override
  State<AddMenuPage> createState() => _AddMenuPageState();
}

class _AddMenuPageState extends State<AddMenuPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _ingredients = [];
  List<dynamic> _stocks = [];

  File? _selectedImage;
  bool _isLoading = false;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchStocks();
  }

  Future<void> _fetchStocks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final response = await http.get(
      Uri.parse("https://be-aplikasi-kasir.vercel.app/api/stocks"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      setState(() {
        _stocks = decoded['data'];
      });
    } else {
      throw Exception("Failed to load stocks");
    }
  }

  void _showAddIngredientDialog() {
    String? selectedStockId;
    final TextEditingController qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Tambah Bahan Baku"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStockId,
                    hint: const Text("Pilih Bahan Baku"),
                    items: _stocks.map<DropdownMenuItem<String>>((stock) {
                      return DropdownMenuItem<String>(
                        value: stock['_id'],
                        child: Text("${stock['name']} (${stock['unit']})"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedStockId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyController,
                    decoration: const InputDecoration(
                      labelText: "Jumlah",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Batal"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text("Tambah"),
                  onPressed: () {
                    if (selectedStockId != null &&
                        qtyController.text.isNotEmpty) {
                      setState(() {
                        _ingredients.add({
                          'stockId': selectedStockId,
                          'quantity': double.parse(qtyController.text),
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveMenu() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        throw Exception("Token tidak ditemukan. Silakan login ulang.");
      }

      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = "https://contoh.com/path-to-uploaded-image.jpg";
      }

      final response = await http.post(
        Uri.parse('https://be-aplikasi-kasir.vercel.app/api/menus'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'description': _descriptionController.text.trim(),
          if (imageUrl != null) 'image': imageUrl,
          'ingredients': _ingredients
              .map((i) => {'stock': i['stockId'], 'quantity': i['quantity']})
              .toList(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu berhasil ditambahkan')),
        );
        Navigator.pop(context);
      } else {
        throw Exception(data['message'] ?? 'Gagal menambah menu');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Menu'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Nama Menu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama menu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama menu wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Harga',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                  if (value == null || value.isEmpty) {
                    return 'Harga wajib diisi';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Harga harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Deskripsi (opsional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan deskripsi menu',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Gambar (opsional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Pilih Gambar',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Resep (Ingredients)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Column(
                children: _ingredients.map((ing) {
                  dynamic stock;
                  try {
                    stock = _stocks.firstWhere(
                      (s) => s['_id'] == ing['stockId'],
                    );
                  } catch (e) {
                    stock = null;
                  }
                  return ListTile(
                    title: Text(stock != null ? stock['name'] : 'Unknown'),
                    subtitle: Text(
                      'Jumlah: ${ing['quantity']} ${stock?['unit'] ?? ''}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _ingredients.remove(ing);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _stocks.isEmpty
                    ? null
                    : () => _showAddIngredientDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Tambah Bahan Baku"),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveMenu,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Simpan Menu', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}
