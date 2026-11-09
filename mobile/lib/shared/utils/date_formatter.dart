/// Format tanggal untuk tampilan UI.
///
/// Ditulis manual (bukan `intl`) agar tidak menambah dependency hanya untuk
/// satu format. Bulan memakai singkatan bahasa Indonesia.
const List<String> _monthsShort = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Label ringkas untuk kartu Beranda, mis. `12 Mar, 10:24`.
String formatShortDateLabel(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day ${_monthsShort[local.month - 1]}, $hour:$minute';
}
