import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';
import 'package:saldough/features/record/domain/capture/speech_transcriber.dart';
import 'package:saldough/features/record/presentation/capture/bloc/voice_capture_bloc.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Membuka lembar rekam Catat Cerdas dan mengembalikan [RecordDraft], atau
/// `null` kalau dibatalkan atau pengguna memilih mengetik (ADR-027).
///
/// [bloc] dibuat pemanggil dan ditutup di sini begitu lembar tertutup.
Future<RecordDraft?> showVoiceCaptureSheet(
  BuildContext context, {
  required VoiceCaptureBloc bloc,
  required List<Wallet> wallets,
}) async {
  final start = VoiceCaptureStarted(
    localeId: LocaleSettings.currentLocale.languageCode == 'id' ? 'id_ID' : 'en_US',
    wallets: wallets,
    categories: ActiveCategories.notifier.value,
  );
  bloc.add(start);
  try {
    return await showModalBottomSheet<RecordDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: VoiceCaptureSheet(restart: start),
      ),
    );
  } finally {
    await bloc.close();
  }
}

/// Isi lembar rekam: teks yang tertangkap, lalu "Memahami…", lalu menutup
/// dengan draf. Bukan asisten percakapan -- satu ucapan, satu draf.
class VoiceCaptureSheet extends StatelessWidget {
  /// Membuat [VoiceCaptureSheet]. [restart] dikirim ulang oleh "Coba lagi".
  const VoiceCaptureSheet({required this.restart, super.key});

  /// Event untuk mengulang rekaman.
  final VoiceCaptureStarted restart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return BlocConsumer<VoiceCaptureBloc, VoiceCaptureState>(
      listenWhen: (previous, current) => previous.phase != current.phase,
      listener: (context, state) {
        if (state.phase == VoiceCapturePhase.done) Navigator.of(context).pop(state.draft);
      },
      builder: (context, state) {
        final heard = state.heardText.trim();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.record.voice.title, style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                const Center(child: AppIcon(IconKey.microphone, size: 48)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  switch (state.phase) {
                    VoiceCapturePhase.listening => t.record.voice.listening,
                    VoiceCapturePhase.interpreting || VoiceCapturePhase.done => t.record.voice.interpreting,
                    VoiceCapturePhase.failed => _failureMessage(state.failure),
                  },
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  heard.isEmpty ? t.record.voice.example : '“$heard”',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: heard.isEmpty ? colors.textMuted : colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (state.phase == VoiceCapturePhase.listening)
                  AppButton(
                    label: t.record.voice.stopAction,
                    onPressed: () => context.read<VoiceCaptureBloc>().add(const VoiceCaptureStopped()),
                  ),
                if (state.phase == VoiceCapturePhase.failed)
                  AppButton(
                    label: t.common.retry,
                    onPressed: () => context.read<VoiceCaptureBloc>().add(restart),
                  ),
                const SizedBox(height: AppSpacing.sm),
                AppButton.secondary(label: t.record.voice.typeInstead, onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _failureMessage(SpeechFailure? failure) => switch (failure) {
  SpeechFailure.permissionDenied => t.record.voice.failure.permissionDenied,
  SpeechFailure.unavailable => t.record.voice.failure.unavailable,
  SpeechFailure.noMatch => t.record.voice.failure.noMatch,
  SpeechFailure.network => t.record.voice.failure.network,
  SpeechFailure.other || null => t.record.voice.failure.other,
};
