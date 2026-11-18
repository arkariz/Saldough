import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/investment/domain/price_sheet.dart';

const _linkKey = StorageKey(namespace: 'investment', name: 'sheet_link');

/// [PriceSheetLinkStore] di kunci `investment_sheet_link` (ADR-051 §3.3), ikut
/// cadangan.
final class PriceSheetLinkStoreImpl with RepositoryGuard implements PriceSheetLinkStore {
  /// Membuat [PriceSheetLinkStoreImpl].
  const PriceSheetLinkStoreImpl({required this._storage});

  final KeyValueStorage _storage;

  /// Versi skema dokumen tautan.
  static const schemaVersion = 1;

  StoredValue<PriceSheetLink> get _store => StoredValue<PriceSheetLink>.json(
    key: _linkKey,
    fromJson: (json) => PriceSheetLink(
      sheetId: json['sheetId'] as String,
      lastFetchedAt: switch (json['lastFetchedAt']) {
        final String at => DateTime.parse(at),
        _ => null,
      },
    ),
    toJson: (link) => {
      'schemaVersion': schemaVersion,
      'sheetId': link.sheetId,
      if (link.lastFetchedAt case final at?) 'lastFetchedAt': at.toIso8601String(),
    },
    storage: _storage,
  );

  @override
  Future<Either<Failure, PriceSheetLink?>> read() => guard(_store.read);

  @override
  Future<Either<Failure, Unit>> save(PriceSheetLink link) => guardVoid(() => _store.write(link));

  @override
  Future<Either<Failure, Unit>> clear() => guardVoid(_store.remove);
}
