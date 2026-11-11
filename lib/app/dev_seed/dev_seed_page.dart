import 'package:di/di.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/app/dev_seed/seed_pack.dart';
import 'package:saldough/app/dev_seed/spending_seed_pack.dart';
import 'package:saldough/app/dev_seed/wallet_seed_pack.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Kunci rute halaman data seed; hanya terdaftar di build non-rilis.
const devSeedRouteKey = RouteKey<EmptyInput>('app.devSeed');

/// Paket seed yang tersedia. Paket baru (transaksi, rutin, ...) cukup
/// ditambahkan di sini; lihat aturan di [SeedPack].
const List<SeedPack> devSeedPacks = [
  WalletSeedPack(),
  SpendingSeedPack(),
];

/// Modul rute data seed. Milik `lib/app/` karena perlakuan pengembang, bukan
/// fitur: di rilis tanpa rute dan tanpa entri menu pengembang.
final class DevSeedRouteModule extends FeatureRouteModule {
  /// Membuat [DevSeedRouteModule]; [isRelease] untuk uji.
  const DevSeedRouteModule({this.isRelease = kReleaseMode});

  /// Build rilis: tanpa rute dan tanpa entri.
  final bool isRelease;

  @override
  List<RouteNode> get routes => isRelease
      ? const []
      : [
          RouteNode.typed<EmptyInput>(
            key: devSeedRouteKey,
            defaultInput: () => const EmptyInput(),
            builder: (context, _) => DevSeedPage(container: ScopeProvider.of(context)),
          ),
        ];

  @override
  List<DevEntry> get devEntries => isRelease
      ? const []
      : [
          DevEntry.typed<EmptyInput>(
            label: 'Data seed (uji)',
            category: 'data',
            key: devSeedRouteKey,
            inputFactory: () => const EmptyInput(),
          ),
        ];
}

/// Menerapkan paket seed satu per satu. Aman diulang: data yang sudah ada
/// tidak ditimpa.
class DevSeedPage extends StatelessWidget {
  /// Membuat [DevSeedPage].
  const DevSeedPage({required this.container, this.packs = devSeedPacks, super.key});

  /// Kontainer akar.
  final GetIt container;

  /// Paket yang ditawarkan.
  final List<SeedPack> packs;

  Future<void> _apply(BuildContext context, SeedPack pack) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await pack.apply(container);
      messenger.showSnackBar(SnackBar(content: Text('${pack.label}: $result')));
    } on Object catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('${pack.label} gagal: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data seed (uji)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
            const Text('Tambah-bila-belum-ada. Tidak menimpa atau menghapus data yang sudah ada.'),
            const SizedBox(height: AppSpacing.space4),
            AppListCard(
              children: [
                for (final pack in packs)
                  AppListRow(
                    key: ValueKey('seed-${pack.id}'),
                    title: pack.label,
                    subtitle: pack.description,
                    onTap: () => _apply(context, pack),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
