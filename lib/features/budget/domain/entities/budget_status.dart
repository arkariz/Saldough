/// Status siklus hidup sebuah `Budget` — penyaring di layar Anggaran. Hanya
/// [archived] yang punya penanda tersimpan (`Budget.isArchived`); dua lainnya
/// turunan dari tanggal, sehingga anggaran berpindah dari [active] ke
/// [finished] sendirinya. Lihat DOMAIN_MODEL.md bagian "Anggaran".
enum BudgetStatus {
  /// Aktif: bukan diarsipkan, dan periodenya belum lewat.
  active,

  /// Selesai: bukan diarsipkan, tetapi periodenya sudah lewat.
  finished,

  /// Nonaktif: diarsipkan pemilik.
  archived,
}
