import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';

/// Parse ID video YouTube dari format URL umum:
/// `watch?v=`, `youtu.be/`, `/shorts/`, `/live/`, `/embed/`, atau ID
/// mentah (11 karakter). Null bila tidak dikenali.
String? parseYouTubeVideoId(String url) {
  final t = url.trim();
  final m = RegExp(
    r'(?:youtube\.com/(?:watch\?v=|shorts/|live/|embed/)|youtu\.be/)'
    r'([A-Za-z0-9_-]{6,11})',
  ).firstMatch(t);
  if (m != null) return m.group(1);
  if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(t)) return t;
  return null;
}

/// Kartu video YouTube pada Detail Resep (preview cara seduh) — thumbnail
/// + tombol buka aplikasi YouTube (tanpa player embed, D-v6).
class RecipeVideoCard extends StatelessWidget {
  final String videoUrl;

  const RecipeVideoCard({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    final id = parseYouTubeVideoId(videoUrl);

    return Container(
      decoration: BoxDecoration(
        color: RoastmateColors.surface,
        borderRadius: BorderRadius.circular(RoastmateRadius.large),
        border: Border.all(color: RoastmateColors.borderDefault),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(RoastmateRadius.large),
        child: InkWell(
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.all(RoastmateSpacing.lg),
            child: Row(
              children: [
                if (id != null)
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(RoastmateRadius.small),
                    child: SizedBox(
                      width: 104,
                      height: 58,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            'https://i.ytimg.com/vi/$id/hqdefault.jpg',
                            fit: BoxFit.cover,
                          ),
                          const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              size: 30,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: 104,
                    height: 58,
                    decoration: BoxDecoration(
                      color: RoastmateColors.espressoSoft,
                      borderRadius:
                          BorderRadius.circular(RoastmateRadius.small),
                    ),
                    child: const Icon(
                      Icons.videocam_outlined,
                      color: RoastmateColors.primary,
                    ),
                  ),
                const SizedBox(width: RoastmateSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video Brewing',
                        style: RoastmateText.titleSm.copyWith(
                          color: RoastmateColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tonton panduan seduh',
                        style: RoastmateText.bodySm.copyWith(
                          color: RoastmateColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.play_arrow_rounded,
                  color: RoastmateColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(videoUrl.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Tautan video tidak valid')),
      );
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        messenger.showSnackBar(
          SnackBar(content: Text('Gagal membuka tautan: $uri')),
        );
      }
    } on Exception {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal membuka tautan: $uri')),
      );
    }
  }
}
