import 'package:flutter/widgets.dart';

/// Tanggal kalender yang sedang berjalan (T-15.17). Aplikasi bisa hidup di
/// latar melewati tengah malam; layar yang menghitung "hari ini" (kemunculan
/// menunggu, Bulan ini) mendengarkan [notifier] untuk memuat ulang saat
/// tanggal berganti. `main.dart` memasang [observer].
abstract final class ActiveDay {
  ActiveDay._();

  /// Tanggal hari ini (jam 00.00 lokal).
  static final ValueNotifier<DateTime> notifier = ValueNotifier(_dateOf(DateTime.now()));

  /// Pengamat siklus hidup yang memanggil [sync] tiap aplikasi kembali ke
  /// depan.
  static final WidgetsBindingObserver observer = _ResumeObserver();

  /// Memperbarui [notifier] bila tanggal [now] berbeda dari yang tersimpan.
  static void sync([DateTime? now]) {
    final date = _dateOf(now ?? DateTime.now());
    if (date != notifier.value) notifier.value = date;
  }

  static DateTime _dateOf(DateTime now) => DateTime(now.year, now.month, now.day);
}

final class _ResumeObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ActiveDay.sync();
  }
}
