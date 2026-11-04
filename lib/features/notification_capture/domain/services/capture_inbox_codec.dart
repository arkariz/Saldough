import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/shared/capture/capture.dart';

// JSON kartu kotak masuk dan draf (ADR-032 §3.6). Dipakai penyimpanan kotak
// masuk dan sebagai muatan jurnal mesin tanpa layar (ADR-044 §3.5, T-26.10),
// supaya satu bentuk untuk keduanya.

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

/// JSON [RecordDraft].
Map<String, dynamic> captureDraftToJson(RecordDraft d) => {
  'kind': d.kind.name,
  'amountSen': d.amountSen,
  'walletId': d.walletId,
  'toWalletId': d.toWalletId,
  'categoryId': d.categoryId,
  'note': d.note,
  'date': d.date?.toIso8601String(),
  'issues': [for (final i in d.issues) i.name],
  'sourceText': d.sourceText,
  'sourceIconId': ?d.sourceIconId,
};

/// Kebalikan [captureDraftToJson].
RecordDraft captureDraftFromJson(Map<dynamic, dynamic> j) => RecordDraft(
  kind: _enum(DraftKind.values, j['kind'], DraftKind.expense),
  amountSen: j['amountSen'] as int?,
  walletId: j['walletId'] as String?,
  toWalletId: j['toWalletId'] as String?,
  categoryId: j['categoryId'] as String?,
  note: j['note'] as String? ?? '',
  date: switch (j['date']) {
    final String s => DateTime.parse(s),
    _ => null,
  },
  issues: {
    for (final name in j['issues'] as List? ?? const [])
      for (final issue in DraftIssue.values)
        if (issue.name == name) issue,
  },
  sourceText: j['sourceText'] as String?,
  sourceIconId: j['sourceIconId'] as String?,
);

/// JSON [CaptureInboxEntry].
Map<String, dynamic> captureInboxEntryToJson(CaptureInboxEntry e) => {
  'id': e.id,
  'packageName': e.packageName,
  'appLabel': e.appLabel,
  'text': e.text,
  'capturedAt': e.capturedAt.toIso8601String(),
  'draft': captureDraftToJson(e.draft),
  'possibleDuplicate': e.possibleDuplicate,
  'iconId': ?e.iconId,
  'patternId': ?e.patternId,
  'reviewReason': ?e.reviewReason?.name,
};

/// Kebalikan [captureInboxEntryToJson].
CaptureInboxEntry captureInboxEntryFromJson(Map<String, dynamic> j) => CaptureInboxEntry(
  id: j['id'] as String,
  packageName: j['packageName'] as String,
  appLabel: j['appLabel'] as String? ?? '',
  text: j['text'] as String? ?? '',
  capturedAt: DateTime.parse(j['capturedAt'] as String),
  draft: captureDraftFromJson(j['draft'] as Map),
  possibleDuplicate: j['possibleDuplicate'] as bool? ?? false,
  iconId: j['iconId'] as String?,
  patternId: j['patternId'] as String?,
  reviewReason: CaptureReviewReason.values.where((r) => r.name == j['reviewReason']).firstOrNull,
);
