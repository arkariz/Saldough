import 'dart:typed_data';

import 'package:dependencies/dependencies.dart' hide State;
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/services/built_in_notification_patterns.dart';

/// Lembar pemilih aplikasi sumber (ADR-032 §3.2): aplikasi peluncur
/// terpasang, bisa dicari; aplikasi yang punya pola bawaan diberi lencana
/// dan tampil lebih dulu.
Future<InstalledApp?> showAppPickerSheet(
  BuildContext context, {
  required Future<Either<Failure, List<InstalledApp>>> Function() load,
}) => showFullScreenSheet<InstalledApp>(context, builder: (_) => _AppPicker(load: load));

class _AppPicker extends StatefulWidget {
  const _AppPicker({required this.load});

  final Future<Either<Failure, List<InstalledApp>>> Function() load;

  @override
  State<_AppPicker> createState() => _AppPickerState();
}

class _AppPickerState extends State<_AppPicker> {
  late final Future<Either<Failure, List<InstalledApp>>> _apps = widget.load();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(title: Text(texts.pickAppTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(hintText: texts.searchApps, prefixIcon: const Icon(Icons.search)),
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: FutureBuilder<Either<Failure, List<InstalledApp>>>(
                future: _apps,
                builder: (context, snapshot) {
                  final result = snapshot.data;
                  if (result == null) return const Center(child: CircularProgressIndicator());
                  return switch (result) {
                    Left() => Center(child: Text(texts.appsLoadFailed)),
                    Right(:final value) => _list(context, value, textTheme, colors),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<InstalledApp> apps, TextTheme textTheme, AppColors colors) {
    final filtered =
        [
          for (final app in apps)
            if (_query.isEmpty ||
                app.label.toLowerCase().contains(_query) ||
                app.packageName.toLowerCase().contains(_query))
              app,
        ]..sort((a, b) {
          final aKnown = builtInNotificationApps.containsKey(a.packageName) ? 0 : 1;
          final bKnown = builtInNotificationApps.containsKey(b.packageName) ? 0 : 1;
          return aKnown != bKnown ? aKnown - bKnown : a.label.toLowerCase().compareTo(b.label.toLowerCase());
        });
    if (filtered.isEmpty) return Center(child: Text(t.notificationCapture.appsEmpty));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final app = filtered[index];
        final icon = app.icon;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: icon == null
              ? const AppIcon(IconKey.walletEwallet)
              : Image.memory(Uint8List.fromList(icon), width: 36, height: 36),
          title: Text(app.label),
          subtitle: Text(
            builtInNotificationApps.containsKey(app.packageName)
                ? '${t.notificationCapture.builtInPatternsBadge} · ${app.packageName}'
                : app.packageName,
            style: textTheme.bodySmall?.copyWith(color: colors.ink2),
          ),
          onTap: () => Navigator.of(context).pop(app),
        );
      },
    );
  }
}
