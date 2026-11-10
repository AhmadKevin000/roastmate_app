import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/brewing_repository_impl.dart';
import '../../domain/entities/brew_recipe.dart';
import '../../domain/repositories/brewing_repository.dart';

/// Provider instance repository brewing.
final brewingRepositoryProvider = Provider<BrewingRepository>((ref) {
  return BrewingRepositoryImpl();
});

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
/// Memuat data dari SQLite via [BrewingRepository].
class BrewViewModel extends StateNotifier<BrewCatalogState> {
  final BrewingRepository _repository;

  BrewViewModel(this._repository) : super(const BrewCatalogState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    state = const BrewCatalogState(isLoading: true);
    try {
      final methods = await _repository.getMethods();
      final List<BrewRecipe> allRecipes = [];
      for (final m in methods) {
        final recipes = await _repository.getRecipesForMethod(m.methodId);
        allRecipes.addAll(recipes);
      }

      state = BrewCatalogState(
        isLoading: false,
        methods: methods,
        recipes: allRecipes,
      );
    } catch (e) {
      state = BrewCatalogState(
        isLoading: false,
        errorMessage: 'Gagal memuat katalog seduh: $e',
      );
    }
  }
}

/// Provider katalog seduh.
final brewCatalogProvider =
    StateNotifierProvider<BrewViewModel, BrewCatalogState>((ref) {
  final repo = ref.watch(brewingRepositoryProvider);
  return BrewViewModel(repo);
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
