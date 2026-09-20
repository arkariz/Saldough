import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

/// Ikon jenis dompet yang bisa dipilih di formulir, sesuai urutan tampil.
///
/// `Wallet.iconKey` menyimpan `IconKey.name` salah satunya; jenis dompet
/// TIDAK disimpan terpisah -- ia diturunkan dari ikon ([walletTypeLabel]),
/// karena rujukan visual "Tipe kategori" dan "Pilih ikon" adalah pilihan yang
/// sama.
const List<IconKey> walletIconChoices = [
  IconKey.walletBank,
  IconKey.walletCash,
  IconKey.walletEwallet,
  IconKey.walletSavings,
  IconKey.walletCard,
];

/// Label jenis dompet dari [iconKey] ("Bank / Rekening", "Uang Tunai", ...),
/// atau `null` kalau [iconKey] bukan salah satu [walletIconChoices] (data
/// tersimpan dari versi lain) -- lencananya tidak ditampilkan.
String? walletTypeLabel(String iconKey) => switch (walletIconKey(iconKey)) {
  IconKey.walletBank => t.wallet.typeBank,
  IconKey.walletCash => t.wallet.typeCash,
  IconKey.walletEwallet => t.wallet.typeEwallet,
  IconKey.walletSavings => t.wallet.typeSavings,
  IconKey.walletCard => t.wallet.typeCard,
  _ => null,
};
