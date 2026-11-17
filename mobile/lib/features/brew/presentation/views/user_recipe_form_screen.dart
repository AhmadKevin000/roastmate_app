import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/roastmate_colors.dart';
import '../../../../core/theme/roastmate_radius.dart';
import '../../../../core/theme/roastmate_spacing.dart';
import '../../../../core/theme/roastmate_text.dart';
import '../../../../core/widgets/roastmate_app_bar.dart';
import '../../../../shared/utils/brew_label_helpers.dart';
import '../../domain/entities/brew_recipe.dart';
import '../viewmodels/brew_view_model.dart';

/// Form tambah resep seduh buatan user (Plan 4 — route `/brewing/new`).
///
/// Parameter penuh tanpa langkah seduh (v1). Validasi: nama wajib (≥ 3
/// karakter), dropdown wajib, angka opsional ≥ 0 (suhu 0–100).
class UserRecipeFormScreen extends ConsumerStatefulWidget {
  const UserRecipeFormScreen({super.key});

  @override
  ConsumerState<UserRecipeFormScreen> createState() =>
      _UserRecipeFormScreenState();
}

class _UserRecipeFormScreenState extends ConsumerState<UserRecipeFormScreen> {
  static const _speciesOptions = ['Arabica', 'Robusta', 'Liberika', 'Mixed'];
  static const _roastOptions = [
    'Green',
    'Light',
    'Medium',
    'Dark',
    'Light/Medium',
    'Medium/Dark',
  ];
  static const _profileOptions = ['High', 'Medium', 'Low'];
  static const _grindOptions = [
    'Espresso',
    'Fine',
    'Medium-Fine',
    'Medium',
    'Medium-Coarse',
    'Coarse',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  late final TextEditingController _waterController;
  late final TextEditingController _tempController;
  late final TextEditingController _timeController;
  late final TextEditingController _notesController;

  String _methodId = 'M001';
  String _species = 'Arabica';
  String _roastContext = 'Light';
  String _profile = 'High';
  String? _grind;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _doseController = TextEditingController();
    _waterController = TextEditingController();
    _tempController = TextEditingController();
    _timeController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _waterController.dispose();
    _tempController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? _parseDouble(String text) {
    final t = text.trim();
    return t.isEmpty ? null : double.tryParse(t);
  }

  int? _parseInt(String text) {
    final t = text.trim();
    return t.isEmpty ? null : int.tryParse(t);
  }

  String? _validateWholeNumber(
    String? text, {
    required String label,
    int? max,
  }) {
    final t = text?.trim() ?? '';
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    if (n == null) return '$label harus angka';
    if (n < 0) return '$label tidak boleh negatif';
    if (max != null && n > max) return '$label maksimal $max';
    return null;
  }

  String? _validateDose(String? text) {
    final t = text?.trim() ?? '';
    if (t.isEmpty) return null;
    final d = double.tryParse(t);
    if (d == null) return 'Dose harus angka';
    if (d < 0) return 'Dose tidak boleh negatif';
    return null;
  }

  Widget _ratioPreview() {
    // Reaktif terhadap perubahan teks dose/air (controller = Listenable);
    // build induk tidak ter-trigger oleh perubahan controller.
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        _doseController,
        _waterController,
      ]),
      builder: (context, _) {
        final dose = _parseDouble(_doseController.text);
        final water = _parseInt(_waterController.text);
        if (dose == null || dose <= 0 || water == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: RoastmateSpacing.sm),
          child: Text(
            'Rasio: ${brewRatioLabel(doseG: dose, waterVolumeMl: water)}',
            style: RoastmateText.bodySm.copyWith(
              color: RoastmateColors.textSecondary,
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final notes = _notesController.text.trim();
    final recipe = BrewRecipe(
      recipeId: '', // di-generate repo: U<epoch-micros>
      name: _nameController.text.trim(),
      methodId: _methodId,
      species: _species,
      qualityProfile: _profile,
      roastContext: _roastContext,
      doseG: _parseDouble(_doseController.text),
      waterVolumeMl: _parseInt(_waterController.text),
      grindSize: _grind,
      temperatureC: _parseInt(_tempController.text),
      brewingTimeS: _parseInt(_timeController.text),
      source: 'USER',
      notes: notes.isEmpty ? null : notes,
    );

    try {
      await ref.read(brewCatalogProvider.notifier).addRecipe(recipe);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan resep: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: RoastmateText.labelLg.copyWith(
        color: RoastmateColors.textSecondary,
      ),
      filled: true,
      fillColor: RoastmateColors.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: RoastmateSpacing.lg,
        vertical: RoastmateSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RoastmateRadius.small),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RoastmateRadius.small),
        borderSide: const BorderSide(color: RoastmateColors.primary),
      ),
    );
  }

  DropdownButtonFormField<String> _dropdown(
    String label, {
    required String initialValue,
    required List<String> items,
    required ValueChanged<String?> onSelected,
    required String requiredMessage,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (v) => setState(() => onSelected(v)),
      validator: (v) => v == null ? requiredMessage : null,
      isExpanded: true,
      decoration: _decoration(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final methods = ref.watch(brewCatalogProvider).methods;

    return Scaffold(
      backgroundColor: RoastmateColors.background,
      appBar: const RoastmateAppBar(title: 'Resep Baru'),
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
                    Text(
                      'Tambah Resep Seduh',
                      style: RoastmateText.titleLg.copyWith(
                        color: RoastmateColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: RoastmateSpacing.xs),
                    Text(
                      'Simpan resep buatanmu sendiri. Tersimpan permanen di '
                      'perangkat dan tampil di seksi Resep Kamu.',
                      style: RoastmateText.bodyMd.copyWith(
                        color: RoastmateColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: RoastmateSpacing.xl),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      style: RoastmateText.bodyLg.copyWith(
                        color: RoastmateColors.textPrimary,
                      ),
                      decoration: _decoration('Nama resep'),
                      validator: (value) {
                        final t = value?.trim() ?? '';
                        if (t.isEmpty) return 'Nama resep wajib diisi';
                        if (t.length < 3) return 'Nama minimal 3 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: RoastmateSpacing.md),
                    if (methods.isNotEmpty)
                      DropdownButtonFormField<String>(
                        // initialValue di-capture saat field dibuat — dropdown
                        // baru di-mount setelah metode KB termuat (prefill M001).
                        initialValue: methods.any((m) => m.methodId == 'M001')
                            ? 'M001'
                            : methods.first.methodId,
                        items: [
                          for (final m in methods)
                            DropdownMenuItem(
                              value: m.methodId,
                              child: Text(m.methodName),
                            ),
                        ],
                        onChanged: (v) =>
                            setState(() => _methodId = v ?? _methodId),
                        validator: (v) =>
                            v == null ? 'Metode wajib dipilih' : null,
                        isExpanded: true,
                        decoration: _decoration('Metode'),
                      ),
                    const SizedBox(height: RoastmateSpacing.md),
                    _dropdown(
                      'Species',
                      initialValue: _species,
                      items: _speciesOptions,
                      onSelected: (v) => _species = v ?? _species,
                      requiredMessage: 'Species wajib dipilih',
                    ),
                    const SizedBox(height: RoastmateSpacing.md),
                    _dropdown(
                      'Roast context',
                      initialValue: _roastContext,
                      items: _roastOptions,
                      onSelected: (v) => _roastContext = v ?? _roastContext,
                      requiredMessage: 'Roast context wajib dipilih',
                    ),
                    const SizedBox(height: RoastmateSpacing.md),
                    _dropdown(
                      'Quality profile',
                      initialValue: _profile,
                      items: _profileOptions,
                      onSelected: (v) => _profile = v ?? _profile,
                      requiredMessage: 'Quality profile wajib dipilih',
                    ),
                    const SizedBox(height: RoastmateSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _doseController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: RoastmateText.bodyLg.copyWith(
                              color: RoastmateColors.textPrimary,
                            ),
                            decoration: _decoration('Dose (g)'),
                            validator: _validateDose,
                          ),
                        ),
                        const SizedBox(width: RoastmateSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _waterController,
                            keyboardType: TextInputType.number,
                            style: RoastmateText.bodyLg.copyWith(
                              color: RoastmateColors.textPrimary,
                            ),
                            decoration: _decoration('Air (ml)'),
                            validator: (v) => _validateWholeNumber(
                              v,
                              label: 'Air',
                            ),
                          ),
                        ),
                      ],
                    ),
                    _ratioPreview(),
                    const SizedBox(height: RoastmateSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _grind,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('— opsional'),
                        ),
                        for (final g in _grindOptions)
                          DropdownMenuItem(value: g, child: Text(g)),
                      ],
                      onChanged: (v) => setState(() => _grind = v),
                      isExpanded: true,
                      decoration: _decoration('Grind (opsional)'),
                    ),
                    const SizedBox(height: RoastmateSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tempController,
                            keyboardType: TextInputType.number,
                            style: RoastmateText.bodyLg.copyWith(
                              color: RoastmateColors.textPrimary,
                            ),
                            decoration: _decoration('Suhu (°C)'),
                            validator: (v) => _validateWholeNumber(
                              v,
                              label: 'Suhu',
                              max: 100,
                            ),
                          ),
                        ),
                        const SizedBox(width: RoastmateSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _timeController,
                            keyboardType: TextInputType.number,
                            style: RoastmateText.bodyLg.copyWith(
                              color: RoastmateColors.textPrimary,
                            ),
                            decoration: _decoration('Waktu (detik)'),
                            validator: (v) => _validateWholeNumber(
                              v,
                              label: 'Waktu',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: RoastmateSpacing.md),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      style: RoastmateText.bodyMd.copyWith(
                        color: RoastmateColors.textPrimary,
                      ),
                      decoration: _decoration('Notes (opsional)'),
                    ),
                    const SizedBox(height: RoastmateSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
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
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: RoastmateColors.surface,
                                ),
                              )
                            : const Text('Simpan Resep'),
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
