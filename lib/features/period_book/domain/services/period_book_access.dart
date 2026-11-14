/// Hasil gerbang buku (ADR-045 §3.1).
enum BookAccess {
  /// Buku boleh dibuka.
  open,

  /// Buku terkunci; pengguna hanya punya Kartu Periode (BP-10, BP-15).
  locked,
}

/// Aturan BP-1 dan BP-10 sebagai fungsi murni.
///
/// [plusActive] = `Entitlements.can(PlusFeature.periodBook)` (Plus atau uji
/// coba, termasuk masa tenggang ADR-041). [everOpened] = buku periode itu
/// pernah dibuka (`PeriodBookMemory.isOpened`). Sesudah Plus berakhir, buku
/// yang pernah dibuka tetap terbuka; yang belum, terkunci.
///
/// Dipanggil rute buku dan Rak Buku, bukan hanya UI (ADR-045 §3.1).
BookAccess bookAccessOf({required bool plusActive, required bool everOpened}) =>
    plusActive || everOpened ? BookAccess.open : BookAccess.locked;
