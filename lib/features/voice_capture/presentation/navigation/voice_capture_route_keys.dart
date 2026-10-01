import 'package:navigation/navigation.dart';

// Satu-satunya berkas fitur `voice_capture` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3, ADR-033 §3.2).

/// Kunci rute fitur `voice_capture`.
abstract final class VoiceCaptureRouteKeys {
  /// Catat pakai suara (ADR-027): alur transparan yang berlanjut ke CATAT
  /// dengan draf.
  static const capture = RouteKey<EmptyInput>('voiceCapture.capture');
}
