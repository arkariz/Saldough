import 'package:dependencies/dependencies.dart';

/// Satu baris di bagian pemasukan sebuah [MonthlyCycle].
final class IncomeLine extends Equatable {
  /// Membuat [IncomeLine].
  const IncomeLine({
    required this.id,
    required this.label,
    required this.amount,
    this.sourceId,
    this.isTemplate = false,
    this.needsReview = false,
  });

  /// Identitas baris.
  final String id;

  /// Nama yang tampil, misalnya `"Gaji Koko"`.
  final String label;

  /// Nominal dalam sen.
  final int amount;

  /// Rujukan ke `IncomeSource`. Null untuk baris yang diketik lepas.
  final String? sourceId;

  /// True kalau baris ikut terbawa saat rollover. Bawaan `false` — baris
  /// baru selalu insidental (ADR-0008).
  final bool isTemplate;

  /// True kalau baris ini hasil rollover yang belum dikonfirmasi pemilik.
  final bool needsReview;

  /// Salinan [IncomeLine] dengan field yang disebutkan diganti.
  IncomeLine copyWith({
    String? label,
    int? amount,
    String? sourceId,
    bool? isTemplate,
    bool? needsReview,
  }) {
    return IncomeLine(
      id: id,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      sourceId: sourceId ?? this.sourceId,
      isTemplate: isTemplate ?? this.isTemplate,
      needsReview: needsReview ?? this.needsReview,
    );
  }

  @override
  List<Object?> get props => [id, label, amount, sourceId, isTemplate, needsReview];
}
