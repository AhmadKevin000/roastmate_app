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

/// Form tambah/edit resep seduh buatan user.
///
/// Mode tambah → route `/brewing/new` (tanpa `extra`).
/// Mode edit   → route `/brewing/edit` dengan `extra` berupa [BrewRecipe]
///              yang sudah ada. Field di-prefill, judul berubah, tombol
///              simpan memanggil `updateRecipe()` alih-alih `addRecipe()`.
///
/// v6: metode KB atau "Lainnya" (nama bebas), langkah seduh dinamis, dan
/// link video YouTube opsional. Validasi: nama wajib (≥ 3 karakter),
/// nama metode wajib saat "Lainnya", judul langkah wajib, angka opsional
/// ≥ 0 (suhu 0–100).
class UserRecipeFormScreen extends ConsumerStatefulWidget {
  /// Resep yang akan diedit. `null` berarti mode tambah resep baru.
  final BrewRecipe? initialRecipe;

  const UserRecipeFormScreen({super.key, this.initialRecipe});

  @override
  ConsumerState<UserRecipeFormScreen> createState() =>
      _UserRecipeFormScreenState();
}

class _UserRecipeFormScreenState extends ConsumerState<UserRecipeFormScreen> {
  bool get _isEditMode => widget.initialRecipe != null;

  /// Sentinel dropdown untuk metode di luar KB (v6).
  static const String _otherMethod = 'OTHER';

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
  late final TextEditingController _otherNameController;
  late final TextEditingController _videoController;
  late final TextEditingController _doseController;
  late final TextEditingController _waterController;
  late final TextEditingController _tempController;
  late final TextEditingController _timeController;
  late final TextEditingController _notesController;

  late String _methodId;
  late String _species;
  late String _roastContext;
  late String _profile;
  String? _grind;
  bool _submitting = false;

  /// Draft langkah seduh (v6) — tiap baris punya controller sendiri.
  final List<_StepDraft> _steps = <_StepDraft>[];

  @override
  void initState() {
    super.initState();
    final r = widget.initialRecipe;

    // Prefill dari resep yang ada (mode edit), atau default kosong (mode tambah).
    _nameController = TextEditingController(text: r?.name ?? '');
    _videoController = TextEditingController(text: r?.videoUrl ?? '');
    _doseController = TextEditingController(
      text: r?.doseG != null ? r!.doseG!.toString() : '',
    );
    _waterController = TextEditingController(
      text: r?.waterVolumeMl != null ? r!.waterVolumeMl!.toString() : '',
    );
    _tempController = TextEditingController(
      text: r?.temperatureC != null ? r!.temperatureC!.toString() : '',
    );
    _timeController = TextEditingController(
      text: r?.brewingTimeS != null ? r!.brewingTimeS!.toString() : '',
    );
    _notesController = TextEditingController(text: r?.notes ?? '');

    // Metode: bila mode edit dan methodId null → "Lainnya" (OTHER).
    if (r != null) {
      _methodId = r.methodId ?? _otherMethod;
      _otherNameController = TextEditingController(
        text: r.methodId == null ? (r.methodName) : '',
      );
    } else {
      _methodId = 'M001';
      _otherNameController = TextEditingController();
    }

    _species = r?.species ?? 'Arabica';
    _roastContext = r?.roastContext ?? 'Light';
    _profile = r?.qualityProfile ?? 'High';
    _grind = r?.grindSize;

    // Prefill langkah seduh (mode edit).
    if (r != null && r.brewSteps.isNotEmpty) {
      for (final step in r.brewSteps) {
        final draft = _StepDraft();
        draft.title.text = step.title;
        draft.description.text = step.description ?? '';
        draft.time.text = step.targetTime ?? '';
        _steps.add(draft);
      }
    }
  }

  void _addStep() {
    setState(() => _steps.add(_StepDraft()));
  }

  void _removeStep(int index) {
    _steps[index].dispose();
    setState(() => _steps.removeAt(index));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _otherNameController.dispose();
    _videoController.dispose();
    _doseController.dispose();
    _waterController.dispose();
    _tempController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    for (final s in _steps) {
      s.dispose();
    }
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
    final methods = ref.read(brewCatalogProvider).methods;
    final isOther = _methodId == _otherMethod;

    String kbMethodName = _methodId;
    for (final m in methods) {
      if (m.methodId == _methodId) {
        kbMethodName = m.methodName;
        break;
      }
    }

    final steps = [
      for (var i = 0; i < _steps.length; i++)
        BrewStep(
          stepNo: i + 1,
          phase: BrewStepPhase.brew,
          title: _steps[i].title.text.trim(),
          description: _steps[i].description.text.trim(),
          targetTime: _steps[i].time.text.trim().isEmpty
              ? null
              : _steps[i].time.text.trim(),
        ),
    ];

    try {
      if (_isEditMode) {
        // ── MODE EDIT ──────────────────────────────────────────────
        final updated = BrewRecipe(
          recipeId: widget.initialRecipe!.recipeId,
          name: _nameController.text.trim(),
          methodId: isOther ? null : _methodId,
          methodName: isOther
              ? _otherNameController.text.trim()
              : kbMethodName,
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
          videoUrl: _videoController.text.trim().isEmpty
              ? null
              : _videoController.text.trim(),
          steps: steps,
        );
        await ref.read(brewCatalogProvider.notifier).updateRecipe(updated);
      } else {
        // ── MODE TAMBAH ────────────────────────────────────────────
        final recipe = BrewRecipe(
          recipeId: '', // di-generate repo: U<epoch-micros>
          name: _nameController.text.trim(),
          methodId: isOther ? null : _methodId,
          methodName: isOther
              ? _otherNameController.text.trim()
              : kbMethodName,
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
          videoUrl: _videoController.text.trim().isEmpty
              ? null
              : _videoController.text.trim(),
          steps: steps,
        );
        await ref.read(brewCatalogProvider.notifier).addRecipe(recipe);
      }

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

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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

  /// Seksi "Langkah Seduh" dinamis (v6): tambah/hapus baris; tiap baris
  /// judul wajib, deskripsi & target waktu opsional.
  Widget _buildStepsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Langkah Seduh (opsional)',
                style: RoastmateText.titleSm.copyWith(
                  color: RoastmateColors.textPrimary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addStep,
              style: TextButton.styleFrom(
                foregroundColor: RoastmateColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: RoastmateSpacing.sm,
                ),
                minimumSize: Size.zero,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Langkah'),
            ),
          ],
        ),
        if (_steps.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: RoastmateSpacing.xs),
            child: Text(
              'Tuliskan langkah demi langkah cara seduhmu — tampil di '
              'halaman detail resep.',
              style: RoastmateText.bodySm.copyWith(
                color: RoastmateColors.iconMuted,
              ),
            ),
          )
        else ...[
          const SizedBox(height: RoastmateSpacing.sm),
          for (var i = 0; i < _steps.length; i++) ...[
            _buildStep(i, _steps[i]),
            if (i < _steps.length - 1)
              const SizedBox(height: RoastmateSpacing.sm),
          ],
        ],
      ],
    );
  }

  Widget _buildStep(int index, _StepDraft step) {
    return Container(
      padding: const EdgeInsets.all(RoastmateSpacing.md),
      decoration: BoxDecoration(
        color: RoastmateColors.surfaceContainer,
        borderRadius: BorderRadius.circular(RoastmateRadius.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Langkah ${index + 1}',
                style: RoastmateText.labelMd.copyWith(
                  color: RoastmateColors.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Hapus langkah',
                onPressed: () => _removeStep(index),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: RoastmateColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: RoastmateSpacing.xs),
          TextFormField(
            controller: step.title,
            style: RoastmateText.bodyMd.copyWith(
              color: RoastmateColors.textPrimary,
            ),
            decoration: _decoration('Judul langkah'),
            validator: (value) {
              if ((value?.trim() ?? '').isEmpty) {
                return 'Judul langkah wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: RoastmateSpacing.xs),
          TextFormField(
            controller: step.description,
            maxLines: 2,
            style: RoastmateText.bodyMd.copyWith(
              color: RoastmateColors.textPrimary,
            ),
            decoration: _decoration(
              'Deskripsi (opsional)',
              hint: 'mis. Tuang spiral sampai 240 ml',
            ),
          ),
          const SizedBox(height: RoastmateSpacing.xs),
          TextFormField(
            controller: step.time,
            style: RoastmateText.bodyMd.copyWith(
              color: RoastmateColors.textPrimary,
            ),
            decoration: _decoration(
              'Target waktu (opsional)',
              hint: 'mis. 00:30',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final methods = ref.watch(brewCatalogProvider).methods;

    // Tentukan initialValue dropdown metode untuk mode edit.
    // Bila method id dari resep ada di KB → pakai itu; bila null (OTHER) →
    // 'OTHER'; bila tidak ditemukan di list (KB update) → fallback M001.
    String dropdownInitialValue;
    if (_isEditMode) {
      final rid = widget.initialRecipe!.methodId;
      if (rid == null) {
        dropdownInitialValue = _otherMethod;
      } else if (methods.any((m) => m.methodId == rid)) {
        dropdownInitialValue = rid;
      } else {
        dropdownInitialValue =
            methods.isNotEmpty ? methods.first.methodId : 'M001';
      }
    } else {
      dropdownInitialValue = methods.any((m) => m.methodId == 'M001')
          ? 'M001'
          : (methods.isNotEmpty ? methods.first.methodId : 'M001');
    }

    return Scaffold(
      backgroundColor: RoastmateColors.background,
      appBar: RoastmateAppBar(
        title: _isEditMode ? 'Edit Resep' : 'Resep Baru',
      ),
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
                      _isEditMode ? 'Edit Resep Seduh' : 'Tambah Resep Seduh',
                      style: RoastmateText.titleLg.copyWith(
                        color: RoastmateColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: RoastmateSpacing.xs),
                    Text(
                      _isEditMode
                          ? 'Perbarui resep buatanmu. Perubahan tersimpan '
                              'permanen di perangkat.'
                          : 'Simpan resep buatanmu sendiri. Tersimpan permanen di '
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
                        initialValue: dropdownInitialValue,
                        items: [
                          for (final m in methods)
                            DropdownMenuItem(
                              value: m.methodId,
                              child: Text(m.methodName),
                            ),
                          const DropdownMenuItem(
                            value: _otherMethod,
                            child: Text('Lainnya (metode lain)'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _methodId = v ?? _methodId),
                        validator: (v) =>
                            v == null ? 'Metode wajib dipilih' : null,
                        isExpanded: true,
                        decoration: _decoration('Metode'),
                      ),
                    if (_methodId == _otherMethod) ...[
                      const SizedBox(height: RoastmateSpacing.md),
                      TextFormField(
                        controller: _otherNameController,
                        style: RoastmateText.bodyLg.copyWith(
                          color: RoastmateColors.textPrimary,
                        ),
                        decoration: _decoration(
                          'Nama metode',
                          hint: 'mis. AeroPress Homemade',
                        ),
                        validator: (value) {
                          final t = value?.trim() ?? '';
                          if (t.isEmpty) return 'Nama metode wajib diisi';
                          if (t.length < 2) return 'Nama minimal 2 karakter';
                          return null;
                        },
                      ),
                    ],
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
                    _buildStepsSection(),
                    const SizedBox(height: RoastmateSpacing.md),
                    TextFormField(
                      controller: _videoController,
                      style: RoastmateText.bodyMd.copyWith(
                        color: RoastmateColors.textPrimary,
                      ),
                      decoration: _decoration(
                        'Link video YouTube (opsional)',
                        hint: 'https://youtu.be/…',
                      ),
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
                            : Text(
                                _isEditMode ? 'Simpan Perubahan' : 'Simpan Resep',
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

/// Satu baris draft langkah seduh (v6) — controller per field.
class _StepDraft {
  final TextEditingController title = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController time = TextEditingController();

  void dispose() {
    title.dispose();
    description.dispose();
    time.dispose();
  }
}
