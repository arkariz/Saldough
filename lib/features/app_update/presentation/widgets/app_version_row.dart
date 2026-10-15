import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/app_update/domain/entities/app_version.dart';
import 'package:saldough/features/app_update/domain/services/update_policy.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_state.dart';
import 'package:saldough/features/app_update/presentation/navigation/app_update_route_keys.dart';
import 'package:state_management/state_management.dart';

/// Baris "Versi aplikasi" di grup paling bawah layar Akun (APP_UPDATE F4):
/// versi, build, dan pembaruan kecil yang berjalan, lalu keterangan keadaan.
/// Ketukan membuka "Apa yang baru". Membukanya memicu pengecekan Play (B-5);
/// kosong bila fitur tidak terdaftar (uji, platform lain).
class AppVersionRow extends StatefulWidget {
  /// Membuat [AppVersionRow].
  const AppVersionRow({required this.container, super.key});

  /// Container akar tempat bloc pembaruan terdaftar.
  final GetIt container;

  @override
  State<AppVersionRow> createState() => _AppVersionRowState();
}

class _AppVersionRowState extends State<AppVersionRow> {
  AppUpdateBloc? _bloc;

  @override
  void initState() {
    super.initState();
    if (!widget.container.isRegistered<AppUpdateBloc>()) return;
    _bloc = widget.container<AppUpdateBloc>()..add(const AppUpdateChecked(force: true));
  }

  static String _value(AppVersion version) => version.patch > 0
      ? t.account.version.valuePatched(version: version.name, build: version.build, patch: version.patch)
      : t.account.version.value(version: version.name, build: version.build);

  static String? _status(VersionStatus status) => switch (status) {
    VersionStatus.unknown => null,
    VersionStatus.latest => t.account.version.statusLatest,
    VersionStatus.available => t.account.version.statusAvailable,
    VersionStatus.downloading => t.account.version.statusDownloading,
    VersionStatus.downloaded => t.account.version.statusDownloaded,
    VersionStatus.patchReady => t.account.version.statusPatchReady,
  };

  @override
  Widget build(BuildContext context) {
    final bloc = _bloc;
    if (bloc == null) return const SizedBox.shrink();
    return BlocBuilder<AppUpdateBloc, AppUpdateState>(
      bloc: bloc,
      buildWhen: (a, b) => a.snapshot != b.snapshot,
      builder: (context, state) {
        final version = state.snapshot?.version;
        final lines = [?version == null ? null : _value(version), ?_status(state.status)];
        return AppListRow(
          key: const ValueKey('app-version-row'),
          compact: true,
          leading: AppIcon(IconKey.info, color: context.appColors.ink2),
          title: t.account.version.label,
          subtitle: lines.isEmpty ? null : lines.join('\n'),
          wrapSubtitle: true,
          chevron: true,
          onTap: () => context.pushRoute(AppUpdateRouteKeys.notes, const EmptyInput()),
        );
      },
    );
  }
}
