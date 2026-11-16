import '../../../brew/domain/entities/brew_recipe.dart';
import '../../../brew/domain/repositories/brewing_repository.dart';
import 'analysis_repository.dart';
import 'reason_template_source.dart';

/// Menyatukan resep default knowledge base + template `reason` menjadi
/// [RecommendationRef] siap disimpan ke tabel `recommendations`.
///
/// Ini satu-satunya tempat keputusan "metode + resep mana untuk konteks
/// species × roast" diambil (Plan 1 item 2) — alur scan cukup memanggil
/// [resolve] lalu meneruskan hasilnya ke `AnalysisRepository.insertResult`.
class RecommendationResolver {
  const RecommendationResolver(this._repo, this._reasons);

  final BrewingRepository _repo;
  final ReasonTemplateSource _reasons;

  /// Cari referensi rekomendasi untuk kombinasi [species] × [roast].
  ///
  /// Return null bila KB tidak punya resep default untuk kombinasi itu
  /// (UI memakai fallback tanpa rekomendasi).
  Future<RecommendationRef?> resolve({
    required String species,
    required String roast,
  }) async {
    final recipe =
        await _repo.findDefaultRecipe(species: species, roastContext: roast);
    if (recipe == null) return null;

    final reason = await _reasons.reasonFor(species, roast);

    return RecommendationRef(
      methodId: recipe.methodId,
      recipeId: recipe.recipeId,
      alternativeMethodId: await _alternativeMethodId(recipe),
      reason: reason,
    );
  }

  /// Metode lain (≠ metode resep terpilih) yang punya resep untuk species
  /// yang sama, urutan `method_id` ASC, ambil pertama; null bila tidak ada.
  Future<String?> _alternativeMethodId(BrewRecipe recipe) async {
    final methods = await _repo.getMethods(); // sudah diurut method_id ASC
    for (final method in methods) {
      if (method.methodId == recipe.methodId) continue;
      final recipes = await _repo.getRecipesForMethod(method.methodId);
      if (recipes.any((r) => r.species == recipe.species)) {
        return method.methodId;
      }
    }
    return null;
  }
}
