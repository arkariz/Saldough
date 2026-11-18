import 'dart:developer' as developer;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:saldough/shared/investment/domain/price_sheet.dart';

/// [PriceSheetConfigSource] yang membaca nilai Remote Config yang sudah aktif
/// (pola `FirebaseReviewConfig`): tidak mengambil dan tidak mengubah setelan
/// ambil. Sebelum pengambilan pertama, nilai bawaan berlaku.
final class FirebasePriceSheetConfig implements PriceSheetConfigSource {
  /// Membuat [FirebasePriceSheetConfig]; [remoteConfig] untuk uji.
  FirebasePriceSheetConfig({FirebaseRemoteConfig? remoteConfig}) : _injected = remoteConfig;

  final FirebaseRemoteConfig? _injected;

  @override
  PriceSheetConfig get config {
    try {
      final value = (_injected ?? FirebaseRemoteConfig.instance).getString(PriceSheetConfig.goldKey);
      return PriceSheetConfig.fromValues({PriceSheetConfig.goldKey: value});
    } on Object catch (e) {
      developer.log('Remote Config harga Sheet gagal dibaca', error: e, name: 'PriceSheet');
      return PriceSheetConfig.defaults;
    }
  }
}
