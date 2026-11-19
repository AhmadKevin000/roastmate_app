// Unit test `parseYouTubeVideoId` (v6) — fungsi murni untuk thumbnail
// preview video di RecipeVideoCard.

import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_sem5/features/brew/presentation/widgets/recipe_video_card.dart';

void main() {
  group('parseYouTubeVideoId', () {
    test('youtube.com/watch?v= → id', () {
      expect(
        parseYouTubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('watch?v= dengan parameter tambahan → id tetap terbaca', () {
      expect(
        parseYouTubeVideoId('https://youtu.be/dQw4w9WgXcQ?si=abc&t=10s'),
        'dQw4w9WgXcQ',
      );
    });

    test('youtu.be/ → id', () {
      expect(parseYouTubeVideoId('https://youtu.be/abcdefghijk'), 'abcdefghijk');
    });

    test('/shorts/ → id', () {
      expect(
        parseYouTubeVideoId('https://youtube.com/shorts/abcdefghijk'),
        'abcdefghijk',
      );
    });

    test('/live/ → id', () {
      expect(
        parseYouTubeVideoId('https://youtube.com/live/abcdefghijk'),
        'abcdefghijk',
      );
    });

    test('/embed/ → id', () {
      expect(
        parseYouTubeVideoId('https://youtube.com/embed/abcdefghijk'),
        'abcdefghijk',
      );
    });

    test('id mentah 11 karakter → id', () {
      expect(parseYouTubeVideoId('abcdefghijk'), 'abcdefghijk');
    });

    test('whitespace di pinggir → tetap terbaca', () {
      expect(
        parseYouTubeVideoId('  https://youtu.be/abcdefghijk  '),
        'abcdefghijk',
      );
    });

    test('URL non-YouTube → null', () {
      expect(parseYouTubeVideoId('https://example.com/video'), isNull);
    });

    test('string kosong → null', () {
      expect(parseYouTubeVideoId(''), isNull);
    });
  });
}
