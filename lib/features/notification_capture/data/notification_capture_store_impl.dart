import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/shared/capture/capture.dart';

const _settingsKey = StorageKey(namespace: 'settings', name: 'notification_capture');
const _patternsKey = StorageKey(namespace: 'capture', name: 'notification_patterns');
const _inboxKey = StorageKey(namespace: 'capture', name: 'inbox');
const _autoKey = StorageKey(namespace: 'capture', name: 'auto_recorded');
const _processedKey = StorageKey(namespace: 'capture', name: 'processed_ids');

/// [NotificationCaptureStore] di atas [KeyValueStorage] (ADR-032): satu
/// dokumen `{schemaVersion, ...}` per kunci. Nilai enum disimpan sebagai nama;
/// nama yang tidak dikenal (versi lebih baru) jatuh ke bawaan.
final class NotificationCaptureStoreImpl with RepositoryGuard implements NotificationCaptureStore {
  /// Membuat [NotificationCaptureStoreImpl] di atas [_storage].
  const NotificationCaptureStoreImpl({required this._storage});

  /// Versi skema dokumen.
  static const schemaVersion = 1;

  final KeyValueStorage _storage;

  StoredValue<List<Map<String, dynamic>>> _list(StorageKey key) => StoredValue<List<Map<String, dynamic>>>.json(
    key: key,
    fromJson: (json) => [for (final item in json['items'] as List? ?? const []) Map<String, dynamic>.from(item as Map)],
    toJson: (items) => {'schemaVersion': schemaVersion, 'items': items},
    storage: _storage,
  );

  StoredValue<Map<String, dynamic>> get _settings => StoredValue<Map<String, dynamic>>.json(
    key: _settingsKey,
    fromJson: (json) => json,
    toJson: (json) => json,
    storage: _storage,
  );

  @override
  Future<Either<Failure, NotificationCaptureSettings>> loadSettings() => guard(() async {
    final json = await _settings.read();
    return json == null ? const NotificationCaptureSettings() : _settingsFromJson(json);
  });

  @override
  Future<Either<Failure, Unit>> saveSettings(NotificationCaptureSettings settings) =>
      guardVoid(() => _settings.write(_settingsToJson(settings)));

  @override
  Future<Either<Failure, List<NotificationPattern>>> loadPatterns() => guard(
    () async => [
      for (final j in await _list(_patternsKey).read() ?? const <Map<String, dynamic>>[]) _patternFromJson(j),
    ],
  );

  @override
  Future<Either<Failure, Unit>> savePatterns(List<NotificationPattern> patterns) =>
      guardVoid(() => _list(_patternsKey).write([for (final p in patterns) _patternToJson(p)]));

  @override
  Future<Either<Failure, List<CaptureInboxEntry>>> loadInbox() => guard(
    () async => [for (final j in await _list(_inboxKey).read() ?? const <Map<String, dynamic>>[]) _inboxFromJson(j)],
  );

  @override
  Future<Either<Failure, Unit>> saveInbox(List<CaptureInboxEntry> entries) =>
      guardVoid(() => _list(_inboxKey).write([for (final e in entries) _inboxToJson(e)]));

  @override
  Future<Either<Failure, List<AutoRecordedEntry>>> loadAutoRecorded() => guard(
    () async => [for (final j in await _list(_autoKey).read() ?? const <Map<String, dynamic>>[]) _autoFromJson(j)],
  );

  @override
  Future<Either<Failure, Unit>> saveAutoRecorded(List<AutoRecordedEntry> entries) =>
      guardVoid(() => _list(_autoKey).write([for (final e in entries) _autoToJson(e)]));

  @override
  Future<Either<Failure, Map<String, DateTime>>> loadProcessedIds() => guard(() async {
    final items = await _list(_processedKey).read() ?? const [];
    return {for (final j in items) j['id'] as String: DateTime.parse(j['at'] as String)};
  });

  @override
  Future<Either<Failure, Unit>> saveProcessedIds(Map<String, DateTime> ids) => guardVoid(
    () => _list(_processedKey).write([
      for (final e in ids.entries) {'id': e.key, 'at': e.value.toIso8601String()},
    ]),
  );
}

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

Map<String, dynamic> _settingsToJson(NotificationCaptureSettings s) => {
  'schemaVersion': NotificationCaptureStoreImpl.schemaVersion,
  'enabled': s.enabled,
  'delivery': s.delivery.name,
  'autoRecordLevel': s.autoRecordLevel.name,
  'disabledBuiltInPatternIds': s.disabledBuiltInPatternIds.toList(),
  'sources': [
    for (final source in s.sources)
      {
        'packageName': source.packageName,
        'appLabel': source.appLabel,
        'keywords': source.keywords,
        'walletId': source.walletId,
        'enabled': source.enabled,
      },
  ],
};

NotificationCaptureSettings _settingsFromJson(Map<String, dynamic> j) => NotificationCaptureSettings(
  enabled: j['enabled'] as bool? ?? false,
  delivery: _enum(NotificationDelivery.values, j['delivery'], NotificationDelivery.inboxOnly),
  autoRecordLevel: _enum(AutoRecordLevel.values, j['autoRecordLevel'], AutoRecordLevel.reviewAll),
  disabledBuiltInPatternIds: {for (final id in j['disabledBuiltInPatternIds'] as List? ?? const []) id as String},
  sources: [
    for (final raw in j['sources'] as List? ?? const [])
      if (raw case final Map<dynamic, dynamic> s)
        NotificationSource(
          packageName: s['packageName'] as String,
          appLabel: s['appLabel'] as String? ?? s['packageName'] as String,
          keywords: [for (final k in s['keywords'] as List? ?? const []) k as String],
          walletId: s['walletId'] as String?,
          enabled: s['enabled'] as bool? ?? true,
        ),
  ],
);

Map<String, dynamic> _patternToJson(NotificationPattern p) => {
  'id': p.id,
  'packageName': p.packageName,
  'label': p.label,
  'template': p.template,
  'kind': p.kind.name,
  'categoryId': p.categoryId,
  'transferWalletId': p.transferWalletId,
};

NotificationPattern _patternFromJson(Map<String, dynamic> j) => NotificationPattern(
  id: j['id'] as String,
  packageName: j['packageName'] as String,
  label: j['label'] as String? ?? '',
  template: j['template'] as String,
  kind: _enum(NotificationPatternKind.values, j['kind'], NotificationPatternKind.expense),
  categoryId: j['categoryId'] as String?,
  transferWalletId: j['transferWalletId'] as String?,
);

Map<String, dynamic> _draftToJson(RecordDraft d) => {
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

RecordDraft _draftFromJson(Map<dynamic, dynamic> j) => RecordDraft(
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

Map<String, dynamic> _inboxToJson(CaptureInboxEntry e) => {
  'id': e.id,
  'packageName': e.packageName,
  'appLabel': e.appLabel,
  'text': e.text,
  'capturedAt': e.capturedAt.toIso8601String(),
  'draft': _draftToJson(e.draft),
  'possibleDuplicate': e.possibleDuplicate,
  'iconId': ?e.iconId,
};

CaptureInboxEntry _inboxFromJson(Map<String, dynamic> j) => CaptureInboxEntry(
  id: j['id'] as String,
  packageName: j['packageName'] as String,
  appLabel: j['appLabel'] as String? ?? '',
  text: j['text'] as String? ?? '',
  capturedAt: DateTime.parse(j['capturedAt'] as String),
  draft: _draftFromJson(j['draft'] as Map),
  possibleDuplicate: j['possibleDuplicate'] as bool? ?? false,
  iconId: j['iconId'] as String?,
);

Map<String, dynamic> _autoToJson(AutoRecordedEntry e) => {
  'captureId': e.captureId,
  'transactionId': e.transactionId,
  'transactionDate': e.transactionDate.toIso8601String(),
  'kind': e.kind.name,
  'amountSen': e.amountSen,
  'appLabel': e.appLabel,
  'recordedAt': e.recordedAt.toIso8601String(),
  'note': e.note,
  'categoryId': ?e.categoryId,
  'iconId': ?e.iconId,
  'capturedAt': ?e.capturedAt?.toIso8601String(),
};

AutoRecordedEntry _autoFromJson(Map<String, dynamic> j) => AutoRecordedEntry(
  captureId: j['captureId'] as String,
  transactionId: j['transactionId'] as String,
  transactionDate: DateTime.parse(j['transactionDate'] as String),
  kind: _enum(DraftKind.values, j['kind'], DraftKind.expense),
  amountSen: j['amountSen'] as int,
  appLabel: j['appLabel'] as String? ?? '',
  recordedAt: DateTime.parse(j['recordedAt'] as String),
  note: j['note'] as String? ?? '',
  categoryId: j['categoryId'] as String?,
  iconId: j['iconId'] as String?,
  capturedAt: switch (j['capturedAt']) {
    final String at => DateTime.parse(at),
    _ => null,
  },
);
