import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Status tujuan tabungan (ADR-048 §3.3). Batas Gratis hanya menghitung
/// [active].
enum SavingsGoalStatus {
  /// Masih berjalan.
  active,

  /// Target sudah tercapai. Menetap walau saldo turun lagi (keputusan pemilik
  /// 17 Nov 2026); kemajuan tetap mengikuti saldo.
  completed,

  /// Tidak aktif. Dompetnya tetap ada.
  archived,
}

/// Rencana mengumpulkan sejumlah uang di dompetnya sendiri (WEALTH_ASSETS §4,
/// ADR-048 §8). **Rencana, bukan pemesanan uang** (aturan 5):
/// tujuan sendiri tidak pernah membuat transaksi. Kemajuannya dibaca dari saldo
/// dompet [walletId]; tidak ada nilai turunan yang disimpan.
final class SavingsGoal extends Equatable {
  /// Membuat [SavingsGoal].
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.iconKey,
    required this.walletId,
    required this.createdAt,
    this.status = SavingsGoalStatus.active,
    this.targetDate,
    this.description,
    this.completedAt,
  });

  /// Identitas tujuan.
  final String id;

  /// Nama pilihan pemilik, mis. "Dana darurat". Data pengguna, tidak lewat
  /// i18n.
  final String name;

  /// Target dalam sen, selalu positif.
  final int targetAmount;

  /// Kunci ikon dari pilihan yang sama dengan kategori.
  final String iconKey;

  /// Dompet milik tujuan ini, dibuat otomatis bersama tujuannya (ADR-048 §8).
  /// Hanya menerima dan mengirim transfer (§8.2a).
  final String walletId;

  /// Kapan tujuan dibuat.
  final DateTime createdAt;

  /// Status saat ini.
  final SavingsGoalStatus status;

  /// Target tanggal, hanya penanda (WEALTH_ASSETS T-6).
  final DateTime? targetDate;

  /// Keterangan bebas, boleh kosong.
  final String? description;

  /// Kapan target pertama kali tercapai, `null` bila belum.
  final DateTime? completedAt;

  /// Salinan dengan field yang disebutkan diganti. [clearTargetDate] dan
  /// [clearDescription] mengosongkan field opsionalnya.
  SavingsGoal copyWith({
    String? name,
    int? targetAmount,
    String? iconKey,
    SavingsGoalStatus? status,
    DateTime? targetDate,
    bool clearTargetDate = false,
    String? description,
    bool clearDescription = false,
    DateTime? completedAt,
  }) {
    return SavingsGoal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      iconKey: iconKey ?? this.iconKey,
      walletId: walletId,
      createdAt: createdAt,
      status: status ?? this.status,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      description: clearDescription ? null : (description ?? this.description),
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    targetAmount,
    iconKey,
    walletId,
    createdAt,
    status,
    targetDate,
    description,
    completedAt,
  ];
}

/// Kemajuan sebuah tujuan, dihitung dari saldo dompetnya (ADR-048 §8.1).
/// Semua nilai dalam sen; pembulatan hanya di [percent].
final class SavingsGoalProgress extends Equatable {
  /// Membuat [SavingsGoalProgress].
  const SavingsGoalProgress({required this.collected, required this.target});

  /// Kemajuan [goal] dari [wallets]: `currentBalance` dompet milik tujuan,
  /// termasuk saldo awalnya; 0 bila dompetnya tidak ditemukan.
  factory SavingsGoalProgress.of(SavingsGoal goal, Iterable<Wallet> wallets) {
    final wallet = wallets.where((w) => w.id == goal.walletId).firstOrNull;
    return SavingsGoalProgress(collected: wallet?.currentBalance ?? 0, target: goal.targetAmount);
  }

  /// Saldo dompet tujuan. Boleh negatif.
  final int collected;

  /// Target tujuan.
  final int target;

  /// Kekurangan, tidak pernah negatif.
  int get remaining => collected >= target ? 0 : target - collected;

  /// Persen terkumpul, dibulatkan ke bawah; saldo negatif tampil 0. Boleh
  /// lebih dari 100.
  int get percent => collected <= 0 ? 0 : collected * 100 ~/ target;

  /// Apakah target sudah tercapai.
  bool get reached => collected >= target;

  @override
  List<Object?> get props => [collected, target];
}

/// Id dompet milik tujuan di [goals]: dompet yang hanya untuk transfer dan
/// tampil di bagian Tujuan, bukan di grid dompet (ADR-048 §8).
Set<String> goalWalletIds(Iterable<SavingsGoal> goals) => {for (final g in goals) g.walletId};
