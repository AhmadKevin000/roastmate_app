import 'package:flutter/material.dart';

class RoastmateColors {
  static const primary = Color(0xFF5A382C);
  static const espressoDark = Color(0xFF3D251D);
  static const espressoSoft = Color(0xFFF0DED4);

  static const secondary = Color(0xFF8B5E3C);
  static const terracottaSoft = Color(0xFFF2E2D5);

  static const tertiary = Color(0xFF5E6B4A);

  static const background = Color(0xFFF7F3EE);
  static const surface = Color(0xFFFFFDF9);
  static const surfaceContainer = Color(0xFFF2ECE6);
  static const surfaceInverse = Color(0xFF2B2421);

  static const textPrimary = Color(0xFF211A17);
  static const textSecondary = Color(0xFF625850);

  static const borderDefault = Color(0xFFD9CDC4);
  static const borderStrong = Color(0xFF806F65);

  static const iconDefault = Color(0xFF4E433D);
  static const iconMuted = Color(0xFF887B72);

  static const statusInfo = Color(0xFF496574);
  static const statusInfoContainer = Color(0xFFDCE8ED);
  static const error = Color(0xFFB3261E);
  static const statusError = Color(0xFFB3261E);
  static const statusErrorContainer = Color(0xFFF9DEDC);
  static const statusSuccess = Color(0xFF3F6B4A);
  static const statusWarning = Color(0xFFC49038);

  static const Map<String, Color> defect = {
    'normal': Color(0xFF5E6B4A),
    'quaker': Color(0xFFC49038),
    'broken': Color(0xFF9B6A3D),
    'severe': Color(0xFFB54A43),
  };

  static const Map<String, Map<String, Color>> grade = {
    'specialty': {'color': Color(0xFF3F6B4A), 'container': Color(0xFFE0EADF)},
    'premium': {'color': Color(0xFF496574), 'container': Color(0xFFDCE8ED)},
    'standard': {'color': Color(0xFF8B5E00), 'container': Color(0xFFF8E5B5)},
    'belowStandard': {
      'color': Color(0xFFA85E32),
      'container': Color(0xFFF4DFD1),
    },
    'offGrade': {'color': Color(0xFFB3261E), 'container': Color(0xFFF9DEDC)},
  };
}
