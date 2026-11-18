import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

/// Ikon yang bisa dipilih untuk dompet di formulir, sesuai urutan tampil.
///
/// Ikon dompet **hanya tampilan**: dompet tidak punya jenis, dan memilih ikon
/// tertentu tidak memberi dompet kemampuan apa pun (keputusan pemilik
/// 17 Nov 2026, WEALTH_ASSETS keputusan 11). Peran dompet, mis. dompet
/// tabungan, hanya berasal dari tautan ke tujuan. `Wallet.iconKey` menyimpan
/// `IconKey.name` salah satunya.
const List<IconKey> walletIconChoices = [
  IconKey.walletBank,
  IconKey.walletCash,
  IconKey.walletEwallet,
  IconKey.walletSavings,
  IconKey.walletCard,
];

/// Pilihan warna latar kartu dompet, urutan tampil (nama warna palet kategori
/// design system). `null` di `Wallet.colorKey` berarti bawaan.
const List<String> walletColorChoices = [
  'blue',
  'green',
  'teal',
  'amber',
  'orange',
  'rose',
  'purple',
  'indigo',
  'brown',
  'slate',
];

/// Pasangan warna untuk [key] dari palet kategori, atau `null` bila bawaan
/// atau tidak dikenal (data dari versi lain).
DsColorPair? walletColorPair(DsColorScheme scheme, String? key) {
  final cats = scheme.categories;
  return switch (key) {
    'blue' => cats.blue,
    'green' => cats.green,
    'teal' => cats.teal,
    'amber' => cats.amber,
    'orange' => cats.orange,
    'rose' => cats.rose,
    'purple' => cats.purple,
    'indigo' => cats.indigo,
    'brown' => cats.brown,
    'slate' => cats.slate,
    _ => null,
  };
}
