// Widget test Detail Resep Kamu (v6) — repository di-fake (tanpa SQLite)
// sehingga FutureProvider resolve deterministik di zona fake-async.
//
// Tampilan video (thumbnail) tak diuji di sini — `Image.network` butuh
// jaringan; jalur non-thumbnail & parser URL tercakup terpisah.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/features/brew/domain/entities/brew_recipe.dart';
import 'package:pbl_sem5/features/brew/domain/entities/brew_tool.dart';
import 'package:pbl_sem5/features/brew/domain/repositories/brewing_repository.dart';
import 'package:pbl_sem5/features/brew/presentation/viewmodels/brew_view_model.dart';
import 'package:pbl_sem5/features/brew/presentation/views/user_recipe_detail_screen.dart';

class _FakeBrewingRepository implements BrewingRepository {
  _FakeBrewingRepository(this._recipe);

  final BrewRecipe? _recipe;

  @override
  Future<List<BrewMethod>> getMethods() async => const [];

  @override
  Future<BrewMethod?> getMethodById(String methodId) async => null;

  @override
  Future<List<BrewRecipe>> getRecipesForMethod(String methodId) async =>
      const [];

  @override
  Future<BrewRecipe?> getRecipeById(String recipeId) async => null;

  @override
  Future<BrewRecipe?> getDefaultRecipe(String methodId) async => null;

  @override
  Future<BrewRecipe?> findDefaultRecipe({
    required String species,
    required String roastContext,
  }) async =>
      null;

  @override
  Future<List<BrewTool>> getAllTools() async => const [];

  @override
  Future<BrewRecipe?> getUserRecipeById(String recipeId) async => _recipe;

  @override
  Future<List<BrewRecipe>> getUserRecipes() async => const [];

  @override
  Future<void> insertUserRecipe(BrewRecipe recipe) async {}

  @override
  Future<void> deleteUserRecipe(String recipeId) async {}
}

Widget _app(BrewRecipe? recipe) {
  return ProviderScope(
    overrides: [
      brewingRepositoryProvider
          .overrideWithValue(_FakeBrewingRepository(recipe)),
    ],
    child: const MaterialApp(
      home: UserRecipeDetailScreen(recipeId: 'U1'),
    ),
  );
}

/// Resep user metode "Lainnya" + 1 langkah + tanpa video (hindari
/// `Image.network` di test).
BrewRecipe _sample() => BrewRecipe(
      recipeId: 'U1',
      name: 'V60 Eksperimen',
      methodId: null,
      methodName: 'AeroPress Homemade',
      species: 'Arabica',
      qualityProfile: 'High',
      roastContext: 'Light',
      doseG: 15,
      waterVolumeMl: 240,
      grindSize: 'Medium-Fine',
      temperatureC: 93,
      brewingTimeS: 170,
      source: 'USER',
      notes: 'Catatan uji',
      steps: const [
        BrewStep(
          stepNo: 1,
          phase: BrewStepPhase.brew,
          title: 'Bloom',
          description: 'Tuang 30 ml, tunggu 30 detik',
          targetTime: '00:30',
        ),
      ],
    );

void main() {
  testWidgets('resep user tampil: nama, chip, langkah, notes', (tester) async {
    await tester.pumpWidget(_app(_sample()));
    await tester.pumpAndSettle();

    expect(find.text('V60 Eksperimen'), findsOneWidget);
    // Chip metode "Lainnya" memakai nama bebas dari form.
    expect(find.text('AeroPress Homemade'), findsOneWidget);
    expect(find.text('Arabica'), findsOneWidget);
    // Langkah seduh (BrewingStepList).
    expect(find.text('Panduan Langkah'), findsOneWidget);
    expect(find.text('Bloom'), findsOneWidget);
    // Notes di TastingNotesCard.
    expect(find.text('Catatan uji'), findsOneWidget);
    // Tanpa video → tidak ada kartu video.
    expect(find.text('Video Brewing'), findsNothing);
  });

  testWidgets('resep tak ditemukan → empty state', (tester) async {
    await tester.pumpWidget(_app(null));
    await tester.pumpAndSettle();

    expect(find.text('Resep tidak ditemukan.'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
  });
}
