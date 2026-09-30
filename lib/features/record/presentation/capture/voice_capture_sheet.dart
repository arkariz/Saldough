import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/core/presentation/motion/motion.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/domain/capture/record_draft.dart';
import 'package:saldough/features/record/domain/capture/speech_transcriber.dart';
import 'package:saldough/features/record/presentation/capture/bloc/voice_capture_bloc.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Hasil lembar rekam Catat Cerdas.
sealed class VoiceCaptureResult {
  const VoiceCaptureResult();
}

/// Ucapan sudah ditafsirkan; [draft] dibuka di formulir CATAT.
final class VoiceDraftReady extends VoiceCaptureResult {
  /// Membuat [VoiceDraftReady].
  const VoiceDraftReady(this.draft);

  /// Draf hasil ucapan.
  final RecordDraft draft;
}

/// Pengguna memilih mengetik: buka CATAT kosong.
final class VoiceTypeInstead extends VoiceCaptureResult {
  /// Membuat [VoiceTypeInstead].
  const VoiceTypeInstead();
}

/// Membuka lembar rekam Catat Cerdas (ADR-027). Mengembalikan `null` kalau
/// lembar ditutup tanpa hasil. Mikrofon **tidak** dibuka sampai pengguna
/// menekan tombol rekam.
///
/// [bloc] dibuat pemanggil dan ditutup di sini begitu lembar tertutup.
Future<VoiceCaptureResult?> showVoiceCaptureSheet(
  BuildContext context, {
  required VoiceCaptureBloc bloc,
  required List<Wallet> wallets,
}) async {
  final start = VoiceCaptureStarted(
    localeId: ActiveLanguage.speechLocaleId,
    wallets: wallets,
    categories: ActiveCategories.notifier.value,
  );
  try {
    return await showModalBottomSheet<VoiceCaptureResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: VoiceCaptureSheet(start: start),
      ),
    );
  } finally {
    await bloc.close();
  }
}

/// Isi lembar rekam: satu tombol bulat untuk mulai, berhenti, dan rekam
/// ulang; lencana REKAM dengan penghitung waktu dan cincin yang berdenyut
/// mengikuti kekuatan suara selama merekam. Bukan asisten percakapan -- satu
/// ucapan, satu draf.
class VoiceCaptureSheet extends StatelessWidget {
  /// Membuat [VoiceCaptureSheet]. [start] dikirim tombol rekam.
  const VoiceCaptureSheet({required this.start, super.key});

  /// Event untuk mulai (atau mengulang) merekam.
  final VoiceCaptureStarted start;

  void _onMainButton(BuildContext context, VoiceCaptureState state) {
    final bloc = context.read<VoiceCaptureBloc>();
    switch (state.phase) {
      case VoiceCapturePhase.idle || VoiceCapturePhase.failed:
        bloc.add(start);
      case VoiceCapturePhase.starting || VoiceCapturePhase.listening:
        bloc.add(const VoiceCaptureStopped());
      case VoiceCapturePhase.interpreting || VoiceCapturePhase.done:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return BlocConsumer<VoiceCaptureBloc, VoiceCaptureState>(
      listenWhen: (previous, current) => previous.phase != current.phase,
      listener: (context, state) {
        final draft = state.draft;
        if (state.phase == VoiceCapturePhase.done && draft != null) Navigator.of(context).pop(VoiceDraftReady(draft));
      },
      builder: (context, state) {
        final heard = state.heardText.trim();
        final busy = state.phase == VoiceCapturePhase.interpreting || state.phase == VoiceCapturePhase.done;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(t.record.voice.title, style: textTheme.titleLarge)),
                    if (state.isRecording)
                      _RecordingBadge(key: const ValueKey('voice-recording-badge'), phase: state.phase),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: _RecordButton(
                    phase: state.phase,
                    level: state.level,
                    onPressed: busy ? null : () => _onMainButton(context, state),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    switch (state.phase) {
                      VoiceCapturePhase.idle => t.record.voice.idleHint,
                      VoiceCapturePhase.starting || VoiceCapturePhase.listening => t.record.voice.listening,
                      VoiceCapturePhase.interpreting || VoiceCapturePhase.done => t.record.voice.interpreting,
                      VoiceCapturePhase.failed => _failureMessage(state.failure),
                    },
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  heard.isEmpty ? t.record.voice.example : '“$heard”',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: heard.isEmpty ? colors.textMuted : colors.textPrimary),
                ),
                if (busy) ...[
                  const SizedBox(height: AppSpacing.md),
                  const LinearProgressIndicator(),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton.secondary(
                  label: t.record.voice.typeInstead,
                  onPressed: () => Navigator.of(context).pop(const VoiceTypeInstead()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tombol bulat utama: mikrofon (mulai / rekam ulang) atau kotak berhenti
/// (sedang merekam), dengan cincin yang membesar mengikuti [level].
class _RecordButton extends StatefulWidget {
  const _RecordButton({required this.phase, required this.level, required this.onPressed});

  final VoiceCapturePhase phase;
  final double level;
  final VoidCallback? onPressed;

  @override
  State<_RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<_RecordButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  bool get _recording => widget.phase == VoiceCapturePhase.starting || widget.phase == VoiceCapturePhase.listening;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(_RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final animate = _recording && MotionPolicy.duration(context, _pulse.duration!) != Duration.zero;
    if (animate && !_pulse.isAnimating) {
      unawaited(_pulse.repeat(reverse: true));
    } else if (!animate && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const size = 88.0;
    final color = _recording ? colors.expense : colors.accent;
    final label = switch (widget.phase) {
      VoiceCapturePhase.idle => t.record.voice.startAction,
      VoiceCapturePhase.starting || VoiceCapturePhase.listening => t.record.voice.stopButtonLabel,
      VoiceCapturePhase.failed => t.record.voice.retryAction,
      VoiceCapturePhase.interpreting || VoiceCapturePhase.done => t.record.voice.interpreting,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size + 48,
          height: size + 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_recording)
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    // Cincin: dasar berdenyut pelan, ditambah kekuatan suara.
                    final grow = 8 + 10 * _pulse.value + 22 * widget.level;
                    return Container(
                      width: size + grow,
                      height: size + grow,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.tinted(color, 0.22),
                        border: Border.all(color: colors.tinted(color, 0.6), width: 2),
                      ),
                    );
                  },
                ),
              Semantics(
                button: true,
                label: label,
                child: AppTappable(
                  key: const ValueKey('voice-record-button'),
                  label: label,
                  onTap: widget.onPressed,
                  child: Container(
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.onPressed == null ? colors.surfaceMid : color,
                      border: Border.all(color: colors.edge, width: AppBorder.pixelThick),
                      boxShadow: AppElevation.hardShadow(colors.edge),
                    ),
                    child: AppIcon(
                      _recording ? IconKey.stop : IconKey.microphone,
                      size: 40,
                      color: widget.onPressed == null ? colors.textMuted : colors.onAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

/// Lencana "REKAM 0:07" yang berkedip selama mikrofon terbuka.
class _RecordingBadge extends StatefulWidget {
  const _RecordingBadge({required this.phase, super.key});

  final VoiceCapturePhase phase;

  @override
  State<_RecordingBadge> createState() => _RecordingBadgeState();
}

class _RecordingBadgeState extends State<_RecordingBadge> {
  final Stopwatch _stopwatch = Stopwatch()..start();
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final seconds = _stopwatch.elapsed.inSeconds;
    final blinkOn = (_stopwatch.elapsed.inMilliseconds ~/ 500).isEven;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.tinted(colors.expense, 0.15),
        borderRadius: AppRadius.pixelSmAll,
        border: Border.all(color: colors.expense),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blinkOn ? colors.expense : colors.tinted(colors.expense, 0.3),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${t.record.voice.recordingBadge} ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
            style: PixelTypography.tabularMono(context, fontSize: 12, color: colors.expense),
          ),
        ],
      ),
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
