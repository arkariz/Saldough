import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_frame.dart';

/// Layar pilihan yang muncul saat CATAT ditekan (FR-REC-001) — tiga
/// pilihan: catat pemasukan, catat pengeluaran, catat transfer. Memilih
/// satu menutup lembar ini dan mengembalikan [RecordChoice]-nya; pemanggil
/// (`AppShellPage`) yang membuka formulir berikutnya. Tata letaknya mengikuti
/// rujukan visual `pixel_kas_catat_transaksi`.
///
/// Tiap bagian dibedakan menurut fungsinya, supaya tidak terbaca sebagai
/// empat kartu serupa: kop berupa bilah judul datar (bukan kartu), kartu
/// info berupa pita tipis tanpa bayangan, dan ketiga kartu jenis masing-masing
/// bernuansa warna jenisnya (garis aksen, latar, bilah aksi) serta memuat
/// diagram alur uang yang menjelaskan akibatnya -- pemasukan `Luar → Dompet`,
/// pengeluaran `Dompet → Luar`, transfer `Dompet asal → Dompet tujuan`.
///
/// Memuat kartu info yang menyatakan prinsip produk paling dasar Saldough --
/// aplikasi ini MENCATAT, bukan MELAKUKAN, tidak pernah memindahkan uang
/// sendiri -- sebelumnya tidak disebutkan di mana pun dalam alur CATAT.
///
/// ⚠ Kartu "Catat ke Freelance Worklog" di rujukan visual belum dibangun:
/// fitur Freelance baru ada di Fase 5, dan kartu yang mengarah ke layar yang
/// belum ada tidak ditampilkan (pola yang sama dengan baris anggaran di
/// rincian transaksi).
class RecordChoiceSheet extends StatelessWidget {
  /// Membuat [RecordChoiceSheet].
  const RecordChoiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            const SizedBox(height: AppSpacing.md),
            RecordNotice(title: t.record.noticeTitle, body: t.record.disclaimerMessage, flat: true),
            const SizedBox(height: AppSpacing.lg),
            _ChoiceCard(
              kind: TransactionKind.income,
              title: t.record.incomeAction,
              description: t.record.incomeSubtitle,
              badge: t.record.incomeBadge,
              flow: [
                _FlowStep(t.record.flowOutside),
                _FlowStep(t.record.flowWallet, sign: _Sign.plus),
              ],
              examples: [
                t.record.categorySuggestionSalary,
                t.record.categorySuggestionBonus,
                t.record.categorySuggestionSales,
                t.record.categorySuggestionGift,
              ],
              effect: t.record.incomeEffectLabel,
              pickLabel: t.record.pickIncomeAction,
              onTap: () => Navigator.of(context).pop(RecordChoice.income),
            ),
            const SizedBox(height: AppSpacing.md),
            _ChoiceCard(
              kind: TransactionKind.expense,
              title: t.record.expenseAction,
              description: t.record.expenseSubtitle,
              badge: t.record.expenseBadge,
              flow: [
                _FlowStep(t.record.flowWallet, sign: _Sign.minus),
                _FlowStep(t.record.flowOutside),
              ],
              examples: [
                t.record.categorySuggestionFood,
                t.record.categorySuggestionShopping,
                t.record.categorySuggestionBills,
                t.record.categorySuggestionTransport,
              ],
              effect: t.record.expenseEffectLabel,
              pickLabel: t.record.pickExpenseAction,
              onTap: () => Navigator.of(context).pop(RecordChoice.expense),
            ),
            const SizedBox(height: AppSpacing.md),
            _ChoiceCard(
              kind: TransactionKind.transfer,
              title: t.record.transferAction,
              description: t.record.transferSubtitle,
              badge: t.record.transferBadge,
              flow: [
                _FlowStep(t.record.flowSourceWallet, sign: _Sign.minus),
                _FlowStep(t.record.flowTargetWallet, sign: _Sign.plus),
              ],
              examples: [
                t.record.transferExampleCash,
                t.record.transferExampleTopUp,
                t.record.transferExampleMove,
              ],
              effect: t.record.transferEffectLabel,
              pickLabel: t.record.pickTransferAction,
              onTap: () => Navigator.of(context).pop(RecordChoice.transfer),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kop layar: label langkah, judul besar, subjudul, dan tombol tutup -- satu
/// bilah datar tanpa kartu, sehingga jelas berbeda dari kartu pilihan di
/// bawahnya.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.record.choiceStepLabel.toUpperCase(),
                    style: transactionLabelStyle(context, color: colors.accent),
                  ),
                  const SizedBox(height: 2),
                  Text(t.record.sheetTitle, style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: colors.surfaceHigh, borderRadius: BorderRadius.circular(8)),
                child: const AppIcon(IconKey.close),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(t.record.sheetSubtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textMuted)),
      ],
    );
  }
}

/// Tanda pada satu langkah diagram alur: `+` saldo naik, `−` saldo turun,
/// tanpa tanda untuk pihak di luar aplikasi.
enum _Sign { none, plus, minus }

class _FlowStep {
  const _FlowStep(this.label, {this.sign = _Sign.none});

  final String label;
  final _Sign sign;
}

/// Satu kartu pilihan jenis. Identitas fungsinya: garis aksen dan latar
/// berwarna jenis, kotak ikon, lencana, diagram alur uang, contoh, dan bilah
/// aksi penuh berwarna jenis di dasar kartu.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.kind,
    required this.title,
    required this.description,
    required this.badge,
    required this.flow,
    required this.examples,
    required this.effect,
    required this.pickLabel,
    required this.onTap,
  });

  final TransactionKind kind;
  final String title;
  final String description;
  final String badge;
  final List<_FlowStep> flow;
  final List<String> examples;
  final String effect;
  final String pickLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ink = colors.kindInk(kind);
    final fill = colors.kindFill(kind);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: TransactionSlab(
        color: colors.tinted(fill, 0.07),
        shadowColor: ink,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredBox(color: fill, child: const SizedBox(width: 8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: colors.tinted(fill, 0.22),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color.lerp(ink, colors.textPrimary, 0.4)!,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: AppIcon(recordKindIcon(kind), size: 36),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Lencana jenis solid, turun baris kalau
                                      // judul panjang atau teks besar.
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: AppSpacing.sm,
                                        runSpacing: 4,
                                        children: [
                                          Text(title, style: Theme.of(context).textTheme.titleLarge),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: ink,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              badge.toUpperCase(),
                                              style: transactionLabelStyle(
                                                context,
                                                size: 9,
                                                color: colors.cardBackground,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        description,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _FlowRow(steps: flow),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  t.record.examplesLabel,
                                  style: transactionLabelStyle(context, color: colors.textMuted),
                                ),
                                for (final example in examples)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceMid,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      example,
                                      style: transactionLabelStyle(context, size: 11, color: colors.textPrimary),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Bilah aksi penuh berwarna jenis: akibat pada saldo di
                      // kiri, ajakan memilih di kanan.
                      Container(
                        color: ink,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: 2,
                          children: [
                            Text(
                              effect.toUpperCase(),
                              style: transactionLabelStyle(context, color: colors.cardBackground),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // `Flexible`: ajakan panjang (teks besar)
                                // membungkus, tidak meluap di sisi kanan.
                                Flexible(
                                  child: Text(
                                    pickLabel,
                                    style: transactionLabelStyle(context, size: 12, color: colors.cardBackground),
                                  ),
                                ),
                                AppIcon(IconKey.chevronRight, size: 20, color: colors.cardBackground),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Diagram alur uang satu baris: `[Luar] → [+ Dompet]`. Langkah yang menambah
/// saldo bernuansa hijau, yang mengurangi bernuansa merah, pihak luar netral.
class _FlowRow extends StatelessWidget {
  const _FlowRow({required this.steps});

  final List<_FlowStep> steps;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) Text('→', style: transactionLabelStyle(context, size: 14, color: colors.textMuted)),
          _FlowChip(step: steps[i]),
        ],
      ],
    );
  }
}

class _FlowChip extends StatelessWidget {
  const _FlowChip({required this.step});

  final _FlowStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (fill, ink, sign) = switch (step.sign) {
      _Sign.plus => (colors.tinted(colors.incomeFill, 0.2), colors.income, '+ '),
      _Sign.minus => (colors.tinted(colors.expenseFill, 0.2), colors.expense, '− '),
      _Sign.none => (colors.surfaceMid, colors.textMuted, ''),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(4)),
      child: Text('$sign${step.label}', style: transactionLabelStyle(context, size: 11, color: ink)),
    );
  }
}
