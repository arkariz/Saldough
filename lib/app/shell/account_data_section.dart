import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:saldough/features/data_portability/presentation/widgets/account_data_section.dart';

/// Bagian Data kamu untuk layar Akun (EXPORT_BACKUP §4). Akun tidak boleh
/// mengimpor isi `data_portability`, jadi akar komposisi yang
/// menyambungkannya (ADR-030), sama dengan [accountVersionEntry].
Widget accountDataSection(GetIt container) => AccountDataSection(container: container);
