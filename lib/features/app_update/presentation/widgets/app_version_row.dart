import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_state.dart';
import 'package:saldough/features/app_update/presentation/navigation/app_update_route_keys.dart';
import 'package:saldough/features/app_update/presentation/widgets/app_update_labels.dart';
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

  @override
  Widget build(BuildContext context) {
    final bloc = _bloc;
    if (bloc == null) return const SizedBox.shrink();
    return BlocBuilder<AppUpdateBloc, AppUpdateState>(
      bloc: bloc,
      buildWhen: (a, b) => a.snapshot != b.snapshot,
      builder: (context, state) {
        final version = state.snapshot?.version;
        final status = versionStatusLabel(state.status);
        return AppListRow(
          key: const ValueKey('app-version-row'),
          compact: true,
          leading: AppIcon(IconKey.systemUpdate, color: context.appColors.ink2),
          title: t.account.version.label,
          subtitle: version == null ? null : versionValue(version),
          wrapSubtitle: true,
          detail: status,
          detailStrong: versionStatusStrong(state.status),
          chevron: true,
          onTap: () => context.pushRoute(AppUpdateRouteKeys.notes, const EmptyInput()),
        );
      },
    );
  }
}
