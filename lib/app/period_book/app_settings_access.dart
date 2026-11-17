import 'package:saldough/app/period_book/period_book_gate.dart';
import 'package:saldough/features/period_book/presentation/period_book_settings_access.dart';

/// [PeriodBookSettingsAccess] di akar komposisi, lewat [PeriodBookGate].
final class AppSettingsAccess implements PeriodBookSettingsAccess {
  /// Membuat [AppSettingsAccess].
  const AppSettingsAccess(this._gate);

  final PeriodBookGate _gate;

  @override
  Future<bool> inviteEnabled() async => (await _gate.memory()).inviteEnabled;

  @override
  Future<void> setInviteEnabled({required bool enabled}) async {
    await _gate.setInviteEnabled(enabled: enabled);
  }
}
