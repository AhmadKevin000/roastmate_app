import 'package:flutter/material.dart';
import 'core/roastmate_theme.dart';
import 'data/mock_inspection.dart';
import 'features/analysis/inspection_detail_screen.dart';

void main() {
  runApp(const RoastmateApp());
}

class RoastmateApp extends StatelessWidget {
  const RoastmateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roastmate',
      theme: roastmateTheme,
      debugShowCheckedModeBanner: false,
      home: InspectionDetailScreen(
        result: mockInspectionResult,
        initialState: ViewState.content,
      ),
    );
  }
}
