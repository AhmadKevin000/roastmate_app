import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nama jenis biji kopi yang diisi pengguna sebelum scan.
///
/// State lokal sesi: dipakai untuk menimpa `batchName` pada hasil analisis.
final scanBatchNameProvider = StateProvider<String>((ref) => '');
