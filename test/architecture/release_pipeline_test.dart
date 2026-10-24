import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kunci SDK RevenueCat harus ikut di rilis DAN patch Shorebird (ADR-041
/// §3.13 butir 6): patch tanpa kunci membuang pembelian dari build terpasang.
void main() {
  final fastfile = File('android/fastlane/Fastfile').readAsStringSync();
  final workflow = File('.github/workflows/deploy.yaml').readAsStringSync();

  String lane(String name) {
    final start = fastfile.indexOf('lane :$name do');
    expect(start, isNonNegative, reason: 'lane $name tidak ada');
    final next = fastfile.indexOf('\n    desc ', start);
    return fastfile.substring(start, next == -1 ? fastfile.length : next);
  }

  test('kedua lane Fastlane meneruskan dart-define kunci RevenueCat', () {
    expect(lane('release_internal'), contains('revenuecat_args'));
    expect(lane('patch_ota'), contains('revenuecat_args'));
    expect(fastfile, contains('--dart-define=REVENUECAT_ANDROID_KEY='));
  });

  test('kedua langkah Fastlane di workflow menerima secret kunci', () {
    final count =
        r'REVENUECAT_ANDROID_KEY: ${{ secrets.REVENUECAT_ANDROID_KEY }}'
            .allMatches(workflow)
            .length;
    expect(count, 2);
  });
}
