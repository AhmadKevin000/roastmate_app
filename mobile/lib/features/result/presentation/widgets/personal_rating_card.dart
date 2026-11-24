import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../viewmodels/personal_rating_view_model.dart';

/// Kartu "Penilaian Pribadi Anda" pada Detail Inspeksi.
///
/// Penilaian (bintang 1–5 + catatan) disimpan ke baris `analyses` lewat
/// [PersonalRatingViewModel] (v8, D-31) sehingga ikut tampil di kartu Beranda
/// dan Riwayat Analisis. Untuk hasil scan yang belum tersimpan di DB
/// ([analysisId] null) penilaian hanya hidup di state sesi.
class PersonalRatingCard extends ConsumerStatefulWidget {
  /// Kunci penilaian, biasanya `batchLabel`.
  final String ratingKey;

  /// Id baris `analyses`; null bila belum tersimpan (draft hasil scan).
  final int? analysisId;

  /// Nilai awal dari DB (`analyses.personal_rating`); null = belum dinilai.
  final int? initialStars;

  /// Catatan awal dari DB (`analyses.personal_rating_note`).
  final String? initialNote;

  const PersonalRatingCard({
    super.key,
    required this.ratingKey,
    this.analysisId,
    this.initialStars,
    this.initialNote,
  });

  @override
  ConsumerState<PersonalRatingCard> createState() => _PersonalRatingCardState();
}

class _PersonalRatingCardState extends ConsumerState<PersonalRatingCard> {
  late final TextEditingController _noteController;

  /// Bintang aktif di UI: di-seed dari state sesi, lalu dari DB.
  late int _stars;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final session = ref
        .read(personalRatingProvider.notifier)
        .ratingFor(widget.ratingKey);
    _stars = session.hasRating ? session.stars : (widget.initialStars ?? 0);
    _noteController = TextEditingController(
      text: session.hasRating ? session.note : (widget.initialNote ?? ''),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasRating = _stars > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: RoastmateSpacing.lg),
      padding: const EdgeInsets.all(RoastmateSpacing.lg),
      decoration: BoxDecoration(
        color: RoastmateColors.surface,
        borderRadius: BorderRadius.circular(RoastmateRadius.large),
        border: Border.all(color: RoastmateColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.rate_review_outlined,
                size: 16,
                color: RoastmateColors.textSecondary,
              ),
              const SizedBox(width: RoastmateSpacing.sm),
              Flexible(
                child: Text(
                  "PENILAIAN PRIBADI ANDA",
                  style: RoastmateText.labelSm.copyWith(
                    color: RoastmateColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.sm),
          Text(
            "Bagaimana menurut Anda kualitas rasa batch ini?",
            style: RoastmateText.bodyMd.copyWith(
              color: RoastmateColors.textPrimary,
            ),
          ),
          const SizedBox(height: RoastmateSpacing.md),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: RoastmateSpacing.xs,
            runSpacing: RoastmateSpacing.xs,
            children: [
              ...List.generate(5, (index) {
                final value = index + 1;
                final selected = value <= _stars;
                return IconButton(
                  onPressed: () => _selectStars(value),
                  tooltip: '$value bintang',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  icon: Icon(
                    selected ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 32,
                    color: selected
                        ? RoastmateColors.secondary
                        : RoastmateColors.iconMuted,
                  ),
                );
              }),
              const SizedBox(width: RoastmateSpacing.xs),
              Text(
                hasRating ? '$_stars/5' : 'Belum dinilai',
                style: RoastmateText.labelMd.copyWith(
                  color: hasRating
                      ? RoastmateColors.secondary
                      : RoastmateColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.md),
          TextField(
            controller: _noteController,
            maxLines: 3,
            minLines: 2,
            textInputAction: TextInputAction.newline,
            style: RoastmateText.bodyMd.copyWith(
              color: RoastmateColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Catatan opsional (aroma, body, aftertaste)…',
              hintStyle: RoastmateText.bodySm.copyWith(
                color: RoastmateColors.iconMuted,
              ),
              filled: true,
              fillColor: RoastmateColors.surfaceContainer,
              contentPadding: const EdgeInsets.all(RoastmateSpacing.md),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(RoastmateRadius.small),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: RoastmateSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasRating && !_saving ? _save : null,
              icon: const Icon(Icons.check, size: 16),
              label: Text("Simpan Penilaian", style: RoastmateText.labelLg),
              style: ElevatedButton.styleFrom(
                backgroundColor: RoastmateColors.primary,
                foregroundColor: RoastmateColors.surface,
                elevation: 0,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RoastmateRadius.small),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bintang pilihan pengguna: perbarui state UI + cache sesi.
  void _selectStars(int value) {
    setState(() => _stars = value);
    ref.read(personalRatingProvider.notifier).setStars(widget.ratingKey, value);
  }

  Future<void> _save() async {
    final notifier = ref.read(personalRatingProvider.notifier);
    notifier.setNote(widget.ratingKey, _noteController.text.trim());
    FocusScope.of(context).unfocus();

    final analysisId = widget.analysisId;
    if (analysisId == null) {
      // Belum ada baris DB (draft hasil scan): cukup state sesi.
      _showSnack('Penilaian pribadi disimpan');
      return;
    }

    setState(() => _saving = true);
    final saved = await notifier.persist(widget.ratingKey, analysisId);
    if (!mounted) return;
    setState(() => _saving = false);
    _showSnack(
      saved
          ? 'Penilaian pribadi disimpan'
          : 'Penilaian gagal disimpan. Coba lagi.',
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
