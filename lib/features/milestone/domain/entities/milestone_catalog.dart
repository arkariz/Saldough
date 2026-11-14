import 'package:saldough/features/milestone/domain/entities/milestone_def.dart';

/// Katalog tonggak R1 (GAMIFICATION §5, ADR-046 §3.2): delapan stempel dari
/// fakta yang sudah ada. Menambah stempel biasa = satu baris di sini.
///
/// Tidak ada tonggak berbasis jumlah transaksi, nominal, arah belanja, atau hari
/// berturut-turut (G-2).
const milestoneCatalog = <MilestoneDef>[
  MilestoneDef(
    id: 'wallet_first',
    group: MilestoneGroup.start,
    kind: MilestoneKind.firstTime,
    fact: MilestoneFact.walletExists,
  ),
  MilestoneDef(
    id: 'record_first',
    group: MilestoneGroup.start,
    kind: MilestoneKind.firstTime,
    fact: MilestoneFact.recordExists,
  ),
  MilestoneDef(
    id: 'period_tidy',
    group: MilestoneGroup.tidy,
    kind: MilestoneKind.closedPeriod,
    fact: MilestoneFact.tidyPeriodClosed,
  ),
  MilestoneDef(
    id: 'recurring_clear',
    group: MilestoneGroup.tidy,
    kind: MilestoneKind.closedPeriod,
    fact: MilestoneFact.recurringClearClosed,
  ),
  MilestoneDef(
    id: 'inbox_clear',
    group: MilestoneGroup.tidy,
    kind: MilestoneKind.queueCleared,
    fact: MilestoneFact.inboxCleared,
    revealOnUse: true,
  ),
  MilestoneDef(
    id: 'backup_first',
    group: MilestoneGroup.safe,
    kind: MilestoneKind.firstTime,
    fact: MilestoneFact.backupDone,
  ),
  MilestoneDef(
    id: 'budget_first',
    group: MilestoneGroup.plan,
    kind: MilestoneKind.firstTime,
    fact: MilestoneFact.budgetItemLinked,
  ),
  MilestoneDef(
    id: 'freelance_paid',
    group: MilestoneGroup.plan,
    kind: MilestoneKind.firstTime,
    fact: MilestoneFact.freelancePaid,
    revealOnUse: true,
  ),
];
