import 'dart:convert';
import 'dart:typed_data';

import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/shared/transaction/domain/source_icon_repository.dart';
import 'package:saldough/shared/transaction/source_icons.dart';

/// [SourceIconRepository] di atas [KeyValueStorage]: satu dokumen per ikon,
/// `source_icon/<id>`. Setiap baca dan tulis yang berhasil ikut mengisi
/// cache tampilan [SourceIcons].
final class SourceIconRepositoryImpl with RepositoryGuard implements SourceIconRepository {
  /// Membuat [SourceIconRepositoryImpl] di atas [_storage].
  const SourceIconRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<Uint8List> _store(String id) => StoredValue<Uint8List>.json(
    key: StorageKey(namespace: 'source_icon', name: id),
    fromJson: (json) => base64Decode(json['png'] as String),
    toJson: (png) => {'png': base64Encode(png)},
    storage: _storage,
  );

  @override
  Future<Either<Failure, String>> save(Uint8List png) => guard(() async {
    final id = sourceIconIdOf(png);
    final store = _store(id);
    if (await store.read() == null) await store.write(png);
    SourceIcons.put(id, png);
    return id;
  });

  @override
  Future<Either<Failure, Uint8List?>> read(String id) => guard(() async {
    final png = await _store(id).read();
    if (png != null) SourceIcons.put(id, png);
    return png;
  });
}
