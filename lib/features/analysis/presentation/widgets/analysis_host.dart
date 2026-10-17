import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/analysis/di/analysis_scope.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_state.dart';
import 'package:state_management/state_management.dart';

/// Memasang scope dan [AnalysisBloc] untuk [child] lalu memulainya (ADR-030):
/// dipakai segmen di Riwayat maupun halaman rute penuh.
class AnalysisHost extends StatelessWidget {
  /// Membuat [AnalysisHost]. [periodStart] `null` = periode berjalan.
  const AnalysisHost({
    required this.container,
    required this.child,
    this.periodStart,
    super.key,
  });

  /// Kontainer induk (akar komposisi).
  final GetIt container;

  /// Tanggal di dalam periode yang dibuka; `null` = periode berjalan.
  final DateTime? periodStart;

  /// Isi layar.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScopeWidget<AnalysisScope>(
      create: () => AnalysisScope(parentContainer: container),
      builder: (context, scope) {
        final bloc = scope.container<AnalysisBloc>();
        return BlocProvider.value(
          value: bloc,
          child: EffectListener<AnalysisBloc, AnalysisState>(
            child: RunOnce(
              action: () => bloc.add(AnalysisStarted(periodStart: periodStart)),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
