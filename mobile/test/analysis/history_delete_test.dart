// Test UI hapus riwayat analisis (v6): ikon hapus hanya untuk item DB
// (analysisId terisi), dialog konfirmasi sebelum eksekusi. Eksekusi hapus
// + cascade sudah tercakup di `test/data/analysis_repository_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/features/analysis/data/sources/mock_analysis_history.dart';
import 'package:pbl_sem5/features/analysis/domain/entities/analysis_history_item.dart';
import 'package:pbl_sem5/features/analysis/presentation/views/analysis_history_screen.dart';

Widget _app(List<AnalysisHistoryItem> items) => ProviderScope(
  child: MaterialApp(home: AnalysisHistoryScreen(items: items)),
);

void main() {
  testWidgets('item mock (tanpa analysisId) → tanpa ikon hapus',
      (tester) async {
    await tester.pumpWidget(_app(mockAnalysisHistory));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('item DB (analysisId) → ikon hapus + dialog konfirmasi',
      (tester) async {
    final item = AnalysisHistoryItem(
      dateLabel: '12 Mar 2025, 10:24 WIB',
      detail: mockAnalysisHistory.first.detail.copyWith(analysisId: 7),
    );
    await tester.pumpWidget(_app([item]));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Hapus Analisis?'), findsOneWidget);

    // Batal → dialog tertutup, tak ada aksi hapus.
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus Analisis?'), findsNothing);
  });
}
