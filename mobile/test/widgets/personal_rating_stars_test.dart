// Widget test: komponen bintang ringkas penilaian pribadi (v8, D-31).
//
// Dipakai kartu Beranda & card riwayat — harus membedakan belum dinilai
// (5 bintang outline + label redup) dan sudah dinilai (n bintang penuh).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/core/widgets/personal_rating_stars.dart';

Widget _host({int? stars, bool showLabel = true}) => MaterialApp(
  home: Scaffold(
    body: PersonalRatingStars(stars: stars, showLabel: showLabel),
  ),
);

void main() {
  testWidgets('belum dinilai → 5 bintang outline + label "Belum dinilai"', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.text('Belum dinilai'), findsOneWidget);
  });

  testWidgets('4 bintang → 4 penuh + 1 outline + label "4/5"', (tester) async {
    await tester.pumpWidget(_host(stars: 4));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
    expect(find.text('4/5'), findsOneWidget);
  });

  testWidgets('showLabel false → hanya ikon', (tester) async {
    await tester.pumpWidget(_host(stars: 3, showLabel: false));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.text('3/5'), findsNothing);
  });

  testWidgets('nilai di luar rentang tetap aman (0 → semua outline)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(stars: 0));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));
    expect(find.text('Belum dinilai'), findsOneWidget);
  });
}
