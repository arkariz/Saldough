import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_frame.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/savings_goal/savings_goal_presentation.dart';

/// Persen sesudah tombol papan angka [key] ditekan pada persen [current]
/// (ADR-048 §9.3): angka ditambahkan di belakang (`000` = dua nol), hapus
/// membuang angka terakhir, hapus semua menjadi 0; operator dan desimal
/// diabaikan. Hasil di atas 100 ditolak (persen tetap).
int percentAfterKey(int current, String key) {
  if (key == moneyKeyBackspace) return current ~/ 10;
  if (key == RecordFormFrame.frameClearKey) return 0;
  final digits = key == '000' ? '00' : key;
  if (!RegExp(r'^\d+$').hasMatch(digits)) return current;
  final next = int.parse('$current$digits');
  return next > 100 ? current : next;
}

/// Daftar tujuan yang ikut menabung ke beberapa tujuan (ADR-048 §9.3): ikon,
/// nama, nominal hasil bagi, kotak persen yang diisi lewat papan angka Catat,
/// tombol keluarkan; di kepala ada Bagi rata dan Isi sisa, di bawah Tambah
/// tujuan. Jumlah persen tampil di [RecordSplitTotalBar], bukan di sini.
class RecordGoalSplitField extends StatelessWidget {
  /// Membuat [RecordGoalSplitField].
  const RecordGoalSplitField({
    required this.goals,
    required this.percents,
    required this.amountSen,
    required this.activeGoalId,
    required this.onSelect,
    required this.onRemove,
    required this.onEven,
    this.onFillRest,
    this.onAdd,
    super.key,
  });

  /// Tujuan yang ikut, urutan tampil.
  final List<SavingsGoal> goals;

  /// Persen per `goalId` tujuan yang ikut.
  final Map<String, int> percents;

  /// Total nominal, atau `null` bila belum diisi.
  final int? amountSen;

  /// Tujuan yang persennya sedang diisi papan angka, atau `null` (nominal).
  final String? activeGoalId;

  /// Kotak persen tujuan diketuk.
  final ValueChanged<String> onSelect;

  /// Tujuan dikeluarkan dari pembagian.
  final ValueChanged<String> onRemove;

  /// Bagi rata ke semua tujuan yang ikut.
  final VoidCallback onEven;

  /// Isi kekurangan sampai 100% ke tujuan aktif; `null` = tidak bisa.
  final VoidCallback? onFillRest;

  /// Membuka pemilih tujuan lain; `null` = semua tujuan sudah ikut.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final s = t.record.split;
    final parts = amountSen == null ? const <String, int>{} : splitByPercent(amountSen!, percents);
    return DsFieldGroup(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(s.goalsLabel, style: ds.typography.pixelCaption.copyWith(color: c.textMuted, fontSize: 10)),
              ),
              TextButton(key: const ValueKey('split-even'), onPressed: onEven, child: Text(s.evenAction)),
              TextButton(key: const ValueKey('split-fill'), onPressed: onFillRest, child: Text(s.fillRestAction)),
            ],
          ),
        ),
        for (final goal in goals)
          Padding(
            key: ValueKey('split-goal-${goal.id}'),
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                savingsGoalTile(goal.iconKey, size: DsIconTileSize.sm),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w700),
                      ),
                      AppMoneyText(parts[goal.id] ?? 0, size: MoneySize.small, color: c.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PercentBox(
                  key: ValueKey('split-percent-${goal.id}'),
                  value: percents[goal.id] ?? 0,
                  active: activeGoalId == goal.id,
                  semanticsLabel: s.percentSemantics(name: goal.name),
                  onTap: () => onSelect(goal.id),
                ),
                IconButton(
                  key: ValueKey('split-remove-${goal.id}'),
                  tooltip: s.removeAction(name: goal.name),
                  onPressed: () => onRemove(goal.id),
                  icon: Icon(Icons.close_rounded, size: 18, color: c.textMuted),
                ),
              ],
            ),
          ),
        if (onAdd case final add?)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('split-add'),
                onPressed: add,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(s.addAction),
              ),
            ),
          ),
      ],
    );
  }
}

class _PercentBox extends StatelessWidget {
  const _PercentBox({
    required this.value,
    required this.active,
    required this.semanticsLabel,
    required this.onTap,
    super.key,
  });

  final int value;
  final bool active;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Semantics(
      button: true,
      selected: active,
      label: semanticsLabel,
      value: '$value%',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: DsMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 150),
          width: 72,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: active ? c.surfaceCard : c.surfaceSunken,
            borderRadius: DsRadius.mdAll,
            border: Border.all(color: active ? c.actionPrimary : c.outlineSubtle, width: active ? 2 : 1),
          ),
          child: Text(
            '$value%',
            textAlign: TextAlign.end,
            style: ds.typography.titleMd.copyWith(fontSize: 16, color: value == 0 ? c.textMuted : null),
          ),
        ),
      ),
    );
  }
}

/// Baris jumlah persen di atas tombol Catat (ADR-048 §9.3): selalu terlihat,
/// hijau bila tepat 100, merah dengan kekurangan atau kelebihannya bila tidak.
class RecordSplitTotalBar extends StatelessWidget {
  /// Membuat [RecordSplitTotalBar].
  const RecordSplitTotalBar({required this.total, super.key});

  /// Jumlah persen tujuan yang ikut.
  final int total;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final s = t.record.split;
    final ok = total == 100;
    final hint = total < 100 ? s.totalShort(n: 100 - total) : (total > 100 ? s.totalOver(n: total - 100) : null);
    return Semantics(
      liveRegion: true,
      child: Row(
        key: const ValueKey('split-total'),
        children: [
          Text(s.totalLabel, style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w700)),
          if (hint != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(hint, style: ds.typography.bodySm.copyWith(color: c.error), overflow: TextOverflow.ellipsis),
            ),
          ] else
            const Spacer(),
          Text(
            '$total%',
            style: ds.typography.titleMd.copyWith(color: ok ? c.income : c.error, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
