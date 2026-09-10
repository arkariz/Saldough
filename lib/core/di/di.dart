import 'package:di/di.dart';
import 'package:saldough/core/di/src/root_module.dart';

/// [DiBoot] akar Saldough. Lihat ARCHITECTURE_OVERVIEW.md bagian
/// "Bootstrap" — `di.run()` ditunggu sebelum `runApp`, `di.warmUp()`
/// berjalan sesudahnya tanpa ditunggu.
const di = DiBoot(
  init: RootModule.registerAll,
);
