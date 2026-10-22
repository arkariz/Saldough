import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/app_spin.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/data_portability/data/restore_engine.dart';

/// Menjalankan ulang bootstrap aplikasi di dalam proses (ADR-040 §3.7).
///
/// Pemulihan cadangan mengganti data di penyimpanan, sedangkan kontainer DI,
/// blok, dan state global (`ActiveCurrency`, `ActiveCategories`, ...) sudah
/// memuat data lama. Membangun ulang pohon widget saja tidak membuangnya;
/// boot ulang memakai jalur yang sama dengan peluncuran dingin, yang sudah
/// teruji.
abstract final class AppReboot {
  static Future<void> Function()? _bootstrap;

  /// Keterangan pemulihan yang baru selesai, diisi bootstrap. Dibaca layar
  /// untuk menampilkan "Data dipulihkan dari cadangan {tanggal}" sekali, lalu
  /// dikosongkan.
  static final ValueNotifier<RestoreReport?> report = ValueNotifier(null);

  /// Mendaftarkan [bootstrap] (`bootstrapApp`), dipanggil sekali oleh `main()`.
  // ignore: use_setters_to_change_properties, dipasang sekali sebagai tindakan, bukan properti.
  static void install(Future<void> Function() bootstrap) => _bootstrap = bootstrap;

  /// Mengganti layar dengan penanda proses lalu menjalankan ulang bootstrap.
  /// Penerapan data sebenarnya dilakukan jalur pemulihan jurnal di dalam
  /// bootstrap, jadi jalur yang sama menangani pemulihan biasa dan pemulihan
  /// dari gangguan.
  static Future<void> reboot() async {
    final bootstrap = _bootstrap;
    if (bootstrap == null) throw StateError('AppReboot.install belum dipanggil');
    runApp(const _RebootSplash());
    // Pohon lama harus benar-benar lepas sebelum kontainer DI dikosongkan.
    await WidgetsBinding.instance.endOfFrame;
    await bootstrap();
  }
}

class _RebootSplash extends StatelessWidget {
  const _RebootSplash();

  @override
  Widget build(BuildContext context) {
    final colors = PixelTheme.light.extension<AppColors>()!;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: PixelTheme.light,
      darkTheme: PixelTheme.dark,
      home: Scaffold(
        body: Center(
          child: AppSpin(child: Icon(Icons.sync, color: colors.brand, size: 32)),
        ),
      ),
    );
  }
}
