import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/wallet/data/wallet_model.dart';
import 'package:saldough/shared/wallet/domain/wallet.dart';
import 'package:saldough/shared/wallet/domain/wallet_repository.dart';

const _walletsKey = StorageKey(namespace: 'wallet', name: 'all');

/// Implementasi [WalletRepository] di atas [KeyValueStorage], mengikuti pola
/// `GoalRepositoryImpl`.
///
/// Seluruh dompet disimpan sebagai satu dokumen JSON — jumlah dompet
/// pemilik kecil (belasan, bukan ribuan), berbeda dari `Transaction` yang
/// dipartisi per bulan (lihat ADR-012).
final class WalletRepositoryImpl with RepositoryGuard implements WalletRepository {
  /// Membuat [WalletRepositoryImpl] di atas [_storage].
  const WalletRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<WalletModel>> get _store => StoredValue<List<WalletModel>>.json(
        key: _walletsKey,
        fromJson: (json) => (json['items'] as List<dynamic>)
            .map((e) => WalletModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        toJson: (models) => {
          'schemaVersion': WalletModel.schemaVersion,
          'items': models.map((m) => m.toJson()).toList(),
        },
        storage: _storage,
      );

  @override
  Future<Either<Failure, List<Wallet>>> listWallets() => guard(() async {
        final models = await _store.read();
        return (models ?? const []).map((m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, Unit>> saveWallet(Wallet wallet) => guardVoid(() async {
        final models = await _store.read() ?? <WalletModel>[];
        final next = [
          ...models.where((m) => m.id != wallet.id),
          WalletModel.fromEntity(wallet),
        ];
        await _store.write(next);
      });

  @override
  Future<Either<Failure, Unit>> deleteWallet(String id) => guardVoid(() async {
        final models = await _store.read() ?? <WalletModel>[];
        await _store.write(models.where((m) => m.id != id).toList());
      });
}
