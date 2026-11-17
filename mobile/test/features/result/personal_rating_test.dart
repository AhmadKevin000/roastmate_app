// Widget test: kartu Personal Rating pada Detail Inspeksi.
//
// Fokus: pilih bintang, tombol simpan aktif hanya setelah dinilai, dan
// penilaian tersimpan (state lokal sesi) dengan SnackBar konfirmasi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/features/result/presentation/widgets/personal_rating_card.dart';

Widget _host() => ProviderScope(
  child: MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: const PersonalRatingCard(ratingKey: 'Batch #042'),
      ),
    ),
  ),
);

void main() {
  testWidgets('Tombol simpan nonaktif sebelum bintang dipilih', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('Belum dinilai'), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('Pilih 4 bintang lalu simpan penilaian', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    // Tap bintang ke-4 (indeks 3 dari 5 bintang kosong).
    await tester.tap(find.byIcon(Icons.star_border_rounded).at(3));
    await tester.pumpAndSettle();

    expect(find.text('4/5'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);

    await tester.enterText(
      find.byType(TextField),
      'Aroma kuat, aftertaste manis',
    );
    await tester.tap(find.text('Simpan Penilaian'));
    await tester.pumpAndSettle();

    expect(find.text('Penilaian pribadi disimpan'), findsOneWidget);
  });
}
