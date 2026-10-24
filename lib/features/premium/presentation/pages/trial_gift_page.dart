import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/premium/domain/trial_gift.dart';
import 'package:saldough/features/premium/presentation/widgets/plus_tile.dart';

/// Layar hadiah uji coba (D-1, design `PlusHadiah`): bila tanggal gajian belum
/// pernah dipilih, menanyakannya dulu dengan kisi tanggal dan menunjukkan
/// kapan Plus berakhir untuk pilihan itu; lalu "Plus aktif sampai {tanggal},
/// akhir periode pertamamu." dengan satu tombol. Menyebut tanggal, bukan hari.
///
/// Menandai hadiah sudah ditampilkan begitu layar hadiah (bukan pertanyaan)
/// tampil, supaya tanggal akhir tidak bergeser lagi.
class TrialGiftPage extends StatefulWidget {
  /// Membuat [TrialGiftPage].
  const TrialGiftPage({required this.info, required this.gift, super.key});

  /// Keadaan uji coba saat layar dibuka.
  final TrialGiftInfo info;

  /// Penyimpanan tanggal gajian dan penanda tampil.
  final TrialGift gift;

  @override
  State<TrialGiftPage> createState() => _TrialGiftPageState();
}

class _TrialGiftPageState extends State<TrialGiftPage> {
  FinancialMonthStart _pick = const FinancialMonthStart.day(25);
  late DateTime _endsOn = widget.info.endsOn;
  late bool _asking = widget.info.needsPayday;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (!_asking) unawaited(widget.gift.markSeen());
  }

  DateTime get _preview => trialEndsOn(
    widget.info.start,
    ActiveFinancialMonth.schedule.changedOn(DateTime.now(), _pick),
    minDays: widget.info.minDays,
  );

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final endsOn = await widget.gift.setPayday(_pick);
    if (!mounted) return;
    if (endsOn == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.common.genericErrorMessage)));
      return;
    }
    setState(() {
      _endsOn = endsOn;
      _asking = false;
      _saving = false;
    });
    unawaited(widget.gift.markSeen());
  }

  @override
  Widget build(BuildContext context) {
    final texts = t.premium.gift;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(title: Text(texts.brand)),
      body: SafeArea(
        child: _asking
            ? ListView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(texts.askTitle, style: textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.space2),
                        Text(texts.askBody, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.space2),
                    child: AppDayGrid(selected: _pick, onSelected: (start) => setState(() => _pick = start)),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Semantics(
                    liveRegion: true,
                    child: Row(
                      children: [
                        AppIcon(IconKey.plus, color: colors.brandInk),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Text(
                            texts.endLine(date: CycleMonthFormatter.formatDayMonth(_preview)),
                            style: textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PlusTile(IconKey.plus, size: 72),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        texts.title(date: CycleMonthFormatter.formatDayMonth(_endsOn)),
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        texts.body,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: AppStickyBar(
        child: _asking
            ? AppButton(
                label: _pick.isLastDay ? texts.confirmLast : texts.confirmDay(day: _pick.day!),
                expand: true,
                loading: _saving,
                onPressed: _confirm,
              )
            : AppButton(label: texts.start, expand: true, onPressed: () => Navigator.of(context).maybePop()),
      ),
    );
  }
}
