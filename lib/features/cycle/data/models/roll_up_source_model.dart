import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';

/// Serialisasi [RollUpSource] ke/dari JSON, lewat `type` pembeda.
abstract final class RollUpSourceModel {
  RollUpSourceModel._();

  /// Membaca [RollUpSource] dari JSON, atau `null` kalau [json] `null`.
  ///
  /// `planId` kosong (`''`) kalau dokumen ditulis SEBELUM `GroceryRollUpSource`
  /// membawa `planId` (skema lama, sebelum rencana belanja per bulan) --
  /// bukan dilempar, supaya dokumen lama tetap bisa dibaca. `GroceryRollUpResolver`
  /// memperlakukan `planId` kosong sebagai "sumber tidak tersedia" (sama
  /// seperti kartu yang belum terdaftar), bukan error -- pemilik menaut
  /// ulang lewat `LineEditSheet` sekali saja.
  static RollUpSource? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return switch (json['type'] as String) {
      'grocery' => .grocery(json['planId'] as String? ?? ''),
      'card' => .card(json['cardId'] as String),
      final type => throw FormatException(
        'RollUpSource.type tidak dikenal: $type',
      ),
    };
  }

  /// Menulis [source] ke JSON, atau `null` kalau [source] `null`.
  static Map<String, dynamic>? toJson(RollUpSource? source) {
    return switch (source) {
      null => null,
      GroceryRollUpSource(:final planId) => {'type': 'grocery', 'planId': planId},
      CardRollUpSource(:final cardId) => {'type': 'card', 'cardId': cardId},
    };
  }
}
