import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:saldough/features/app_update/presentation/widgets/app_version_row.dart';

/// Baris Versi aplikasi untuk layar Akun (APP_UPDATE F4). Akun tidak boleh
/// mengimpor isi `app_update`, jadi akar komposisi yang menyambungkannya
/// (ADR-030), seperti banner di slot Beranda.
Widget accountVersionEntry(GetIt container) => AppVersionRow(container: container);
