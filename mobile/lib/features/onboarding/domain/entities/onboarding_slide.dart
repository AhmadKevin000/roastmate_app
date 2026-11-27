import 'package:flutter/material.dart';

/// Jenis slide onboarding yang merepresentasikan 6 pilar fitur utama RoastMate.
enum OnboardingSlideType {
  authOffline,
  cameraScan,
  inspectionRoast,
  dashboardHistory,
  brewRecipes,
  cloudSync,
}

/// Model entitas untuk satu halaman slide pada alur onboarding.
class OnboardingSlide {
  final String id;
  final OnboardingSlideType type;
  final String categoryBadge;
  final String title;
  final String description;
  final List<String> highlights;
  final IconData icon;
  final Color accentColor;

  const OnboardingSlide({
    required this.id,
    required this.type,
    required this.categoryBadge,
    required this.title,
    required this.description,
    required this.highlights,
    required this.icon,
    required this.accentColor,
  });
}
