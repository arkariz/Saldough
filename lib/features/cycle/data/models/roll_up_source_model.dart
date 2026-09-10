import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';

/// Serialisasi [RollUpSource] ke/dari JSON, lewat `type` pembeda.
abstract final class RollUpSourceModel {
  RollUpSourceModel._();

  /// Membaca [RollUpSource] dari JSON, atau `null` kalau [json] `null`.
  static RollUpSource? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return switch (json['type'] as String) {
      'grocery' => RollUpSource.grocery,
      'card' => RollUpSource.card(json['cardId'] as String),
      final type => throw FormatException('RollUpSource.type tidak dikenal: $type'),
    };
  }

  /// Menulis [source] ke JSON, atau `null` kalau [source] `null`.
  static Map<String, dynamic>? toJson(RollUpSource? source) {
    return switch (source) {
      null => null,
      GroceryRollUpSource() => {'type': 'grocery'},
      CardRollUpSource(:final cardId) => {'type': 'card', 'cardId': cardId},
    };
  }
}
