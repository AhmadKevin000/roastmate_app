/// Pemetaan best-effort nama metode pada rekomendasi ke `methodId` katalog.
///
/// Rekomendasi engine memakai nama bebas (mis. `"Pour Over (V60) — Clean &
/// Bright"`), sedangkan katalog seduh memakai `methodId` tetap (`M001`..).
/// Helper ini mencocokkan lewat kata kunci. Bila tidak ada yang cocok,
/// kembalikan `null` (CTA detail resep dinonaktifkan).
String? resolveMethodId(String methodName) {
  final needle = methodName.toLowerCase();
  for (final entry in _keywordToMethodId.entries) {
    for (final keyword in entry.value) {
      if (needle.contains(keyword)) return entry.key;
    }
  }
  return null;
}

const Map<String, List<String>> _keywordToMethodId = {
  'M001': ['v60', 'pour over', 'pour-over', 'drip'],
  'M002': ['french press', 'immersion', 'plunger'],
  'M003': ['tubruk', 'tradisional'],
};
