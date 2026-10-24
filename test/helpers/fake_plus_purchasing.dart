import 'dart:async';

import 'package:saldough/features/premium/domain/plus_purchasing.dart';
import 'package:saldough/features/premium/domain/purchase_models.dart';

/// [PlusPurchasing] palsu: isi [plans] dan [result] sesuai kebutuhan uji.
/// [gate] menahan [offered] sampai dilepas (keadaan memuat).
final class FakePlusPurchasing implements PlusPurchasing {
  FakePlusPurchasing({this.selling = true, OfferedPlans? plans})
    : plans = plans ?? defaultPlans;

  static const yearly = PlanOption(
    kind: PlusPlanKind.yearly,
    priceText: 'Rp179.000',
    perMonthText: 'Rp14.917',
    handle: 'yearly',
  );
  static const monthly = PlanOption(
    kind: PlusPlanKind.monthly,
    priceText: 'Rp25.000',
    handle: 'monthly',
  );
  static const OfferedPlans defaultPlans = OfferedPlans(
    offering: null,
    options: [monthly, yearly],
  );

  bool selling;
  OfferedPlans plans;
  BuyResult result = const BuyDone();
  Completer<void>? gate;
  Completer<BuyResult>? buyGate;
  final bought = <PlanOption>[];
  int offeredCalls = 0;

  @override
  bool get isSelling => selling;

  @override
  Future<OfferedPlans> offered() async {
    offeredCalls++;
    await gate?.future;
    return plans;
  }

  @override
  Future<BuyResult> buy(PlanOption option) async {
    bought.add(option);
    return buyGate == null ? result : buyGate!.future;
  }

  @override
  Future<void> restore() async {}
}
