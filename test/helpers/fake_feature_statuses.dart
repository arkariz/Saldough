import 'dart:async';

import 'package:saldough/core/discovery/discovery.dart';

/// [FeatureStatuses] yang keadaannya diatur uji.
final class FakeFeatureStatuses implements FeatureStatuses {
  /// Keadaan tiap fitur; bawaan tidak didukung.
  final status = <DiscoveredFeature, FeatureStatus>{};

  final _controller = StreamController<void>.broadcast();

  @override
  Future<FeatureStatus> read(DiscoveredFeature feature) async => status[feature] ?? FeatureStatus.unsupported;

  @override
  Stream<void> get changes => _controller.stream;

  /// Memberi tahu pendengar bahwa setelan berubah.
  void notify() => _controller.add(null);
}
