import 'package:saldough/shared/wallet/domain/wallet.dart';

/// Model serialisasi [Wallet], terpisah dari entitas domain (tanpa
/// `freezed`, mengikuti konvensi monorepo — lihat ARCHITECTURE_OVERVIEW.md).
final class WalletModel {
  /// Membuat [WalletModel].
  const WalletModel({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.initialBalance,
    required this.currentBalance,
    required this.isActive,
    this.colorKey,
    this.createdAt,
  });

  /// Membaca [WalletModel] dari JSON.
  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
        id: json['id'] as String,
        name: json['name'] as String,
        iconKey: json['iconKey'] as String,
        initialBalance: json['initialBalance'] as int,
        currentBalance: json['currentBalance'] as int,
        isActive: json['isActive'] as bool,
        colorKey: json['colorKey'] as String?,
        createdAt: json['createdAt'] == null ? null : DateTime.parse(json['createdAt'] as String),
      );

  /// Membuat [WalletModel] dari entitas domain [Wallet].
  factory WalletModel.fromEntity(Wallet wallet) => WalletModel(
        id: wallet.id,
        name: wallet.name,
        iconKey: wallet.iconKey,
        initialBalance: wallet.initialBalance,
        currentBalance: wallet.currentBalance,
        isActive: wallet.isActive,
        colorKey: wallet.colorKey,
        createdAt: wallet.createdAt,
      );

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 1;

  /// Identitas dompet.
  final String id;

  /// Nama dompet.
  final String name;

  /// Kunci semantik ikon.
  final String iconKey;

  /// Saldo awal dalam sen.
  final int initialBalance;

  /// Saldo tercatat saat ini, dalam sen.
  final int currentBalance;

  /// Dompet aktif atau tidak.
  final bool isActive;

  /// Warna latar kartu, opsional. Field tambahan tanpa naik skema: pembaca
  /// lama mengabaikannya, dokumen lama tanpa kunci ini terbaca `null`.
  final String? colorKey;

  /// Saat dompet dibuat, opsional (ADR-050 §3.6). Field tambahan tanpa naik
  /// skema, seperti [colorKey]: dokumen lama terbaca `null`, pembaca lama
  /// mengabaikannya.
  final DateTime? createdAt;

  /// Menulis [WalletModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'initialBalance': initialBalance,
        'currentBalance': currentBalance,
        'isActive': isActive,
        if (colorKey != null) 'colorKey': colorKey,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  /// Mengubah model jadi entitas domain [Wallet].
  Wallet toEntity() => Wallet(
        id: id,
        name: name,
        iconKey: iconKey,
        initialBalance: initialBalance,
        currentBalance: currentBalance,
        isActive: isActive,
        colorKey: colorKey,
        createdAt: createdAt,
      );
}
