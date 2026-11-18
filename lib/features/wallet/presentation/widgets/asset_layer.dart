import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/shared/wealth/wealth.dart';

/// Lapis tab Dompet (ADR-050): Dompet, Tabungan, Investasi.
enum AssetLayer {
  /// Dompet sehari-hari.
  wallets,

  /// Tabungan (dompet milik tujuan).
  savings,

  /// Investasi (Fase 31).
  investments,
}

/// Lapis yang ditampilkan: Dompet selalu, Tabungan sesudah ada tujuan,
/// Investasi sesudah ada nilainya.
List<AssetLayer> shownLayers(WealthLayers layers) => [
  AssetLayer.wallets,
  if (layers.hasSavings) AssetLayer.savings,
  if (layers.investment != 0) AssetLayer.investments,
];

/// Nama lapis di antarmuka.
String layerLabel(AssetLayer layer) => switch (layer) {
  AssetLayer.wallets => t.assets.layerOperational,
  AssetLayer.savings => t.assets.layerSavings,
  AssetLayer.investments => t.assets.layerInvestment,
};

/// Nilai satu lapis, dalam sen.
int layerAmount(WealthLayers layers, AssetLayer layer) => switch (layer) {
  AssetLayer.wallets => layers.operational,
  AssetLayer.savings => layers.savings,
  AssetLayer.investments => layers.investment,
};

/// Warna lapis di atas latar hero: terang supaya terbaca di gradasi gelap.
Map<AssetLayer, Color> heroLayerColors(DsColorScheme scheme) => {
  AssetLayer.wallets: scheme.primaryFixed,
  AssetLayer.savings: scheme.heroAccentWarm,
  AssetLayer.investments: Colors.white,
};
