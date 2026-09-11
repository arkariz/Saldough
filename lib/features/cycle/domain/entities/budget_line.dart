import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line_kind.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';

/// Satu baris di bagian anggaran sebuah `MonthlyCycle`.
///
/// Baris ber-`kind` [BudgetLineKind.rollUp] wajib punya [rollUpSource]
/// (invarian DOMAIN_MODEL.md) dan nominalnya ([amount]) tidak pernah
/// dipercaya dari dokumen tersimpan — `CycleRepositoryImpl` selalu
/// menghitungnya ulang saat membaca siklus (ADR-0008). Field [amount] di
/// sini menyimpan hasil hitung terakhir itu, bukan nilai yang pemilik bisa
/// sunting langsung untuk baris jenis ini.
final class BudgetLine extends Equatable {
  /// Membuat [BudgetLine].
  ///
  /// Melempar [ArgumentError] kalau `kind` bernilai [BudgetLineKind.rollUp]
  /// tapi [rollUpSource] tidak diisi.
  BudgetLine({
    required this.id,
    required this.label,
    required this.amount,
    required this.kind,
    this.rollUpSource,
    this.isTemplate = false,
    this.needsReview = false,
    this.rollUpSourceUnavailable = false,
  }) {
    if (kind == .rollUp && rollUpSource == null) {
      throw ArgumentError.value(
        rollUpSource,
        'rollUpSource',
        'Wajib diisi kalau kind bernilai BudgetLineKind.rollUp.',
      );
    }
  }

  /// Identitas baris.
  final String id;

  /// Nama yang tampil, misalnya `"listrik"`.
  final String label;

  /// Nominal dalam sen — lihat catatan di atas soal baris `rollUp`.
  final int amount;

  /// Jenis baris.
  final BudgetLineKind kind;

  /// Sumber roll-up. Wajib terisi kalau [kind] bernilai
  /// [BudgetLineKind.rollUp].
  final RollUpSource? rollUpSource;

  /// True kalau baris ikut terbawa saat rollover. Bawaan `false` — baris
  /// baru selalu insidental (ADR-0008).
  final bool isTemplate;

  /// True kalau baris ini hasil rollover yang belum dikonfirmasi pemilik.
  final bool needsReview;

  /// True kalau [kind] bernilai [BudgetLineKind.rollUp] tapi sumbernya belum
  /// tersedia (belanja/kartu belum dibangun — lihat ROADMAP.md Fase 2).
  /// [amount] bernilai 0 selama ini `true`. Selalu `false` untuk baris
  /// [BudgetLineKind.manual].
  final bool rollUpSourceUnavailable;

  /// Salinan [BudgetLine] dengan field yang disebutkan diganti.
  BudgetLine copyWith({
    String? label,
    int? amount,
    bool? isTemplate,
    bool? needsReview,
    bool? rollUpSourceUnavailable,
  }) {
    return BudgetLine(
      id: id,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      kind: kind,
      rollUpSource: rollUpSource,
      isTemplate: isTemplate ?? this.isTemplate,
      needsReview: needsReview ?? this.needsReview,
      rollUpSourceUnavailable:
          rollUpSourceUnavailable ?? this.rollUpSourceUnavailable,
    );
  }

  @override
  List<Object?> get props => [
    id,
    label,
    amount,
    kind,
    rollUpSource,
    isTemplate,
    needsReview,
    rollUpSourceUnavailable,
  ];
}
