/// Pintu sakelar Ajakan akhir periode di Akun (BP-14) ke ingatan buku.
abstract interface class PeriodBookSettingsAccess {
  /// Ajakan akhir periode menyala (bawaan: ya).
  Future<bool> inviteEnabled();

  /// Menyalakan atau mematikan ajakan. Rapor dan Rak Buku tetap bisa dibuka manual.
  Future<void> setInviteEnabled({required bool enabled});
}
