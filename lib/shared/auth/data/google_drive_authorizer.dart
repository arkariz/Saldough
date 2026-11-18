import 'package:google_sign_in/google_sign_in.dart';

/// Scope berkas buatan aplikasi di Google Drive (ADR-051 §3.2).
const driveFileScope = 'https://www.googleapis.com/auth/drive.file';

/// Izin tambahan `drive.file` lewat `google_sign_in` 7 (ADR-051 §3.2):
/// terpisah dari masuk, diminta hanya dari ketukan pengguna.
final class GoogleDriveAuthorizer {
  /// Membuat [GoogleDriveAuthorizer]; [client] untuk uji.
  GoogleDriveAuthorizer({GoogleSignInAuthorizationClient? client})
    : _client = client ?? GoogleSignIn.instance.authorizationClient;

  final GoogleSignInAuthorizationClient _client;

  /// Token bila izin sudah ada, tanpa layar; `null` bila belum.
  Future<String?> silentToken() async {
    try {
      return (await _client.authorizationForScopes(const [driveFileScope]))?.accessToken;
    } on Object {
      return null;
    }
  }

  /// Meminta izin dengan layar Google bila perlu. Panggil dari ketukan.
  Future<String?> requestToken() async {
    final silent = await silentToken();
    if (silent != null) return silent;
    try {
      return (await _client.authorizeScopes(const [driveFileScope])).accessToken;
    } on GoogleSignInException {
      return null;
    }
  }
}
