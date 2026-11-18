import 'package:saldough/shared/investment/domain/instrument.dart';

/// Serialisasi [Instrument] untuk dokumen `investment_instruments`
/// (ADR-049 §3.9).
abstract final class InstrumentModel {
  /// Versi skema dokumen instrumen.
  static const schemaVersion = 1;

  /// [instrument] ke JSON.
  static Map<String, dynamic> toJson(Instrument instrument) => {
    'id': instrument.id,
    'name': instrument.name,
    'type': instrument.type.name,
    'createdAt': instrument.createdAt.toIso8601String(),
    if (instrument.code != null) 'code': instrument.code,
    if (instrument.opening case final o?)
      'opening': {'date': o.date.toIso8601String(), 'quantity': o.quantity, 'cost': o.cost},
  };

  /// [Instrument] dari JSON.
  static Instrument fromJson(Map<String, dynamic> json) {
    final opening = json['opening'] as Map<String, dynamic>?;
    return Instrument(
      id: json['id'] as String,
      name: json['name'] as String,
      type: InstrumentType.values.byName(json['type'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      code: json['code'] as String?,
      opening: opening == null
          ? null
          : OpeningHolding(
              date: DateTime.parse(opening['date'] as String),
              quantity: opening['quantity'] as int,
              cost: opening['cost'] as int,
            ),
    );
  }
}

/// Serialisasi [InstrumentValuation] untuk dokumen `investment_valuations`.
abstract final class ValuationModel {
  /// Versi skema dokumen valuasi.
  static const schemaVersion = 1;

  /// [valuation] ke JSON.
  static Map<String, dynamic> toJson(InstrumentValuation valuation) => {
    'instrumentId': valuation.instrumentId,
    'date': valuation.date.toIso8601String(),
    'unitPrice': valuation.unitPrice,
    'source': valuation.source.name,
  };

  /// [InstrumentValuation] dari JSON.
  static InstrumentValuation fromJson(Map<String, dynamic> json) => InstrumentValuation(
    instrumentId: json['instrumentId'] as String,
    date: DateTime.parse(json['date'] as String),
    unitPrice: json['unitPrice'] as int,
    source: ValuationSource.values.byName(json['source'] as String),
  );
}
