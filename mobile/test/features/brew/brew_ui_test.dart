// Widget test fitur Brew (Resep Seduh & Detail Resep).
//
// Mengacu ke `docs/PRD.md` FR-06/FR-07 dan `docs/DECISIONS.md` D-01.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pbl_sem5/features/brew/data/sources/mock_brewing_source.dart';
import 'package:pbl_sem5/features/brew/domain/entities/brew_recipe.dart';
import 'package:pbl_sem5/features/brew/domain/entities/brew_tool.dart';
import 'package:pbl_sem5/features/brew/domain/repositories/brewing_repository.dart';
import 'package:pbl_sem5/features/brew/presentation/viewmodels/brew_view_model.dart';
import 'package:pbl_sem5/features/brew/presentation/views/brew_catalog_screen.dart';
import 'package:pbl_sem5/features/brew/presentation/views/recipe_detail_screen.dart';

class _FakeBrewingRepository implements BrewingRepository {
  @override
  Future<List<BrewMethod>> getMethods() async => mockBrewMethods;

  @override
  Future<BrewMethod?> getMethodById(String methodId) async {
    for (final m in mockBrewMethods) {
      if (m.methodId == methodId) return m;
    }
    return null;
  }

  @override
  Future<List<BrewRecipe>> getRecipesForMethod(String methodId) async {
    return mockBrewRecipes.where((r) => r.methodId == methodId).toList();
  }

  @override
  Future<BrewRecipe?> getRecipeById(String recipeId) async {
    for (final r in mockBrewRecipes) {
      if (r.recipeId == recipeId) return r;
    }
    return null;
  }

  @override
  Future<BrewRecipe?> getDefaultRecipe(String methodId) async {
    for (final r in mockBrewRecipes) {
      if (r.methodId == methodId && r.isDefault) return r;
    }
    return null;
  }

  @override
  Future<List<BrewTool>> getAllTools() async => const [];
}

Widget _app({BrewingRepository? repo}) => ProviderScope(
      overrides: [
        brewingRepositoryProvider.overrideWithValue(repo ?? _FakeBrewingRepository()),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/brewing',
          routes: <RouteBase>[
            GoRoute(
              path: '/brewing',
              builder: (context, state) => const BrewCatalogScreen(),
            ),
            GoRoute(
              path: '/brewing/:methodId',
              builder: (context, state) => RecipeDetailScreen(
                methodId: state.pathParameters['methodId']!,
              ),
            ),
          ],
        ),
      ),
    );

void main() {
  testWidgets('Katalog menampilkan metode beserta parameter (FR-06)',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Katalog Metode Seduh'), findsOneWidget);
    expect(find.text('V60 / Pour Over'), findsOneWidget);
    expect(find.text('French Press'), findsOneWidget);
    expect(find.text('Kopi Tubruk Tradisional'), findsOneWidget);
    expect(find.text('Mulai Setup'), findsNWidgets(3));
  });

  testWidgets('Katalog menampilkan rasio yang dihitung (D-10)', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // 225 ml / 15 g = 1:15
    expect(find.text('1:15'), findsOneWidget);
    // 252 ml / 18 g = 1:14
    expect(find.text('1:14'), findsOneWidget);
    // 180 ml / 15 g = 1:12
    expect(find.text('1:12'), findsOneWidget);
  });

  testWidgets('Mulai Setup membuka Detail Resep lengkap tanpa timer (FR-07, D-01)',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final startButton = find.text('Mulai Setup').first;
    await tester.ensureVisible(startButton);
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    // Ringkasan, persiapan, langkah, dan tips rasa.
    expect(find.text('Berat'), findsOneWidget);
    expect(find.text('Total Air'), findsOneWidget);
    expect(find.text('Persiapan & Alat Seduh'), findsOneWidget);
    expect(find.text('Panduan Langkah'), findsOneWidget);
    expect(find.text('Blooming'), findsOneWidget);
    expect(find.text('Artisan Pro-Tips: Kalibrasi Rasa'), findsOneWidget);

    // D-01: panduan statis — tidak ada kontrol timer interaktif.
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(find.byIcon(Icons.pause), findsNothing);
    expect(find.byIcon(Icons.stop), findsNothing);
  });
}
