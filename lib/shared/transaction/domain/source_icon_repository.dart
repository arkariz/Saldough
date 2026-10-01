import 'dart:typed_data';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';

/// Penyimpanan ikon notifikasi asal transaksi (ADR-032 §3.10): satu PNG per
/// ikon, beridentitas hash isinya, dipakai bersama banyak transaksi.
abstract interface class SourceIconRepository {
  /// Menyimpan [png] (idempoten) dan mengembalikan id-nya.
  Future<Either<Failure, String>> save(Uint8List png);

  /// PNG ber-id [id], atau `null` bila tidak ada.
  Future<Either<Failure, Uint8List?>> read(String id);
}

/// Id ikon dari isinya: dua FNV-1a 32-bit (benih berbeda) + panjang,
/// heksadesimal. Ikon yang sama selalu beridentitas sama, jadi tersimpan
/// sekali.
String sourceIconIdOf(Uint8List png) {
  int fnv(int seed) {
    var hash = seed;
    for (final byte in png) {
      hash = ((hash ^ byte) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  String hex(int value) => value.toRadixString(16).padLeft(8, '0');
  return '${hex(fnv(0x811c9dc5))}${hex(fnv(0x050c5d1f))}${png.length.toRadixString(16)}';
}
