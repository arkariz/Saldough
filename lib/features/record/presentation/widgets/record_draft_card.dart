import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/capture/capture.dart';

/// Kartu di atas formulir CATAT yang terisi dari Catat Cerdas (ADR-027 §3.4):
/// teks yang tertangkap, dan hal yang perlu diperiksa sebelum menekan Catat.
class RecordDraftCard extends StatelessWidget {
  /// Membuat [RecordDraftCard] untuk [draft].
  const RecordDraftCard({required this.draft, super.key});

  /// Draf yang mengisi formulir.
  final RecordDraft draft;

  @override
  Widget build(BuildContext context) {
    if (draft.issues.isEmpty) return const SizedBox.shrink();
    final ds = context.ds;
    final c = ds.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.warningContainer.withValues(alpha: 0.55),
        borderRadius: DsRadius.lgAll,
        border: Border.all(color: c.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.record.draftCheckTitle, style: ds.typography.titleMd.copyWith(fontSize: 14)),
          const SizedBox(height: 6),
          for (final issue in DraftIssue.values)
            if (draft.issues.contains(issue))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: c.warning),
                    const SizedBox(width: 6),
                    Expanded(child: Text(draftIssueMessage(issue), style: ds.typography.bodySm.copyWith(fontSize: 13))),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// Bisikan Tanuki di bawah isian pengeluaran bila transaksi terhubung ke satu
/// pos anggaran: rencana pos itu dan, bila nominal sudah diisi, seberapa
/// besar catatan ini darinya. Hanya angka yang nyata (rencana pos); sisa pos
/// tidak dihitung di sini, dan anggaran tetap rencana, bukan pemesanan uang.
class RecordWhisperCard extends StatelessWidget {
  /// Membuat [RecordWhisperCard].
  const RecordWhisperCard({required this.itemName, required this.plannedSen, required this.amountSen, super.key});

  /// Nama pos terhubung.
  final String itemName;

  /// Rencana pos untuk periodenya, sen.
  final int plannedSen;

  /// Nominal yang sedang diisi, sen; `null` atau 0 = belum ada.
  final int? amountSen;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final planned = AppMoneyFormatter.formatRevealed(plannedSen);
    final amount = amountSen ?? 0;
    final body = amount > 0 && plannedSen > 0
        ? t.record.whisperWithAmount(item: itemName, planned: planned, percent: (amount * 100 / plannedSen).round())
        : t.record.whisperNoAmount(item: itemName, planned: planned);
    return Semantics(
      container: true,
      child: DsCard(
        key: const ValueKey('record-whisper'),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Diam (tanpa gerak berulang): lembar Catat harus tetap bisa
            // "settle" di uji dan tidak boros baterai saat mengetik.
            SvgPicture.asset(ClayIcons.mascot, width: 32, height: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.record.whisperTitle,
                    style: ds.typography.pixelCaption.copyWith(color: c.actionPrimary, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(body, style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Teks pengguna untuk [issue].
String draftIssueMessage(DraftIssue issue) => switch (issue) {
  DraftIssue.amountMissing => t.record.draftIssue.amountMissing,
  DraftIssue.amountMultiple => t.record.draftIssue.amountMultiple,
  DraftIssue.amountWithoutUnit => t.record.draftIssue.amountWithoutUnit,
  DraftIssue.amountAmbiguous => t.record.draftIssue.amountAmbiguous,
  DraftIssue.currencyUnsupported => t.record.draftIssue.currencyUnsupported,
  DraftIssue.walletUnknown => t.record.draftIssue.walletUnknown,
  DraftIssue.transferSourceMissing => t.record.draftIssue.transferSourceMissing,
  DraftIssue.transferTargetMissing => t.record.draftIssue.transferTargetMissing,
  DraftIssue.categoryUnknown => t.record.draftIssue.categoryUnknown,
  DraftIssue.dateUnclear => t.record.draftIssue.dateUnclear,
  DraftIssue.kindUnclear => t.record.draftIssue.kindUnclear,
};
