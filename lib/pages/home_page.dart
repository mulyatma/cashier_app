import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Beranda Kasir")),
      body: Center(child: Text("Selamat datang di Aplikasi Kasir!")),
    );
  }
}
