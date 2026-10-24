/// Kemampuan yang dibuka Tanukonomy Plus (ADR-041 §3.8, FREEMIUM_PAYWALL §5).
///
/// Dipakai titik gerbang lewat `Entitlements.can`, dan untuk jatah per periode
/// lewat `EntitlementLimits.freeAllowance`. Pencatatan manual (CATAT) tidak
/// pernah punya nilai di sini (aturan 8).
enum PlusFeature {
  /// Aplikasi sumber Catat dari notifikasi; Gratis hanya yang pertama.
  notificationSources,

  /// Tingkat otomatis Catat dari notifikasi dan pola buatan baru.
  notificationAutoRecord,

  /// Tafsir cerdas lewat Gemini (suara, notifikasi, foto struk; KT-P14).
  smartInterpretation,

  /// Otomasi rutin R3: catat otomatis, belum terlihat, kenaikan harga,
  /// menganggur, saran (ADR-037, KT-P11).
  recurringAutomation,

  /// Analisis lebih dari batas periode Gratis.
  analysisHistory,

  /// Template anggaran; Gratis terbatas jumlahnya.
  budgetTemplates,

  /// Proyek freelance; Gratis terbatas jumlahnya (semua proyek dihitung).
  freelanceProjects,

  /// Tanya Tanuki (jatah cicip di Gratis).
  ask,

  /// Penjaga (jatah cicip di Gratis).
  guardian,
}
