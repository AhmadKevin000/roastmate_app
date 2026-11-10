import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pbl_sem5/app/app.dart';
import 'package:pbl_sem5/app/main_shell.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App loads detail screen test', (WidgetTester tester) async {
    // Build our app wrapped with ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: RoastmateApp(),
      ),
    );

    // Verify that the app displays its home page.
    expect(find.byType(MainShell), findsOneWidget);
  });
}
