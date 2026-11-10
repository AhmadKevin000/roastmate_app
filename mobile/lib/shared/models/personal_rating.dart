/// Penilaian pribadi pengguna terhadap sebuah batch biji kopi.
///
/// Ini penilaian subjektif pengguna (bukan akurasi aplikasi). Disimpan sebagai
/// state lokal sesi (belum dipersistensikan ke database).
class PersonalRating {
  /// Jumlah bintang 0–5. `0` berarti belum dinilai.
  final int stars;

  /// Catatan bebas opsional dari pengguna.
  final String note;

  const PersonalRating({this.stars = 0, this.note = ''});

  bool get hasRating => stars > 0;

  PersonalRating copyWith({int? stars, String? note}) {
    return PersonalRating(stars: stars ?? this.stars, note: note ?? this.note);
  }
}
