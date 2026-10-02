import 'package:navigation/navigation.dart';

// Satu-satunya berkas fitur `recurring` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Input rincian rutin.
final class RecurringDetailInput extends RouteInput {
  /// Membuat [RecurringDetailInput].
  const RecurringDetailInput({required this.ruleId});

  /// Rutin yang dibuka.
  final String ruleId;
}

/// Kunci rute fitur `recurring`.
abstract final class RecurringRouteKeys {
  /// Rincian satu rutin (PLAN_TAB_LAYOUT §6.5).
  static const detail = RouteKey<RecurringDetailInput>('recurring.detail');
}
