import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Path asset template `reason` rekomendasi (12 key `Species|Roast`).
const String kReasonTemplateAsset = 'assets/knowledge/reason_templates.json';

/// Sumber teks `reason` rekomendasi per konteks species × roast.
///
/// Pengganti sementara narasi dari engine ML/LLM: teks statis naratif
/// Indonesia yang nyambung dengan konteks hasil analisis (keputusan desain,
/// `docs/plans` — Plan 1 item 2).
class ReasonTemplateSource {
  const ReasonTemplateSource();

  /// Muat seluruh peta key `Species|Roast` → teks.
  Future<Map<String, String>> loadAll() async {
    final raw = await rootBundle.loadString(kReasonTemplateAsset);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final reasons = data['reasons'] as Map<String, dynamic>;
    return <String, String>{
      for (final e in reasons.entries) e.key: e.value as String,
    };
  }

  /// Teks `reason` untuk pasangan [species] × [roast].
  ///
  /// Fallback generik bila key tak ada (seharusnya tidak pernah terjadi —
  /// test menjamin 12 key persis).
  Future<String> reasonFor(String species, String roast) async {
    final reasons = await loadAll();
    return reasons['$species|$roast'] ??
        'Biji $species (${roast.toLowerCase()} roast) paling aman diseduh dengan '
        'parameter tengah: rasio 1:15, suhu 92 °C, gilingan medium. Haluskan '
        'gilingan bila cup terasa tipis, kasarkan bila terlalu pahit.';
  }
}
