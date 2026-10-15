import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_state.dart';

/// Ringkasan teknis keadaan pembaruan untuk panel diagnostik (tekan lama
/// kartu kepala di halaman Versi aplikasi): jawaban mentah Play, Shorebird,
/// catatan, dan keputusan pengumuman. Teks teknis, tidak diterjemahkan, dan
/// tanpa data pribadi atau keuangan.
String buildUpdateDiagnostics(AppUpdateState state) {
  final snapshot = state.snapshot;
  final lines = <String>[];
  if (snapshot == null) {
    lines.add('versi: belum terbaca');
  } else {
    final version = snapshot.version;
    lines
      ..add('versi: ${version.name} (build ${version.build}, patch ${version.patch})')
      ..add('Play stage: ${snapshot.store.stage.name}, build ditawarkan: ${snapshot.store.availableBuild}')
      ..add('Play:\n${snapshot.store.diagnostic ?? 'tidak dicek / tanpa jawaban'}')
      ..add('Shorebird: berjalan=${snapshot.patch.current}, berikutnya=${snapshot.patch.next}');
  }
  lines
    ..add('pengumuman: ${state.announcement.name}')
    ..add(
      'ditunda: ${state.memory.deferredBuild ?? '-'}'
      '${state.memory.deferredAt == null ? '' : ' sejak ${state.memory.deferredAt!.toIso8601String()}'}',
    )
    ..add('terakhir dilihat: ${state.memory.lastSeenBuild}.${state.memory.lastSeenPatch}')
    ..add(
      'catatan: ${state.notes.entries.length} entri, server terbaca=${state.notes.serverRead}, '
      'chip=${state.availableVersion}',
    );
  return lines.join('\n');
}

/// Lembar diagnostik: teks yang bisa dipilih dan tombol Salin.
class UpdateDiagnosticsSheet extends StatelessWidget {
  /// Membuat [UpdateDiagnosticsSheet].
  const UpdateDiagnosticsSheet({required this.text, super.key});

  /// Isi dari [buildUpdateDiagnostics].
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.appUpdate.diagnostic.title, style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.space3),
          Flexible(
            child: SingleChildScrollView(
              child: SelectableText(
                text,
                key: const ValueKey('update-diagnostics-text'),
                style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: context.appColors.ink),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          AppButton.secondary(
            key: const ValueKey('update-diagnostics-copy'),
            label: t.appUpdate.diagnostic.copy,
            expand: true,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
