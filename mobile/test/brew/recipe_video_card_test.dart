// Widget test RecipeVideoCard (v6) — jalur tanpa thumbnail (URL tak
// ter-parse) agar `Image.network` tak menyentuh jaringan di test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/features/brew/presentation/widgets/recipe_video_card.dart';

Widget _app(String url) => MaterialApp(
      home: Scaffold(body: RecipeVideoCard(videoUrl: url)),
    );

void main() {
  testWidgets('URL tak dikenal → kartu tampil tanpa thumbnail, tak crash',
      (tester) async {
    await tester.pumpWidget(_app('https://example.com/panduan-seduh'));
    await tester.pumpAndSettle();

    expect(find.text('Video Brewing'), findsOneWidget);
    expect(find.text('Tonton panduan seduh'), findsOneWidget);
    // Fallback ikon — bukan Image.network.
    expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
