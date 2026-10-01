import 'package:flutter/material.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/capture/speech_language_sheet.dart';
import 'package:saldough/features/record/presentation/capture/voice_capture_sheet.dart';
import 'package:saldough/features/record/presentation/open_record_sheet.dart';
import 'package:state_management/state_management.dart';

/// Catat pakai suara (ADR-027), dari tombol mikrofon shell: buka lembar rekam,
/// lalu buka CATAT dengan draf hasil ucapan -- atau CATAT kosong kalau
/// pengguna memilih mengetik. Tidak ada yang tersimpan sebelum pengguna
/// menekan Catat di formulir (CLAUDE.md aturan 8).
///
/// [context] harus berada di bawah `BlocProvider<RecordBloc>`, seperti
/// [openRecordSheet].
Future<void> openVoiceRecord(BuildContext context) async {
  final bloc = context.read<RecordBloc>();
  final factory = bloc.voiceCaptureFactory;
  if (factory == null) {
    await openRecordSheet(context);
    return;
  }
  bloc.add(const RecordWalletsLoaded());
  await bloc.stream.firstWhere((s) => !s.isLoading);
  if (!context.mounted || bloc.state.loadFailed) return;

  // Pengguna lama belum pernah memilih bahasa (ADR-028 §3.8): tanya sekali,
  // karena bahasa perangkat belum tentu bahasa yang diucapkan. Ditutup =
  // batal merekam.
  final prompt = bloc.speechLanguagePrompt;
  if (prompt != null && await prompt.isPending()) {
    if (!context.mounted) return;
    final picked = await showSpeechLanguageSheet(context);
    if (picked == null) return;
    await prompt.choose(picked);
  }
  if (!context.mounted) return;

  final result = await showVoiceCaptureSheet(context, bloc: factory(), wallets: bloc.state.wallets);
  if (!context.mounted) return;
  switch (result) {
    case VoiceDraftReady(:final draft):
      await openRecordSheet(context, draft: draft);
    case VoiceTypeInstead():
      await openRecordSheet(context);
    case null:
      return;
  }
}
