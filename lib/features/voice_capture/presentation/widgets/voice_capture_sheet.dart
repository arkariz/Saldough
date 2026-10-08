import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/core/presentation/motion/motion.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/voice_capture/domain/speech_transcriber.dart';
import 'package:saldough/features/voice_capture/presentation/bloc/voice_capture_bloc.dart';
import 'package:saldough/shared/capture/capture.dart';
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
    languageCode: ActiveLanguage.value.languageCode,
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

/// Isi lembar rekam: satu tombol bulat untuk mulai dan rekam ulang; lencana
/// REKAM dengan penghitung waktu dan cincin yang berdenyut mengikuti kekuatan
/// suara selama merekam. Rekaman berhenti sendiri saat pengguna diam --
/// tidak ada tombol berhenti. Bukan asisten percakapan -- satu ucapan, satu
/// draf.
///
/// Teks berjenjang: per tahap hanya **satu** pesan utama (yang tertangkap
/// lebih besar dari petunjuk) dan paling banyak satu keterangan kecil yang
/// redup. Label di bawah tombol hanya muncul saat gagal ("Rekam ulang"); di
/// tahap lain pesan utama sudah menjelaskan, dan labelnya tetap dibacakan
/// pembaca layar.
class VoiceCaptureSheet extends StatelessWidget {
  /// Membuat [VoiceCaptureSheet]. [start] dikirim tombol rekam.
  const VoiceCaptureSheet({required this.start, super.key});

  /// Event untuk mulai (atau mengulang) merekam.
  final VoiceCaptureStarted start;

  void _onMainButton(BuildContext context, VoiceCaptureState state) {
    if (state.phase == VoiceCapturePhase.idle || state.phase == VoiceCapturePhase.failed) {
      context.read<VoiceCaptureBloc>().add(start);
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
        final quoted = heard.isEmpty ? null : '“$heard”';
        final busy = state.phase == VoiceCapturePhase.interpreting || state.phase == VoiceCapturePhase.done;
        final (String primary, TextStyle? primaryStyle) = switch (state.phase) {
          VoiceCapturePhase.idle => (t.record.voice.idleHint, textTheme.bodyLarge),
          VoiceCapturePhase.starting || VoiceCapturePhase.listening =>
            quoted == null ? (t.record.voice.listening, textTheme.bodyLarge) : (quoted, textTheme.titleMedium),
          VoiceCapturePhase.interpreting || VoiceCapturePhase.done => (
            quoted ?? t.record.voice.interpreting,
            textTheme.titleMedium,
          ),
          VoiceCapturePhase.failed => (_failureMessage(state.failure), textTheme.bodyLarge),
        };
        final secondary = switch (state.phase) {
          VoiceCapturePhase.idle => t.record.voice.example,
          VoiceCapturePhase.starting || VoiceCapturePhase.listening => t.record.voice.autoStopHint,
          // Bilah kemajuan sudah menandai "sedang memahami".
          VoiceCapturePhase.interpreting || VoiceCapturePhase.done => null,
          VoiceCapturePhase.failed => null,
        };
        // Selama merekam tombol hanya penanda: sesi berhenti sendiri.
        final tappable = state.phase == VoiceCapturePhase.idle || state.phase == VoiceCapturePhase.failed;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space6),
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
                const SizedBox(height: AppSpacing.space6),
                Center(
                  child: _RecordButton(
                    phase: state.phase,
                    level: state.level,
                    onPressed: tappable ? () => _onMainButton(context, state) : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    primary,
                    key: const ValueKey('voice-primary-text'),
                    textAlign: TextAlign.center,
                    style: primaryStyle?.copyWith(color: colors.ink),
                  ),
                ),
                if (secondary != null) ...[
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    secondary,
                    key: const ValueKey('voice-secondary-text'),
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                  ),
                ],
                if (busy) ...[
                  const SizedBox(height: AppSpacing.space4),
                  const LinearProgressIndicator(),
                ],
                const SizedBox(height: AppSpacing.space6),
                // Tanpa internet (atau tanpa pengenal), merekam ulang belum
                // tentu berhasil -- mengetik jadi jalan utama. Pencatatan
                // sendiri tetap penuh tanpa internet (NFR-REL-001).
                if (_typingIsPrimary(state))
                  AppButton(
                    key: const ValueKey('voice-type-instead'),
                    label: t.record.voice.typeInstead,
                    onPressed: () => Navigator.of(context).pop(const VoiceTypeInstead()),
                  )
                else
                  AppButton.secondary(
                    key: const ValueKey('voice-type-instead'),
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

/// Tombol bulat utama: mikrofon untuk mulai / rekam ulang. Selama merekam
/// tombol tidak bisa diketuk dan menjadi penanda, dengan cincin yang
/// membesar mengikuti [level].
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

  /// Tampak nonaktif: tidak bisa diketuk dan bukan sedang merekam (sedang
  /// memahami).
  bool get _dimmed => widget.onPressed == null && !_recording;

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
    final color = _recording ? colors.danger : colors.brand;
    final label = switch (widget.phase) {
      VoiceCapturePhase.idle => t.record.voice.startAction,
      VoiceCapturePhase.starting || VoiceCapturePhase.listening => t.record.voice.listeningButtonLabel,
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
                button: widget.onPressed != null,
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
                      color: _dimmed ? colors.surface2 : color,
                    ),
                    child: AppIcon(
                      IconKey.microphone,
                      size: 40,
                      color: _dimmed ? colors.ink2 : colors.onBrand,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Label hanya saat gagal: aksi "Rekam ulang" tidak terbaca dari ikon
        // saja. Di tahap lain pesan utama sudah menjelaskan.
        if (widget.phase == VoiceCapturePhase.failed) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2, vertical: AppSpacing.space1),
      decoration: BoxDecoration(
        color: colors.tinted(colors.ink, 0.15),
        borderRadius: BorderRadius.circular(AppSize.pixelStepSm),
        border: Border.all(color: colors.ink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blinkOn ? colors.danger : colors.tinted(colors.danger, 0.3),
            ),
          ),
          const SizedBox(width: AppSpacing.space1),
          Text(
            '${t.record.voice.recordingBadge} ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
            style: context.numberStyles.amountSm.copyWith(color: colors.ink),
          ),
        ],
      ),
    );
  }
}

bool _typingIsPrimary(VoiceCaptureState state) =>
    state.phase == VoiceCapturePhase.failed &&
    (state.failure == SpeechFailure.network ||
        state.failure == SpeechFailure.unavailable ||
        state.failure == SpeechFailure.languageOffline);

String _failureMessage(SpeechFailure? failure) => switch (failure) {
  SpeechFailure.permissionDenied => t.record.voice.failure.permissionDenied,
  SpeechFailure.unavailable => t.record.voice.failure.unavailable,
  SpeechFailure.languageOffline => t.record.voice.failure.languageOffline,
  SpeechFailure.noMatch => t.record.voice.failure.noMatch,
  SpeechFailure.network => t.record.voice.failure.network,
  SpeechFailure.other || null => t.record.voice.failure.other,
};
