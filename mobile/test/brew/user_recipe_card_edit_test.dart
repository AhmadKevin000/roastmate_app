import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/features/brew/domain/entities/brew_recipe.dart';
import 'package:pbl_sem5/features/brew/presentation/widgets/user_recipe_card.dart';

void main() {
  final sampleRecipe = BrewRecipe(
    recipeId: 'U1',
    name: 'Resep Uji Edit',
    methodId: null,
    methodName: 'V60 Custom',
    species: 'Arabica',
    qualityProfile: 'High',
    roastContext: 'Light',
    source: 'USER',
  );

  testWidgets('UserRecipeCard menampilkan tombol edit dan tombol hapus',
      (tester) async {
    var editTapped = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: UserRecipeCard(
              recipe: sampleRecipe,
              onEdit: () => editTapped = true,
            ),
          ),
        ),
      ),
    );

    // Memastikan tombol edit dan hapus keduanya ada di dalam card
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    // Menekan tombol edit memicu aksi edit
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();

    expect(editTapped, isTrue);
  });
}
