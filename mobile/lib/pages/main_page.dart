import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'brew_page.dart';
import '../data/mock_inspection.dart';
import '../features/analysis/inspection_detail_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    InspectionDetailScreen(
      result: mockInspectionResult,
      initialState: ViewState.content,
    ),
    BrewPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0EB),
          border: const Border(
            top: BorderSide(color: Color(0xFFE8E0D8), width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A382C).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Analisis',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.coffee_outlined),
              activeIcon: Icon(Icons.coffee),
              label: 'Seduh',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF5A382C),
          unselectedItemColor: const Color(0xFF796E66),
          onTap: _onItemTapped,
          backgroundColor: const Color(0xFFF5F0EB),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
