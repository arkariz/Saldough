import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:saldough/features/analysis/presentation/widgets/analysis_host.dart';
import 'package:saldough/features/analysis/presentation/widgets/analysis_view.dart';

/// Segmen Analisis di tab Riwayat. Disisipkan akar komposisi ke
/// `TransactionListPage`, jadi fitur `transaction` tidak mengimpor `analysis`
/// (ADR-030).
class AnalysisSegment extends StatelessWidget {
  /// Membuat [AnalysisSegment].
  const AnalysisSegment({required this.container, super.key});

  /// Kontainer induk (akar komposisi).
  final GetIt container;

  @override
  Widget build(BuildContext context) =>
      AnalysisHost(container: container, sharesHistoryPeriod: true, child: const AnalysisView());
}
