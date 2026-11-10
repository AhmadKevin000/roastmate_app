import '../entities/brew_recipe.dart';
import '../entities/brew_tool.dart';

abstract class BrewingRepository {
  /// Mengambil semua metode seduh beserta daftar alat terkait.
  Future<List<BrewMethod>> getMethods();

  /// Mengambil detail satu metode seduh berdasarkan ID.
  Future<BrewMethod?> getMethodById(String methodId);

  /// Mengambil seluruh resep untuk suatu metode seduh.
  Future<List<BrewRecipe>> getRecipesForMethod(String methodId);

  /// Mengambil resep spesifik berdasarkan ID.
  Future<BrewRecipe?> getRecipeById(String recipeId);

  /// Mengambil resep default untuk suatu metode seduh.
  Future<BrewRecipe?> getDefaultRecipe(String methodId);

  /// Mengambil master seluruh alat seduh.
  Future<List<BrewTool>> getAllTools();
}
