import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/budget/presentation/navigation/budget_route_keys.dart';
import 'package:saldough/features/plan/domain/payday_offer.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Kartu tawaran gajian di kepala Rencana › Bulan ini (FEATURE_DISCOVERY
/// §6.2): "Gajian tanggal {d}?" untuk pengguna lama yang sudah mencatat gaji
/// tetapi belum mengatur awal bulan keuangan. **Atur** membuka lembar Awal
/// bulan keuangan dengan tanggal itu sebagai saran; kartu boleh ditutup dan
/// tidak muncul lagi. Hanya menyarankan, tidak mengubah jadwal sendiri.
class PaydayOfferCard extends StatefulWidget {
  /// Membuat [PaydayOfferCard].
  const PaydayOfferCard({required this.container, this.now, super.key});

  /// Kontainer akar.
  final GetIt container;

  /// Jam untuk uji.
  final DateTime Function()? now;

  @override
  State<PaydayOfferCard> createState() => _PaydayOfferCardState();
}

class _PaydayOfferCardState extends State<PaydayOfferCard> {
  /// Berapa bulan ke belakang (termasuk bulan ini) dicari pemasukan Gaji.
  static const _lookbackMonths = 3;

  int? _day;

  @override
  void initState() {
    super.initState();
    ActiveFinancialMonth.notifier.addListener(_load);
    unawaited(_load());
  }

  @override
  void dispose() {
    ActiveFinancialMonth.notifier.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final c = widget.container;
    // Kosong bila bulan keuangan atau kategori tidak terdaftar (uji, platform).
    if (!c.isRegistered<FinancialMonthPreferenceRepository>() ||
        !c.isRegistered<CategoryRepository>() ||
        !c.isRegistered<TransactionRepository>()) {
      return;
    }
    final preferences = c<FinancialMonthPreferenceRepository>();
    final offer = (await preferences.loadOffer()).getOrElse(
      (_) => (changedByUser: false, offeredRuleIds: const <String>{}, paydayCardAnswered: false),
    );
    // Jawaban sudah ada: tak perlu membaca buku besar.
    int? day;
    if (!offer.changedByUser && !offer.paydayCardAnswered) {
      final categories = (await c<CategoryRepository>().listCategories()).getOrElse((_) => const <Category>[]);
      final salaryIds = {
        for (final category in categories)
          if (category.builtInKey == 'salary') category.id,
      };
      if (salaryIds.isNotEmpty) {
        final now = (widget.now ?? DateTime.now)();
        final ledger = <Transaction>[];
        for (var back = 0; back < _lookbackMonths; back++) {
          ledger.addAll(
            (await c<TransactionRepository>().listTransactionsInMonth(
              DateTime(now.year, now.month - back),
            )).getOrElse((_) => const <Transaction>[]),
          );
        }
        day = paydayOfferDay(
          ledger,
          salaryCategoryIds: salaryIds,
          schedule: ActiveFinancialMonth.schedule,
          offer: offer,
        );
      }
    }
    if (!mounted || day == _day) return;
    if (_day == null && day != null) AppAnalytics.log(DiscoveryEvents.paydayCard('shown'));
    setState(() => _day = day);
  }

  Future<void> _answer() async {
    final preferences = widget.container<FinancialMonthPreferenceRepository>();
    final offer = (await preferences.loadOffer()).getOrElse(
      (_) => (changedByUser: false, offeredRuleIds: const <String>{}, paydayCardAnswered: false),
    );
    await preferences.saveOffer((
      changedByUser: offer.changedByUser,
      offeredRuleIds: offer.offeredRuleIds,
      paydayCardAnswered: true,
    ));
  }

  Future<void> _close() async {
    AppAnalytics.log(DiscoveryEvents.paydayCard('closed'));
    await _answer();
    if (mounted) setState(() => _day = null);
  }

  Future<void> _set(int day) async {
    AppAnalytics.log(DiscoveryEvents.paydayCard('accepted'));
    // Tidak ditandai dijawab: bila lembar disimpan, `ActiveFinancialMonth`
    // berubah dan kartu hilang; bila dibatalkan, kartu tetap menawarkan.
    await context.pushRoute(
      BudgetRouteKeys.financialMonth,
      FinancialMonthInput(source: FinancialMonthSource.offer, initial: FinancialMonthStart.day(day)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    if (day == null) return const SizedBox.shrink();
    final texts = t.discovery.payday;
    final ds = context.ds;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DsReveal(
        child: DsCard(
          key: const ValueKey('payday-offer-card'),
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsIdleMotion(
                kind: DsIdleKind.float,
                child: DsIconTile.asset(asset: ClayIcons.coins, size: DsIconTileSize.lg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(texts.title(d: day), style: ds.typography.titleMd),
                    const SizedBox(height: 2),
                    Text(
                      texts.body(d: day),
                      style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 140,
                      child: DsInlineAction(
                        key: const ValueKey('payday-offer-set'),
                        tone: DsInlineActionTone.primary,
                        label: texts.action,
                        onPressed: () => unawaited(_set(day)),
                      ),
                    ),
                  ],
                ),
              ),
              DsIconButton(
                key: const ValueKey('payday-offer-close'),
                icon: Icons.close,
                label: t.common.close,
                onPressed: () => unawaited(_close()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
