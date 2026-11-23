/// Kredensial saat build, dibaca dari `--dart-define-from-file=.env`.
///
/// Contoh:
/// ```sh
/// flutter build apk --release --dart-define-from-file=.env
/// ```
///
/// Nilai menjadi konstanta waktu kompilasi (bukan aset APK), sehingga file
/// `.env` tidak perlu di-bundle dan rahasianya tidak ikut ter-unduh bersama
/// aplikasi. `flutter run --dart-define-from-file=.env` berlaku sama untuk dev.
///
/// Format `.env` (satu pasangan per baris, tanpa spasi di sekitar `=`):
/// ```
/// SUPABASE_URL=https://xxx.supabase.co
/// SUPABASE_ANON_KEY=sb_publishable_xxx
/// CLOUD_NAME=nama-cloud
/// CLOUDINARY_UPLOAD_PRESET=preset_unsigned
/// ```
class AppEnv {
  const AppEnv._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String cloudName = String.fromEnvironment('CLOUD_NAME');
  static const String cloudinaryUploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  static bool get hasSupabase =>
      _valid(supabaseUrl) && _valid(supabaseAnonKey);

  static bool get hasCloudinary =>
      _valid(cloudName) && _valid(cloudinaryUploadPreset);

  /// Nilai placeholder dari template tidak dianggap kredensial.
  static bool _valid(String value) =>
      value.isNotEmpty && !value.startsWith('your_');
}
