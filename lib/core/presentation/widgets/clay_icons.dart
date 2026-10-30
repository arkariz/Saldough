import 'package:saldough/core/presentation/widgets/app_icon.dart';

/// Ikon "clay" (ilustrasi SVG berwarna, `assets/icons_clay/`, ADR-043 dan
/// `docs/03-design/design-system-v2/icons.md`).
///
/// KT-DS5: ikon clay menggantikan ikon piksel di seluruh aplikasi, tetapi
/// baru 10 yang digambar. [forIcon] mengembalikan aset clay bila ada;
/// `null` berarti pemanggil tetap memakai ikon piksel lama.
abstract final class ClayIcons {
  ClayIcons._();

  /// Maskot tanuki.
  static const String mascot = 'assets/icons_clay/tanuki_mascot.svg';

  /// Koin lencana level.
  static const String tierCoin = 'assets/icons_clay/tier_coin.svg';

  /// Kamera "Scan Struk".
  static const String scan = 'assets/icons_clay/scan_camera.svg';

  /// Daun "Catat Transfer".
  static const String transfer = 'assets/icons_clay/leaf_send.svg';

  /// Batang "Laporan".
  static const String report = 'assets/icons_clay/report_bars.svg';

  /// Piala "Misi Hemat".
  static const String trophy = 'assets/icons_clay/trophy_mission.svg';

  /// Cangkir kopi.
  static const String coffee = 'assets/icons_clay/cup_coffee.svg';

  /// Kereta.
  static const String train = 'assets/icons_clay/train_transport.svg';

  /// Stilus, pekerjaan lepas.
  static const String stylus = 'assets/icons_clay/stylus_freelance.svg';

  /// Headphone, langganan dan hiburan.
  static const String headphones = 'assets/icons_clay/headphones_subscription.svg';

  /// Seluruh aset, untuk uji dan pemeriksaan manifest.
  static const List<String> all = [mascot, tierCoin, scan, transfer, report, trophy, coffee, train, stylus, headphones];

  /// Aset clay untuk [key], atau `null` bila belum digambar.
  static String? forIcon(IconKey key) => switch (key) {
    IconKey.categoryCoffee => coffee,
    IconKey.categoryTransport => train,
    IconKey.freelance => stylus,
    IconKey.categoryEntertainment => headphones,
    _ => null,
  };
}
