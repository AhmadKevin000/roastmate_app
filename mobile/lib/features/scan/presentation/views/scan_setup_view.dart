import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../../../core/widgets/roastmate_app_bar.dart';
import '../viewmodels/scan_setup_view_model.dart';

/// Layar setup sebelum scan: mengisi nama jenis biji kopi yang akan dipindai.
///
/// Nama disimpan ke [scanBatchNameProvider] lalu dipakai menimpa `batchName`
/// pada hasil analisis.
class ScanSetupView extends ConsumerStatefulWidget {
  const ScanSetupView({super.key});

  @override
  ConsumerState<ScanSetupView> createState() => _ScanSetupViewState();
}

class _ScanSetupViewState extends ConsumerState<ScanSetupView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(scanBatchNameProvider),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(scanBatchNameProvider.notifier).state = _nameController.text
        .trim();
    context.push('/scan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoastmateColors.background,
      appBar: const RoastmateAppBar(title: 'Setup Scan'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(RoastmateSpacing.lg),
                      decoration: BoxDecoration(
                        color: RoastmateColors.surface,
                        borderRadius: BorderRadius.circular(
                          RoastmateRadius.large,
                        ),
                        border: Border.all(
                          color: RoastmateColors.borderDefault,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: RoastmateColors.espressoSoft,
                              borderRadius: BorderRadius.circular(
                                RoastmateRadius.small,
                              ),
                            ),
                            child: const Icon(
                              Icons.coffee_outlined,
                              color: RoastmateColors.primary,
                            ),
                          ),
                          const SizedBox(height: RoastmateSpacing.lg),
                          Text(
                            'Nama Jenis Biji Kopi',
                            style: RoastmateText.titleLg.copyWith(
                              color: RoastmateColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: RoastmateSpacing.xs),
                          Text(
                            'Masukkan nama biji yang akan dipindai. Nama ini akan '
                            'disimpan pada hasil analisis batch.',
                            style: RoastmateText.bodyMd.copyWith(
                              color: RoastmateColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: RoastmateSpacing.lg),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            style: RoastmateText.bodyLg.copyWith(
                              color: RoastmateColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'mis. Mandheling Honey, Gayo Natural',
                              hintStyle: RoastmateText.bodyMd.copyWith(
                                color: RoastmateColors.iconMuted,
                              ),
                              filled: true,
                              fillColor: RoastmateColors.surfaceContainer,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: RoastmateSpacing.lg,
                                vertical: RoastmateSpacing.lg,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  RoastmateRadius.small,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama jenis biji wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: RoastmateSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: Text(
                          'Lanjut ke Kamera',
                          style: RoastmateText.labelLg,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RoastmateColors.primary,
                          foregroundColor: RoastmateColors.surface,
                          elevation: 0,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              RoastmateRadius.small,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
