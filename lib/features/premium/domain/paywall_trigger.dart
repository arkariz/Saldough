/// Tempat paywall dibuka (FREEMIUM_PAYWALL §9, ADR-041 §3.8). Nama P1–P10
/// mengikuti tabel §9; empat pemicu terakhir untuk gerbang fitur lama yang
/// belum punya baris di tabel itu.
enum PaywallTrigger {
  /// P1: kuota tafsir cerdas (termasuk foto) habis.
  smartQuota('P1'),

  /// P2: memilih aplikasi sumber notifikasi kedua.
  notificationSource('P2'),

  /// P3: sesudah "Contoh Penjaga".
  guardianExample('P3'),

  /// P4: jatah Tanya Tanuki habis.
  askQuota('P4'),

  /// P5: perkiraan Rencana melewati +2 bulan.
  forecast('P5'),

  /// P6: rapor akhir periode.
  report('P6'),

  /// P7: pembayaran freelance terlambat.
  freelanceOverdue('P7'),

  /// P8: lama tanpa cadangan.
  backupNudge('P8'),

  /// P9: musim laporan (Desember dan Januari).
  seasonal('P9'),

  /// P10: baris tetap di layar Akun.
  account('P10'),

  /// Otomasi rutin R3 (Catat otomatis dan kartunya).
  recurringAutomation('recurring_automation'),

  /// Analisis lebih dari batas periode Gratis.
  analysisHistory('analysis_history'),

  /// Kartu rekap nilai H-3 atau layar turun sesudah uji coba.
  trialRecap('trial_recap'),

  /// Batas jumlah template anggaran.
  templateLimit('template_limit'),

  /// Batas jumlah proyek freelance.
  projectLimit('project_limit');

  const PaywallTrigger(this.analyticsName);

  /// Nilai parameter `trigger` di peristiwa analitik (ADR-041 §3.12).
  final String analyticsName;
}
