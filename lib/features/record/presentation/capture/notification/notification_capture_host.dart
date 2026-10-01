import 'dart:async';
import 'dart:typed_data';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/domain/capture/notification/capture_inbox_entry.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_capture_gateway.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_capture_settings.dart';
import 'package:saldough/features/record/domain/capture/notification/notification_capture_store.dart';
import 'package:saldough/features/record/domain/capture/notification/process_captured_notifications.dart';
import 'package:saldough/features/record/presentation/capture/notification/sync_notification_capture.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Pemicu pemrosesan Catat dari notifikasi (ADR-032 §3.1), dipasang shell di
/// atas tab: saat dibuka, saat kembali ke depan, saat layanan native memberi
/// tahu tangkapan baru, dan saat pengingat diketuk. Tanpa registrasi fitur
/// (platform lain, uji), hanya meneruskan [child].
class NotificationCaptureHost extends StatefulWidget {
  /// Membuat [NotificationCaptureHost].
  const NotificationCaptureHost({required this.container, required this.child, super.key});

  /// Container akar tempat modul notifikasi terdaftar. Diberikan eksplisit
  /// karena shell berada di bawah scope fitur yang terisolasi (ADR-030).
  final GetIt container;

  /// Isi shell.
  final Widget child;

  @override
  State<NotificationCaptureHost> createState() => _NotificationCaptureHostState();
}

class _NotificationCaptureHostState extends State<NotificationCaptureHost> with WidgetsBindingObserver {
  NotificationCaptureGateway? _gateway;
  late NotificationCaptureStore _store;
  ProcessCapturedNotifications? _process;
  late CaptureInboxActions _actions;
  final _subscriptions = <StreamSubscription<Object?>>[];
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gateway != null) return;
    final container = widget.container;
    if (!container.isRegistered<NotificationCaptureGateway>()) return;
    final gateway = container<NotificationCaptureGateway>();
    if (!gateway.isSupported) return;
    _gateway = gateway;
    _store = container<NotificationCaptureStore>();
    _process = container<ProcessCapturedNotifications>();
    _actions = container<CaptureInboxActions>();
    _subscriptions
      ..add(gateway.captured.listen((_) => unawaited(_run())))
      ..add(gateway.reminderTaps.listen((id) => unawaited(_openCapture(id))));
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  Future<void> _start() async {
    final settings = (await _store.loadSettings()).getOrElse((_) => const NotificationCaptureSettings());
    // Teks pengingat native mengikuti bahasa aplikasi yang mungkin berganti.
    await syncNotificationCapture(_gateway!, settings);
    await _run();
    final tap = await _gateway!.takeLaunchReminderTap();
    if (tap != null) await _openCapture(tap);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed && _process != null) unawaited(_run());
  }

  Future<void> _run() async {
    final process = _process;
    if (process == null) return;
    final result = await process();
    if (!mounted || result.isEmpty) return;
    final settings = (await _store.loadSettings()).getOrElse((_) => const NotificationCaptureSettings());
    if (!mounted) return;
    final texts = t.notificationCapture;
    if (_lifecycle == AppLifecycleState.resumed) {
      // Di depan: snackbar cukup; yang perlu ditinjau tampil di kartu Beranda.
      if (result.recorded.isEmpty) return;
      final message = result.recorded.length == 1
          ? texts.autoRecordedSnack(
              amount: AppMoneyFormatter.format(result.recorded.single.amountSen),
              app: result.recorded.single.appLabel,
            )
          : texts.autoRecordedSnackMany(n: result.recorded.length);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: texts.reviewAction,
            onPressed: () => unawaited(context.pushRoute(RecordRouteKeys.captureInbox, const EmptyInput())),
          ),
        ),
      );
      return;
    }
    // Di latar (mesin masih hidup) dan mode pengingat: satu notifikasi per tangkapan.
    if (settings.delivery != NotificationDelivery.reminderAndInbox) return;
    for (final entry in result.recorded) {
      await _gateway!.showReminder(
        captureId: entry.captureId,
        title: texts.reminderRecordedTitle(amount: AppMoneyFormatter.format(entry.amountSen), app: entry.appLabel),
        body: texts.reminderRecordedBody,
        icon: await _iconBytes(entry.iconId),
      );
    }
    for (final entry in result.queued) {
      final amount = entry.draft.amountSen;
      await _gateway!.showReminder(
        captureId: entry.id,
        title: texts.reminderReviewTitle(
          amount: amount == null ? texts.amountUnknown : AppMoneyFormatter.format(amount),
          app: entry.appLabel,
        ),
        body: texts.reminderReviewBody,
        icon: await _iconBytes(entry.iconId),
      );
    }
  }

  /// PNG ikon tangkapan untuk ikon besar pengingat (ADR-032 §3.10).
  Future<Uint8List?> _iconBytes(String? id) async {
    final container = widget.container;
    if (id == null || !container.isRegistered<SourceIconRepository>()) return null;
    return (await container<SourceIconRepository>().read(id)).getOrElse((_) => null);
  }

  /// Ketukan pengingat: tangkapan yang menunggu langsung membuka CATAT
  /// terisi; selain itu (tercatat otomatis, atau belum diproses) kotak masuk.
  Future<void> _openCapture(String id) async {
    await _run();
    if (!mounted) return;
    final inbox = (await _store.loadInbox()).getOrElse((_) => const <CaptureInboxEntry>[]);
    final entry = inbox.where((e) => e.id == id).firstOrNull;
    if (!mounted) return;
    if (entry == null) {
      await context.pushRoute(RecordRouteKeys.captureInbox, const EmptyInput());
      return;
    }
    final saved = await context.pushRoute<RecordSheetInput, bool>(
      RecordRouteKeys.sheet,
      RecordSheetInput(draft: entry.draft),
    );
    if (saved ?? false) await _actions.remove(entry.id);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
