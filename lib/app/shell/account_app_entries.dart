import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:saldough/features/milestone/presentation/stamp_book_access.dart';
import 'package:saldough/features/milestone/presentation/widgets/stamp_account_entries.dart';
import 'package:saldough/features/period_book/presentation/period_book_settings_access.dart';
import 'package:saldough/features/period_book/presentation/widgets/invite_switch_entry.dart';

/// Baris Buku Stempel dan sakelar Perayaan stempel untuk grup Aplikasi di Akun
/// (ADR-046, T-28.5). Akun tidak boleh mengimpor isi `milestone`, jadi akar
/// komposisi yang menyambungkannya (ADR-030), seperti `accountVersionEntry`.
/// Kosong bila mesin tonggak tidak terdaftar (uji).
List<Widget> accountAppEntries(GetIt container) => [
  if (container.isRegistered<MilestoneBookAccess>()) ...stampAccountEntries(container<MilestoneBookAccess>()),
  // Ajakan akhir periode (Buku Periode, BP-14).
  if (container.isRegistered<PeriodBookSettingsAccess>()) InviteSwitchEntry(access: container<PeriodBookSettingsAccess>()),
];
