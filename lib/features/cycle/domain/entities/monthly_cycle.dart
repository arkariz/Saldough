import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';
import 'package:saldough/features/cycle/domain/entities/investment_plan.dart';

/// Agregat inti Saldough — satu blok tabel siklus bulanan, setara satu bulan
/// di spreadsheet utama. Satu-satunya entitas yang disimpan per bulan.
final class MonthlyCycle extends Equatable {
  /// Membuat [MonthlyCycle].
  const MonthlyCycle({
    required this.id,
    required this.incomeLines,
    required this.budgetLines,
    required this.investmentPlan,
    this.closedAt,
  });

  /// Siklus kosong untuk bulan ber-[id] (format `YYYY-MM`).
  factory MonthlyCycle.empty(String id) => MonthlyCycle(
        id: id,
        incomeLines: const [],
        budgetLines: const [],
        investmentPlan: InvestmentPlan.empty(),
      );

  /// Identitas siklus, format `YYYY-MM`, misalnya `"2026-09"`.
  final String id;

  /// Baris di bagian pemasukan.
  final List<IncomeLine> incomeLines;

  /// Baris di bagian anggaran.
  final List<BudgetLine> budgetLines;

  /// Rencana pembagian sisa.
  final InvestmentPlan investmentPlan;

  /// Terisi saat siklus dikunci. Null berarti masih berjalan.
  final DateTime? closedAt;

  /// True kalau siklus sudah ditutup dan tidak bisa disunting tanpa dibuka
  /// kembali secara sadar (ADR-0008).
  bool get isClosed => closedAt != null;

  /// Salinan [MonthlyCycle] dengan field yang disebutkan diganti.
  ///
  /// ⚠ Tidak menangani [closedAt] — `null` di sini berarti "tidak diganti",
  /// bukan "dikosongkan" (jebakan copyWith klasik untuk field nullable).
  /// Pakai [close] atau [reopen] untuk mengubah status kunci.
  MonthlyCycle copyWith({
    List<IncomeLine>? incomeLines,
    List<BudgetLine>? budgetLines,
    InvestmentPlan? investmentPlan,
  }) {
    return MonthlyCycle(
      id: id,
      incomeLines: incomeLines ?? this.incomeLines,
      budgetLines: budgetLines ?? this.budgetLines,
      investmentPlan: investmentPlan ?? this.investmentPlan,
      closedAt: closedAt,
    );
  }

  /// Salinan [MonthlyCycle] yang dikunci pada [at] (bawaan waktu sekarang).
  MonthlyCycle close({DateTime? at}) => MonthlyCycle(
        id: id,
        incomeLines: incomeLines,
        budgetLines: budgetLines,
        investmentPlan: investmentPlan,
        closedAt: at ?? DateTime.now(),
      );

  /// Salinan [MonthlyCycle] yang kuncinya dibuka kembali, secara sadar
  /// (ADR-0008).
  MonthlyCycle reopen() => MonthlyCycle(
        id: id,
        incomeLines: incomeLines,
        budgetLines: budgetLines,
        investmentPlan: investmentPlan,
      );

  @override
  List<Object?> get props => [id, incomeLines, budgetLines, investmentPlan, closedAt];
}
