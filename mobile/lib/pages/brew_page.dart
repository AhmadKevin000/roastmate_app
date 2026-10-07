import 'package:flutter/material.dart';

class BrewPage extends StatelessWidget {
  const BrewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seduh', style: TextStyle(color: Color(0xFF422E26), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Halaman Seduh (Belum Tersedia)',
          style: TextStyle(color: Color(0xFF422E26), fontSize: 16),
        ),
      ),
    );
  }
}
