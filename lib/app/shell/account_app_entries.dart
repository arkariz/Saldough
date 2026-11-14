import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:saldough/features/milestone/presentation/stamp_book_access.dart';
import 'package:saldough/features/milestone/presentation/widgets/stamp_account_entries.dart';

/// Baris Buku Stempel dan sakelar Perayaan stempel untuk grup Aplikasi di Akun
/// (ADR-046, T-28.5). Akun tidak boleh mengimpor isi `milestone`, jadi akar
/// komposisi yang menyambungkannya (ADR-030), seperti `accountVersionEntry`.
/// Kosong bila mesin tonggak tidak terdaftar (uji).
List<Widget> accountAppEntries(GetIt container) =>
    container.isRegistered<MilestoneBookAccess>() ? stampAccountEntries(container<MilestoneBookAccess>()) : const [];
