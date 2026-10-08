import 'package:flutter/material.dart';

import '../features/brew/views/brew_catalog_screen.dart';

/// Host tab "Seduh".
///
/// Isi sebenarnya ada di `features/brew/` (fitur-first). `MainPage` tetap
/// memanggil `BrewPage()`, sehingga `main.dart` & `main_page.dart` tidak perlu
/// diubah.
class BrewPage extends StatelessWidget {
  const BrewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrewCatalogScreen();
  }
}
