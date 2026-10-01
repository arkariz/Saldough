import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/voice_capture/presentation/bloc/voice_capture_bloc.dart';
import 'package:saldough/features/voice_capture/presentation/widgets/speech_language_sheet.dart';
import 'package:saldough/features/voice_capture/presentation/widgets/voice_capture_sheet.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Catat pakai suara (ADR-027), dari tombol mikrofon shell: buka lembar rekam,
/// lalu buka CATAT lewat `RecordRouteKeys.sheet` dengan draf hasil ucapan --
/// atau CATAT kosong kalau pengguna memilih mengetik. Tidak ada yang tersimpan
/// sebelum pengguna menekan Catat di formulir (CLAUDE.md aturan 8).
///
/// [newBloc] membuat bloc rekam untuk satu lembar; [languagePrompt] bertanya
/// bahasa ucapan sekali (ADR-028 §3.8), atau `null`.
Future<void> openVoiceCapture(
  BuildContext context, {
  required WalletRepository walletRepository,
  required VoiceCaptureBloc Function() newBloc,
  SpeechLanguagePrompt? languagePrompt,
}) async {
  final loaded = await walletRepository.listWallets();
  if (!context.mounted) return;
  final wallets = loaded.fold<List<Wallet>?>(
    (_) => null,
    (all) => [
      for (final w in all)
        if (w.isActive) w,
    ],
  );
  // Dompet gagal dibaca: CATAT yang menampilkan galatnya.
  if (wallets == null) {
    await context.pushRoute(RecordRouteKeys.sheet, const RecordSheetInput());
    return;
  }

  // Pengguna lama belum pernah memilih bahasa (ADR-028 §3.8): tanya sekali,
  // karena bahasa perangkat belum tentu bahasa yang diucapkan. Ditutup =
  // batal merekam.
  final prompt = languagePrompt;
  if (prompt != null && await prompt.isPending()) {
    if (!context.mounted) return;
    final picked = await showSpeechLanguageSheet(context);
    if (picked == null) return;
    await prompt.choose(picked);
  }
  if (!context.mounted) return;

  final result = await showVoiceCaptureSheet(context, bloc: newBloc(), wallets: wallets);
  if (!context.mounted) return;
  switch (result) {
    case VoiceDraftReady(:final draft):
      await context.pushRoute(RecordRouteKeys.sheet, RecordSheetInput(draft: draft));
    case VoiceTypeInstead():
      await context.pushRoute(RecordRouteKeys.sheet, const RecordSheetInput());
    case null:
      return;
  }
}
