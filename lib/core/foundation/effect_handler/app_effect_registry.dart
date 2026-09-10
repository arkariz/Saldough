import 'package:saldough/core/foundation/effect_handler/src/dialog_effect_handler.dart';
import 'package:saldough/core/foundation/effect_handler/src/nav_effect_handler.dart';
import 'package:saldough/core/foundation/effect_handler/src/snackbar_effect_handler.dart';
import 'package:state_management/state_management.dart';

/// Mendaftarkan seluruh penangan efek baku Saldough ke [globalEffectRegistry].
///
/// Dipanggil sekali, SEBELUM `runApp` — lihat `main.dart` dan
/// ARCHITECTURE_OVERVIEW.md bagian "Bootstrap". `EffectRegistry.register`
/// menegaskan satu tipe efek hanya boleh terdaftar sekali; memanggil fungsi
/// ini dua kali adalah galat program.
void registerEffectHandlers() {
  registerNavigationEffectHandlers(globalEffectRegistry);
  registerSnackBarEffectHandler(globalEffectRegistry);
  registerDialogEffectHandler(globalEffectRegistry);
  globalEffectRegistry.register<CallbackEffect>((context, effect) => effect.callback(context));
}
