import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

/// Segmen tab Rencana (ADR-034 §3.7, PLAN_TAB_LAYOUT §3).
enum PlanSegment {
  /// Bulan ini: uang nganggur dan perkiraan saldo (R1b).
  thisMonth,

  /// Anggaran: isi layar Anggaran yang lama (`BudgetListPage`).
  budget,

  /// Rutin: daftar transaksi rutin.
  recurring,
}

/// Tab **Rencana** (T-14.4): satu app bar, [AppSubTabs] di bawahnya, dan
/// isi segmen dalam `IndexedStack` supaya tiap segmen menjaga posisi
/// gulirnya.
///
/// Isi segmen diberikan akar komposisi (`AppShellPage`) lewat [segments],
/// jadi fitur `plan` tidak mengimpor `budget` maupun `recurring` (ADR-030).
/// Segmen aktif juga dipegang shell ([selected], [onChanged]): awal sesi
/// membuka Anggaran, sesudah itu segmen terakhir selama aplikasi hidup
/// (KT-L4), dan tempat lain bisa membuka segmen tertentu.
class PlanPage extends StatelessWidget {
  /// Membuat [PlanPage].
  const PlanPage({required this.segments, required this.selected, required this.onChanged, super.key});

  /// Isi tiap segmen, sesuai urutan [PlanSegment.values].
  final Map<PlanSegment, Widget> segments;

  /// Segmen yang tampil.
  final PlanSegment selected;

  /// Dipanggil saat sub-tab lain diketuk.
  final ValueChanged<PlanSegment> onChanged;

  /// Label sub-tab [segment]. Anggaran memakai kunci lama
  /// `appShell.budgetTabLabel` (kebiasaan T-8.8: kunci tidak diganti nama).
  static String labelOf(PlanSegment segment) => switch (segment) {
    PlanSegment.thisMonth => t.plan.thisMonthSegmentLabel,
    PlanSegment.budget => t.appShell.budgetTabLabel,
    PlanSegment.recurring => t.plan.recurringSegmentLabel,
  };

  @override
  Widget build(BuildContext context) {
    final visible = TourVisibility.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.appShell.planTabLabel),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SpotlightTarget(
            spotlightKey: SpotlightKey.planTabs,
            child: AppSubTabs<PlanSegment>(
              options: [for (final segment in PlanSegment.values) (segment, labelOf(segment))],
              selected: selected,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: selected.index,
        children: [
          for (final segment in PlanSegment.values)
            // Tur segmen hanya boleh mulai saat segmennya tampil (ADR-021 §3.3).
            TourVisibility(visible: visible && segment == selected, child: segments[segment] ?? const SizedBox()),
        ],
      ),
    );
  }
}
