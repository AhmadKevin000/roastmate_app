// Uji `ReasonTemplateSource` — 12 key `Species|Roast` persis, non-empty,
// dan fallback `reasonFor` aman untuk key tak dikenal.

import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/features/analysis/data/sources/reason_template_source.dart';

const Set<String> _expectedKeys = {
  'Arabica|Light',
  'Arabica|Medium',
  'Arabica|Dark',
  'Robusta|Light',
  'Robusta|Medium',
  'Robusta|Dark',
  'Liberika|Light',
  'Liberika|Medium',
  'Liberika|Dark',
  'Mixed|Light',
  'Mixed|Medium',
  'Mixed|Dark',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReasonTemplateSource', () {
    test('memuat tepat 12 key Species|Roast, semua non-empty', () async {
      final reasons = await ReasonTemplateSource().loadAll();
      expect(reasons.keys.toSet(), _expectedKeys);
      for (final text in reasons.values) {
        expect(text.trim(), isNotEmpty);
      }
    });

    test('reasonFor mengembalikan teks sesuai konteks key', () async {
      final text = await ReasonTemplateSource().reasonFor('Arabica', 'Light');
      expect(text, contains('Arabica'));
      expect(text, contains('Light'));
    });

    test('reasonFor jatuh ke fallback non-kosong untuk key tak dikenal',
        () async {
      final text = await ReasonTemplateSource().reasonFor('Xyz', 'Medium');
      expect(text.trim(), isNotEmpty);
    });
  });
}
