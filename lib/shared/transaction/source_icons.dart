import 'dart:async';

import 'package:flutter/foundation.dart';

/// Cache tampilan ikon notifikasi asal transaksi (ADR-032 §3.10), pola yang
/// sama dengan `ActiveCategories`: widget membaca sinkron lewat [of]; ikon
/// yang belum termuat diminta ke [loader] sekali, lalu [notifier] berubah
/// dan widget yang mendengar membangun ulang.
abstract final class SourceIcons {
  SourceIcons._();

  /// Ikon yang sudah termuat, per id.
  static final ValueNotifier<Map<String, Uint8List>> notifier = ValueNotifier(const {});

  /// Pembaca dari penyimpanan, dipasang akar aplikasi. `null` (uji) = tanpa
  /// ikon.
  static Future<Uint8List?> Function(String id)? loader;

  static final _requested = <String>{};

  /// PNG ber-id [id] bila sudah termuat; bila belum, memintanya ke [loader]
  /// dan mengembalikan `null` untuk sementara.
  static Uint8List? of(String? id) {
    if (id == null) return null;
    final png = notifier.value[id];
    if (png != null) return png;
    final load = loader;
    // Di luar build: memuat bisa langsung mengubah [notifier].
    if (load != null && _requested.add(id)) scheduleMicrotask(() => unawaited(load(id)));
    return null;
  }

  /// Mencatat [png] untuk [id] (dipanggil repository sesudah baca/tulis).
  static void put(String id, Uint8List png) {
    if (identical(notifier.value[id], png)) return;
    notifier.value = {...notifier.value, id: png};
  }
}
