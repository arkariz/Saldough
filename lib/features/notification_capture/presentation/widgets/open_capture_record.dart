import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_resolver.dart';
import 'package:saldough/features/notification_capture/domain/usecases/capture_inbox_actions.dart';
import 'package:saldough/features/notification_capture/presentation/navigation/notification_capture_route_keys.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Masukan CATAT untuk kartu [entry]. Bila draf cocok dengan satu kemunculan
/// rutin ([match]), CATAT terisi kategori dan catatan dari rutin (yang kosong
/// saja) dan transaksinya tertaut ke kemunculan itu (ADR-035 §3.4).
RecordSheetInput recordSheetInputFor(
  CaptureInboxEntry entry,
  OccurrenceMatch? match, {
  void Function(RecordSavedInfo info)? onSaved,
  String? budgetItemId,
}) {
  if (match == null) {
    return RecordSheetInput(draft: entry.draft, onSaved: onSaved, initialBudgetItemId: budgetItemId);
  }
  return RecordSheetInput(
    onSaved: onSaved,
    draft: enrichFromPlan(entry.draft, match),
    occurrenceRule: match.rule,
    occurrenceDate: match.date,
  );
}

/// Membuka CATAT terisi untuk [entry]; `true` bila disimpan.
///
/// [onSaved] menerima kategori dan catatan akhir sesudah tersimpan (belajar, E1).
Future<bool> openCaptureRecord(
  BuildContext context,
  CaptureInboxEntry entry,
  OccurrenceMatch? match, {
  void Function(RecordSavedInfo info)? onSaved,
  String? budgetItemId,
}) async =>
    await context.pushRoute<RecordSheetInput, bool>(
      RecordRouteKeys.sheet,
      recordSheetInputFor(entry, match, onSaved: onSaved, budgetItemId: budgetItemId),
    ) ??
    false;

/// Pintu "Cek" dari Beranda dan Riwayat (ADR-044 §3.8): bila hanya satu
/// tangkapan menunggu, langsung ke CATAT terisi (lewat Simpan: 2 ketuk), bukan
/// lewat kotak masuk; selain itu membuka kotak masuk. Tidak melewati keputusan
/// pengguna: CATAT tetap formulir yang ditinjau.
Future<void> openCaptureInbox(BuildContext context, GetIt container) async {
  final inbox = (await container<NotificationCaptureStore>().loadInbox()).getOrElse((_) => const []);
  if (!context.mounted) return;
  if (inbox.length != 1) {
    await context.pushRoute(NotificationCaptureRouteKeys.inbox, const EmptyInput());
    return;
  }
  final entry = inbox.single;
  final actions = container<CaptureInboxActions>();
  final matches = await actions.matchesFor([entry]);
  final match = matches[entry.id];
  final suggestion = (await actions.budgetSuggestionsFor([entry], matches))[entry.id];
  if (!context.mounted) return;
  RecordSavedInfo? savedInfo;
  final saved = await openCaptureRecord(
    context,
    entry,
    match,
    budgetItemId: suggestion?.itemId,
    onSaved: (info) => savedInfo = info,
  );
  if (saved) {
    await actions.remove(entry.id);
    // Tanpa Batalkan di jalur ini (tidak ada snackbar): kategori baru tetap diingat.
    await actions.rememberCategory(entry, categoryId: savedInfo?.categoryId, note: savedInfo?.note ?? '');
    await actions.rememberWallet(entry, walletId: savedInfo?.walletId);
    await actions.rememberBudgetItem(
      entry,
      budgetItemId: savedInfo?.budgetItemId,
      suggestedItemId: suggestion?.itemId,
    );
  }
}
