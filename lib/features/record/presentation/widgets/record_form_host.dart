import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';

/// Satu lembar CATAT dengan pengalih jenis di atas formulirnya (UX-1, KO-5):
/// CATAT langsung ke formulir, tanpa lembar pilihan edukasi.
///
/// [formFor] membangun formulir untuk jenis yang dipilih dan memasang
/// pengalih yang diberikan di bawah kopnya. Formulir tetap menutup lembar ini
/// sendiri (`Navigator.pop`) dengan hasilnya — disimpan, dibatalkan, atau
/// `OpenFreelance`. Tur CATAT (TR-CATAT) dipicu dari sini.
class RecordFormHost extends StatefulWidget {
  /// Membuat [RecordFormHost].
  const RecordFormHost({required this.initialChoice, required this.formFor, super.key});

  /// Jenis yang terpilih saat dibuka; bawaan CATAT adalah pengeluaran.
  final RecordChoice initialChoice;

  /// Formulir untuk [RecordChoice], dengan pengalih jenis siap pasang.
  final Widget Function(RecordChoice choice, Widget kindSwitcher) formFor;

  @override
  State<RecordFormHost> createState() => _RecordFormHostState();
}

class _RecordFormHostState extends State<RecordFormHost> {
  late RecordChoice _choice = widget.initialChoice;

  @override
  Widget build(BuildContext context) {
    return TourTrigger(
      tour: TourId.record,
      ready: true,
      // Kunci per jenis: formulir baru dibangun bersih saat jenis diganti.
      child: KeyedSubtree(
        key: ValueKey(_choice),
        child: widget.formFor(
          _choice,
          RecordKindSwitcher(selected: _choice, onChanged: (choice) => setState(() => _choice = choice)),
        ),
      ),
    );
  }
}

/// Pengalih tiga segmen Keluar | Masuk | Transfer — pengganti lembar pilihan
/// CATAT (UX-1). Keluar lebih dulu karena paling sering dicatat.
class RecordKindSwitcher extends StatelessWidget {
  /// Membuat [RecordKindSwitcher].
  const RecordKindSwitcher({required this.selected, required this.onChanged, super.key});

  /// Jenis aktif.
  final RecordChoice selected;

  /// Dipanggil dengan jenis baru.
  final ValueChanged<RecordChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    return SpotlightTarget(
      spotlightKey: SpotlightKey.recordKind,
      child: Semantics(
        container: true,
        label: t.record.kindSwitcherLabel,
        child: AppSegmentedControl<RecordChoice>(
          options: [
            (RecordChoice.expense, t.record.kindExpense),
            (RecordChoice.income, t.record.kindIncome),
            (RecordChoice.transfer, t.record.kindTransfer),
          ],
          selected: selected,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
