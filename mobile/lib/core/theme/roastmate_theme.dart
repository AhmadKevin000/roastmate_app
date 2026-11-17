import 'package:flutter/material.dart';
import 'roastmate_colors.dart';

final roastmateTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: RoastmateColors.primary,
    primary: RoastmateColors.primary,
    secondary: RoastmateColors.secondary,
    tertiary: RoastmateColors.tertiary,
    surface: RoastmateColors.surface,
  ),
  scaffoldBackgroundColor: RoastmateColors.background,
  useMaterial3: true,
  fontFamily: 'Inter',
);
