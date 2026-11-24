/// Kontrak repositori untuk memeriksa dan menyimpan status kelulusan onboarding.
abstract class OnboardingRepository {
  /// Memeriksa apakah pengguna sudah pernah menyelesaikan atau melewati onboarding.
  Future<bool> isOnboardingCompleted();

  /// Menyimpan status penyelesaian onboarding ke penyimpanan lokal.
  Future<void> setOnboardingCompleted(bool completed);
}
