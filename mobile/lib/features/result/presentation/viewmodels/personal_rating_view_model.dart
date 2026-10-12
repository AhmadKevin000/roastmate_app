import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/personal_rating.dart';

/// State personal rating per batch (key = `batchLabel`).
///
/// Sesi ini hanya menyimpan di memori (belum ada persistensi SQLite).
class PersonalRatingViewModel
    extends StateNotifier<Map<String, PersonalRating>> {
  PersonalRatingViewModel() : super(const {});

  PersonalRating ratingFor(String key) => state[key] ?? const PersonalRating();

  void setStars(String key, int stars) {
    final current = ratingFor(key);
    state = {...state, key: current.copyWith(stars: stars)};
  }

  void setNote(String key, String note) {
    final current = ratingFor(key);
    state = {...state, key: current.copyWith(note: note)};
  }
}

/// Provider personal rating (state lokal sesi).
final personalRatingProvider =
    StateNotifierProvider<PersonalRatingViewModel, Map<String, PersonalRating>>(
      (ref) => PersonalRatingViewModel(),
    );
