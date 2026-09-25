import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/net_pay_breakdown.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/domain/usecases/calculate_net_pay.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Ringkasan worklog di puncak Ikhtisar Freelance (FR-FRL-005). Seluruh
/// nominal adalah gaji KOTOR (jam × tarif): [paid] + [unpaid] = [earned].
final class FreelanceSummary {
  /// Membuat [FreelanceSummary].
  const FreelanceSummary({required this.totalHours, required this.earned, required this.paid});

  /// Total jam seluruh entri.
  final int totalHours;

  /// Total diperoleh (kotor), sen.
  final int earned;

  /// Bagian [earned] yang pembayarannya sudah dicatat diterima, sen.
  final int paid;

  /// Bagian [earned] yang belum diterima — belum ditagihkan maupun tertunda.
  int get unpaid => earned - paid;
}

/// State `FreelanceBloc`. Nilai turunan (diperoleh, gaji kotor/bersih,
/// status entri) dihitung di sini, tidak pernah disimpan.
final class FreelanceState extends UiState<FreelanceState> {
  /// Membuat [FreelanceState].
  const FreelanceState({
    required this.projects,
    required this.entries,
    required this.payments,
    required this.wallets,
    required this.isLoading,
    this.loadFailed = false,
    super.effect,
  });

  /// State awal, sebelum apa pun dimuat.
  factory FreelanceState.initial() =>
      const FreelanceState(projects: [], entries: [], payments: [], wallets: [], isLoading: true);

  static const _calculateNetPay = CalculateNetPay();

  /// Seluruh proyek.
  final List<FreelanceProject> projects;

  /// Seluruh entri worklog.
  final List<WorklogEntry> entries;

  /// Seluruh pembayaran.
  final List<FreelancePayment> payments;

  /// Seluruh dompet, aktif maupun tidak — nama dompet pembayaran lama harus
  /// tetap terbaca walau dompetnya sudah dinonaktifkan.
  final List<Wallet> wallets;

  /// Sedang memuat untuk pertama kali.
  final bool isLoading;

  /// Pembacaan terakhir gagal.
  final bool loadFailed;

  /// Dompet aktif — pilihan dompet tujuan saat mencatat diterima.
  List<Wallet> get activeWallets => wallets.where((w) => w.isActive).toList();

  /// Proyek ber-`id` [id], atau `null`.
  FreelanceProject? projectOf(String id) => projects.where((p) => p.id == id).firstOrNull;

  /// Dompet ber-`id` [id], atau `null`.
  Wallet? walletOf(String id) => wallets.where((w) => w.id == id).firstOrNull;

  /// Pembayaran yang menagihkan [entry], atau `null` kalau belum ditagihkan.
  ///
  /// `paymentId` yang menunjuk pembayaran yang tidak ada (penulisan yang
  /// gagal di tengah) dibaca sebagai belum ditagihkan, supaya entri itu
  /// tidak terkunci selamanya.
  FreelancePayment? paymentOf(WorklogEntry entry) {
    final paymentId = entry.paymentId;
    return paymentId == null ? null : payments.where((p) => p.id == paymentId).firstOrNull;
  }

  /// Entri worklog yang tercakup [payment].
  List<WorklogEntry> entriesOf(FreelancePayment payment) {
    final ids = payment.entryIds.toSet();
    return entries.where((e) => ids.contains(e.id)).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Entri [projectId] yang belum ditagihkan, terlama di atas — calon isi
  /// pembayaran baru.
  List<WorklogEntry> unbilledEntriesOf(String projectId) =>
      entries.where((e) => e.projectId == projectId && paymentOf(e) == null).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  /// Proyek yang masih punya entri belum ditagihkan.
  List<FreelanceProject> get projectsWithUnbilled => projects.where((p) => unbilledEntriesOf(p.id).isNotEmpty).toList();

  /// Apakah [project] sudah punya entri — proyek seperti ini tidak bisa
  /// dihapus (ADR-019).
  bool projectHasEntries(FreelanceProject project) => entries.any((e) => e.projectId == project.id);

  /// Gaji kotor, potongan, dan gaji bersih [payment].
  NetPayBreakdown breakdownOf(FreelancePayment payment) => _calculateNetPay(
    grossPay: entriesOf(payment).fold(0, (sum, e) => sum + e.earnedAmount),
    deductionRules: payment.deductionRules,
  );

  /// Entri terbaru di atas.
  List<WorklogEntry> get sortedEntries => [...entries]..sort((a, b) => b.date.compareTo(a.date));

  /// Pembayaran tertunda, perkiraan terdekat di atas.
  List<FreelancePayment> get pendingPayments =>
      payments.where((p) => !p.isPaid).toList()..sort((a, b) => a.expectedDate.compareTo(b.expectedDate));

  /// Pembayaran yang sudah diterima, terbaru di atas.
  List<FreelancePayment> get paidPayments =>
      payments.where((p) => p.isPaid).toList()..sort((a, b) => b.receivedDate!.compareTo(a.receivedDate!));

  /// Total gaji bersih pembayaran tertunda, sen.
  int get pendingNetTotal => pendingPayments.fold(0, (sum, p) => sum + breakdownOf(p).netPay);

  /// Total gaji bersih pembayaran yang sudah diterima, sen — sama dengan
  /// jumlah transaksi pemasukan yang lahir dari freelance.
  int get paidNetTotal => paidPayments.fold(0, (sum, p) => sum + breakdownOf(p).netPay);

  /// Ringkasan worklog (FR-FRL-005).
  FreelanceSummary get summary {
    var hours = 0;
    var earned = 0;
    var paid = 0;
    for (final entry in entries) {
      hours += entry.hours;
      earned += entry.earnedAmount;
      if (paymentOf(entry)?.isPaid ?? false) paid += entry.earnedAmount;
    }
    return FreelanceSummary(totalHours: hours, earned: earned, paid: paid);
  }

  @override
  FreelanceState copyWith({
    List<FreelanceProject>? projects,
    List<WorklogEntry>? entries,
    List<FreelancePayment>? payments,
    List<Wallet>? wallets,
    bool? isLoading,
    bool? loadFailed,
    UiEffect? effect,
  }) {
    return FreelanceState(
      projects: projects ?? this.projects,
      entries: entries ?? this.entries,
      payments: payments ?? this.payments,
      wallets: wallets ?? this.wallets,
      isLoading: isLoading ?? this.isLoading,
      loadFailed: loadFailed ?? this.loadFailed,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [projects, entries, payments, wallets, isLoading, loadFailed];
}
