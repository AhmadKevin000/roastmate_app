import 'package:flutter/material.dart';
import '../../../core/roastmate_colors.dart';

class RoastmateBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const RoastmateBottomNav({Key? key, required this.currentIndex, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: RoastmateColors.surface,
      indicatorColor: RoastmateColors.espressoSoft,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Analisis',
        ),
        NavigationDestination(
          icon: Icon(Icons.coffee_outlined),
          selectedIcon: Icon(Icons.coffee),
          label: 'Seduh',
        ),
      ],
    );
  }
}
