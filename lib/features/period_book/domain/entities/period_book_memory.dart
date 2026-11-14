import 'package:dependencies/dependencies.dart';

/// Yang diingat aplikasi tentang Buku Periode (ADR-045 §3.5): buku mana yang
/// sudah dibuka, langkah ritual yang selesai, kartu yang ditutup, fakta kartu
/// terakhir, dan sakelar ajakan.
///
/// Bukan data keuangan: tidak ada angka, hanya id periode. Id periode adalah
/// tanggal awal periode (`YYYY-MM-DD`) dari `financialPeriodOf`. Semua
/// perubahan mengembalikan salinan baru.
final class PeriodBookMemory extends Equatable {
  /// Membuat [PeriodBookMemory].
  const PeriodBookMemory({
    this.opened = const {},
    this.ritualSteps = const {},
    this.cardDismissed = const {},
    this.cardFacts = const {},
    this.inviteEnabled = true,
  });

  /// Kosong: belum ada buku dibuka, ajakan menyala.
  static const empty = PeriodBookMemory();

  /// Id periode → saat buku pertama kali dibuka. Dasar BP-10.
  final Map<String, DateTime> opened;

  /// Id periode → indeks langkah ritual (0–2) yang selesai (BP-6).
  final Map<String, Set<int>> ritualSteps;

  /// Id periode yang kartu Berandanya ditutup ("Nanti", BP-2).
  final Set<String> cardDismissed;

  /// Nama fakta Kartu Periode yang dinyalakan terakhir; kosong = bawaan
  /// (BP-16: nominal dan kategori terbesar mati).
  final Set<String> cardFacts;

  /// Sakelar Ajakan akhir periode (BP-14).
  final bool inviteEnabled;

  /// Buku periode [periodId] pernah dibuka.
  bool isOpened(String periodId) => opened.containsKey(periodId);

  /// Langkah ritual yang selesai untuk [periodId].
  Set<int> stepsOf(String periodId) => ritualSteps[periodId] ?? const {};

  /// Menandai buku [periodId] dibuka pada [at]; yang sudah dibuka tidak
  /// berubah (tanggal pertama dipertahankan).
  PeriodBookMemory withOpened(String periodId, DateTime at) =>
      isOpened(periodId) ? this : _copy(opened: {...opened, periodId: at});

  /// Menandai langkah ritual [step] selesai untuk [periodId].
  PeriodBookMemory withStepDone(String periodId, int step) =>
      _copy(ritualSteps: {...ritualSteps, periodId: {...stepsOf(periodId), step}});

  /// Menutup kartu Beranda periode [periodId].
  PeriodBookMemory withCardDismissed(String periodId) => _copy(cardDismissed: {...cardDismissed, periodId});

  /// Mengganti fakta kartu yang dinyalakan.
  PeriodBookMemory withCardFacts(Set<String> facts) => _copy(cardFacts: facts);

  /// Mengganti sakelar ajakan.
  PeriodBookMemory withInviteEnabled({required bool enabled}) => _copy(inviteEnabled: enabled);

  PeriodBookMemory _copy({
    Map<String, DateTime>? opened,
    Map<String, Set<int>>? ritualSteps,
    Set<String>? cardDismissed,
    Set<String>? cardFacts,
    bool? inviteEnabled,
  }) => PeriodBookMemory(
    opened: opened ?? this.opened,
    ritualSteps: ritualSteps ?? this.ritualSteps,
    cardDismissed: cardDismissed ?? this.cardDismissed,
    cardFacts: cardFacts ?? this.cardFacts,
    inviteEnabled: inviteEnabled ?? this.inviteEnabled,
  );

  @override
  List<Object?> get props => [opened, ritualSteps, cardDismissed, cardFacts, inviteEnabled];
}
