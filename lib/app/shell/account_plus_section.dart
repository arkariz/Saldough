import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:saldough/features/premium/domain/plus_purchasing.dart';
import 'package:saldough/features/premium/presentation/widgets/account_plus_section.dart';

/// Bagian Plus untuk layar Akun (ADR-041). Akun tidak boleh mengimpor isi
/// `premium`, jadi akar komposisi yang menyambungkannya (ADR-030), sama
/// dengan [accountDataSection].
Widget accountPlusSection(GetIt container) => AccountPlusSection(purchasing: container<PlusPurchasing>());
