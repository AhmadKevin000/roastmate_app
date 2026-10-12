// Widget test: konsistensi header/appbar bersama.
//
// Memastikan header brand dan appbar layar yang di-push memakai komponen core
// dan tidak lagi menampilkan avatar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/core/widgets/roastmate_app_bar.dart';
import 'package:pbl_sem5/core/widgets/roastmate_app_header.dart';

void main() {
  testWidgets('RoastmateAppHeader menampilkan brand + sublabel tanpa avatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RoastmateAppHeader(subtitle: 'Beranda')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Roastmate'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    // Tanpa avatar.
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.byIcon(Icons.person), findsNothing);
  });

  testWidgets(
    'RoastmateAppBar menampilkan judul + tombol kembali tanpa avatar',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(appBar: RoastmateAppBar(title: 'Detail Inspeksi')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detail Inspeksi'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Tanpa avatar.
      expect(find.byType(CircleAvatar), findsNothing);
      expect(find.byIcon(Icons.person), findsNothing);
    },
  );
}
