import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock_brewing.dart';
import '../../../domain/brew_recipe.dart';

/// State katalog seduh (metode + resep).
@immutable
class BrewCatalogState {
  final bool isLoading;
  final List<BrewMethod> methods;
  final List<BrewRecipe> recipes;
  final String? errorMessage;

  const BrewCatalogState({
    this.isLoading = false,
    this.methods = const [],
    this.recipes = const [],
    this.errorMessage,
  });

  bool get isEmpty => methods.isEmpty;

  BrewMethod? methodById(String methodId) {
    for (final method in methods) {
      if (method.methodId == methodId) return method;
    }
    return null;
  }

  /// Resep untuk sebuah metode; utamakan resep umum (`isDefault`).
  BrewRecipe? recipeForMethod(String methodId) {
    for (final recipe in recipes) {
      if (recipe.methodId == methodId && recipe.isDefault) return recipe;
    }
    for (final recipe in recipes) {
      if (recipe.methodId == methodId) return recipe;
    }
    return null;
  }
}

/// ViewModel katalog seduh (MVVM).
///
/// Saat ini memuat data mock. Nanti diisi lewat `BrewingRepository` (SQLite)
/// tanpa mengubah UI (lihat `docs/ARCHITECTURE_MOBILE.md` §5 & §11).
class BrewViewModel extends StateNotifier<BrewCatalogState> {
  BrewViewModel() : super(const BrewCatalogState(isLoading: true)) {
    _load();
  }

  void _load() {
    state = BrewCatalogState(
      methods: mockBrewMethods,
      recipes: mockBrewRecipes,
    );
  }
}

/// Provider katalog seduh.
final brewCatalogProvider =
    StateNotifierProvider<BrewViewModel, BrewCatalogState>((ref) {
  return BrewViewModel();
});

/// Metode berdasarkan id (untuk Detail Resep).
final brewMethodByIdProvider = Provider.family<BrewMethod?, String>((ref, id) {
  return ref.watch(brewCatalogProvider).methodById(id);
});

/// Resep berdasarkan id metode (untuk Detail Resep).
final brewRecipeForMethodProvider =
    Provider.family<BrewRecipe?, String>((ref, id) {
  return ref.watch(brewCatalogProvider).recipeForMethod(id);
});
