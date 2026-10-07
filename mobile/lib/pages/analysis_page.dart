import 'package:flutter/material.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis', style: TextStyle(color: Color(0xFF422E26), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Halaman Analisis (Belum Tersedia)',
          style: TextStyle(color: Color(0xFF422E26), fontSize: 16),
        ),
      ),
    );
  }
}
