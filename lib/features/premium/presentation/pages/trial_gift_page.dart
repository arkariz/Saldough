import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/premium/domain/trial_gift.dart';
import 'package:saldough/features/premium/presentation/widgets/plus_celebration.dart';
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
    if (!_asking) _shown();
  }

  /// Layar hadiah tampil: tanggal akhir dikunci dan momen pertama (pilar
  /// mencatat) dicatat.
  void _shown() {
    unawaited(widget.gift.markSeen());
    AppAnalytics.log(PremiumEvents.trialMoment(pillar: 'record'));
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
      ScaffoldMessenger.of(context).showAppSnackBar(SnackBar(content: Text(t.common.genericErrorMessage)));
      return;
    }
    setState(() {
      _endsOn = endsOn;
      _asking = false;
      _saving = false;
    });
    _shown();
  }

  @override
  Widget build(BuildContext context) {
    final texts = t.premium.gift;
    final ds = context.ds;
    final c = ds.colors;
    return Scaffold(
      appBar: AppBar(title: Text(texts.brand, style: ds.typography.headlineMd), centerTitle: false),
      body: SafeArea(
        child: _asking
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DsCard(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PlusTile(IconKey.plus),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(texts.askTitle, style: ds.typography.titleMd.copyWith(fontSize: 17)),
                              const SizedBox(height: 4),
                              Text(texts.askBody, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DsCard(
                    padding: const EdgeInsets.all(8),
                    child: AppDayGrid(selected: _pick, onSelected: (start) => setState(() => _pick = start)),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.actionPrimary.withValues(alpha: 0.08),
                        borderRadius: DsRadius.lgAll,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(Icons.star_rounded, color: c.actionPrimary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                texts.endLine(date: CycleMonthFormatter.formatDayMonth(_preview)),
                                style: ds.typography.titleMd.copyWith(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PlusCelebrationHero(
                      celebrate: true,
                      title: texts.title(date: CycleMonthFormatter.formatDayMonth(_endsOn)),
                      body: texts.body,
                      chips: [t.premium.plusBadge],
                    ),
                    const SizedBox(height: 24),
                    const PlusUnlockedList(),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: DsStickyBar(
        child: _asking
            ? DsButton(
                label: _pick.isLastDay ? texts.confirmLast : texts.confirmDay(day: _pick.day!),
                expand: true,
                onPressed: _saving ? null : _confirm,
              )
            : DsButton(label: texts.start, expand: true, onPressed: () => Navigator.of(context).maybePop()),
      ),
    );
  }
}
