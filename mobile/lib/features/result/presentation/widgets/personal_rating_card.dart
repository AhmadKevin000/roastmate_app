import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../../../shared/models/personal_rating.dart';
import '../viewmodels/personal_rating_view_model.dart';

/// Kartu "Penilaian Pribadi Anda" pada Detail Inspeksi.
///
/// Muncul setelah aplikasi menampilkan kualitas biji & rekomendasi seduh.
/// Penilaian (bintang 1–5 + catatan) disimpan sebagai state lokal sesi.
class PersonalRatingCard extends ConsumerStatefulWidget {
  /// Kunci penilaian, biasanya `batchLabel`.
  final String ratingKey;

  const PersonalRatingCard({super.key, required this.ratingKey});

  @override
  ConsumerState<PersonalRatingCard> createState() => _PersonalRatingCardState();
}

class _PersonalRatingCardState extends ConsumerState<PersonalRatingCard> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final saved = ref
        .read(personalRatingProvider.notifier)
        .ratingFor(widget.ratingKey);
    _noteController = TextEditingController(text: saved.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rating = ref.watch(
      personalRatingProvider.select(
        (map) => map[widget.ratingKey] ?? const PersonalRating(),
      ),
    );

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
                final selected = value <= rating.stars;
                return IconButton(
                  onPressed: () => ref
                      .read(personalRatingProvider.notifier)
                      .setStars(widget.ratingKey, value),
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
                rating.hasRating ? '${rating.stars}/5' : 'Belum dinilai',
                style: RoastmateText.labelMd.copyWith(
                  color: rating.hasRating
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
              onPressed: rating.hasRating ? _save : null,
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

  void _save() {
    ref
        .read(personalRatingProvider.notifier)
        .setNote(widget.ratingKey, _noteController.text.trim());
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Penilaian pribadi disimpan')));
  }
}
