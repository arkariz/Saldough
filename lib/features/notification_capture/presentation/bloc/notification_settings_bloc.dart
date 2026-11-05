import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/quick_start_apps.dart';
import 'package:saldough/features/notification_capture/presentation/host/sync_notification_capture.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'notification_settings_event.dart';

/// State layar setelan Catat dari notifikasi.
final class NotificationSettingsState extends UiState<NotificationSettingsState> {
  /// Membuat [NotificationSettingsState].
  const NotificationSettingsState({
    this.isLoading = true,
    this.settings = const NotificationCaptureSettings(),
    this.accessGranted = false,
    this.canPostReminders = false,
    this.wallets = const [],
    this.samples = const [],
    this.debugSamples = const [],
    super.effect,
  });

  /// Sedang memuat.
  final bool isLoading;

  /// Setelan tersimpan.
  final NotificationCaptureSettings settings;

  /// Akses notifikasi sistem sudah diberikan.
  final bool accessGranted;

  /// Izin memunculkan notifikasi sudah ada.
  final bool canPostReminders;

  /// Dompet aktif.
  final List<Wallet> wallets;

  /// Contoh notifikasi aplikasi yang sedang dibuka (ADR-042 §3.2).
  final List<CapturedNotification> samples;

  /// Sampel debug (ADR-032 §3.6).
  final List<CapturedNotification> debugSamples;

  @override
  NotificationSettingsState copyWith({
    bool? isLoading,
    NotificationCaptureSettings? settings,
    bool? accessGranted,
    bool? canPostReminders,
    List<Wallet>? wallets,
    List<CapturedNotification>? samples,
    List<CapturedNotification>? debugSamples,
    UiEffect? effect,
  }) => NotificationSettingsState(
    isLoading: isLoading ?? this.isLoading,
    settings: settings ?? this.settings,
    accessGranted: accessGranted ?? this.accessGranted,
    canPostReminders: canPostReminders ?? this.canPostReminders,
    wallets: wallets ?? this.wallets,
    samples: samples ?? this.samples,
    debugSamples: debugSamples ?? this.debugSamples,
    effect: effect,
  );

  @override
  List<Object?> get props => [
    isLoading,
    settings,
    accessGranted,
    canPostReminders,
    wallets,
    samples,
    debugSamples,
  ];
}

/// Hasil [NotificationSettingsBloc.applyQuickStart].
enum QuickStartResult {
  /// Setelan gagal disimpan.
  failed,

  /// Tersimpan, tetapi akses notifikasi sistem belum diberikan.
  needsAccess,

  /// Tersimpan dan akses sudah ada.
  ready,
}

/// Bloc layar setelan Catat dari notifikasi (ADR-032 §3.2–3.8). Setiap
/// perubahan setelan disimpan lalu dikirim ke layanan native.
final class NotificationSettingsBloc extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  /// Membuat [NotificationSettingsBloc].
  NotificationSettingsBloc({
    required this._gateway,
    required this._store,
    required this._walletRepository,
    this._statusChanges,
  }) : super(const NotificationSettingsState()) {
    on<NotificationSettingsStarted>(_onStarted);
    on<NotificationSettingsResumed>(_onResumed);
    on<NotificationCaptureToggled>((e, emit) async {
      await _saveSettings(state.settings.copyWith(enabled: e.enabled), emit);
      // Sakelar dinyalakan lewat setelan (FEATURE_DISCOVERY §9).
      if (e.enabled && state.settings.enabled) {
        AppAnalytics.log(DiscoveryEvents.featureEnabled(feature: 'notification', via: 'account'));
      }
    });
    on<NotificationDeliveryChanged>(_onDeliveryChanged);
    on<AutoRecordLevelChanged>((e, emit) => _saveSettings(state.settings.copyWith(autoRecordLevel: e.level), emit));
    on<AutoRecordToggled>(_onAutoRecordToggled);
    on<NotificationSourceSaved>(_onSourceSaved);
    on<NotificationSourceRemoved>(_onSourceRemoved);
    on<NotificationSamplesToggled>(_onSamplesToggled);
    on<NotificationSamplesRequested>(_onSamplesRequested);
    on<DebugSamplesRequested>(_onDebugSamples);
  }

  /// Tingkat otomatis terakhir sebelum Catat otomatis dimatikan. Hanya di
  /// memori: setelan tetap satu tingkat tersimpan (keputusan pemilik 9 Okt
  /// 2026, QA PR #43 F20).
  AutoRecordLevel _lastAutoLevel = AutoRecordLevel.whenComplete;

  Future<void> _onAutoRecordToggled(AutoRecordToggled event, Emitter<NotificationSettingsState> emit) {
    final current = state.settings.autoRecordLevel;
    if (!event.on && current != AutoRecordLevel.reviewAll) _lastAutoLevel = current;
    final level = event.on ? _lastAutoLevel : AutoRecordLevel.reviewAll;
    return _saveSettings(state.settings.copyWith(autoRecordLevel: level), emit);
  }

  final NotificationCaptureGateway _gateway;
  final NotificationCaptureStore _store;
  final FeatureStatusChanges? _statusChanges;
  final WalletRepository _walletRepository;

  Future<void> _onStarted(NotificationSettingsStarted event, Emitter<NotificationSettingsState> emit) async {
    final settings = (await _store.loadSettings()).getOrElse((_) => const NotificationCaptureSettings());
    final wallets = (await _walletRepository.listWallets())
        .getOrElse((_) => const [])
        .where((w) => w.isActive)
        .toList();
    emit(
      state.copyWith(
        isLoading: false,
        settings: settings,
        wallets: wallets,
        accessGranted: await _gateway.isAccessGranted(),
        canPostReminders: await _gateway.canPostReminders(),
        debugSamples: await _gateway.debugSamples(),
      ),
    );
  }

  /// Menyalakan atau mematikan penyimpanan contoh (ADR-042 §3.2). Mematikan
  /// menghapus semua contoh yang sudah tersimpan.
  Future<void> _onSamplesToggled(NotificationSamplesToggled event, Emitter<NotificationSettingsState> emit) async {
    await _saveSettings(state.settings.copyWith(saveSamples: event.on), emit);
    if (!event.on) {
      await _gateway.clearSamples();
      emit(state.copyWith(samples: const []));
    }
  }

  Future<void> _onSamplesRequested(NotificationSamplesRequested event, Emitter<NotificationSettingsState> emit) async {
    // `await` dulu, baru `state`: `state.copyWith(x: await ...)` membaca state
    // sebelum menunggu dan menimpa setelan yang tersimpan selagi menunggu (F23-5).
    final samples = await _gateway.samples(event.packageName);
    emit(state.copyWith(samples: samples));
  }

  Future<void> _onResumed(NotificationSettingsResumed event, Emitter<NotificationSettingsState> emit) async {
    emit(
      state.copyWith(
        accessGranted: await _gateway.isAccessGranted(),
        canPostReminders: await _gateway.canPostReminders(),
        debugSamples: await _gateway.debugSamples(),
      ),
    );
  }

  Future<void> _onDeliveryChanged(NotificationDeliveryChanged event, Emitter<NotificationSettingsState> emit) async {
    if (event.delivery == NotificationDelivery.reminderAndInbox && !await _gateway.canPostReminders()) {
      final granted = await _gateway.requestReminderPermission();
      if (!granted) {
        emit(
          state.copyWith(
            canPostReminders: false,
            effect: ShowSnackBarEffect(message: t.notificationCapture.reminderPermissionDenied, severity: .error),
          ),
        );
        return;
      }
      emit(state.copyWith(canPostReminders: true));
    }
    await _saveSettings(state.settings.copyWith(delivery: event.delivery), emit);
  }

  Future<void> _onSourceSaved(NotificationSourceSaved event, Emitter<NotificationSettingsState> emit) async {
    final sources = [...state.settings.sources];
    final index = sources.indexWhere((s) => s.packageName == event.source.packageName);
    if (index < 0) {
      sources.add(event.source);
    } else {
      sources[index] = event.source;
    }
    await _saveSettings(state.settings.copyWith(sources: sources), emit);
  }

  Future<void> _onSourceRemoved(NotificationSourceRemoved event, Emitter<NotificationSettingsState> emit) async {
    await _saveSettings(
      state.settings.copyWith(
        sources: [
          for (final s in state.settings.sources)
            if (s.packageName != event.packageName) s,
        ],
      ),
      emit,
    );
    await _gateway.clearSamples(packageName: event.packageName);
  }

  Future<void> _onDebugSamples(DebugSamplesRequested event, Emitter<NotificationSettingsState> emit) async {
    emit(state.copyWith(debugSamples: await _gateway.debugSamples()));
  }

  Future<void> _saveSettings(NotificationCaptureSettings settings, Emitter<NotificationSettingsState> emit) async {
    switch (await _store.saveSettings(settings)) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _error(failure)));
      case Right():
        emit(state.copyWith(settings: settings));
        _statusChanges?.notify();
        await syncNotificationCapture(_gateway, settings);
    }
  }

  /// Membuka setelan akses notifikasi sistem (sesudah pengungkapan jelas,
  /// ADR-032 §3.8). Bukan event: tidak mengubah state; layar mengecek ulang
  /// akses saat kembali (`NotificationSettingsResumed`).
  Future<void> openAccessSettings() => _gateway.openAccessSettings();

  /// Jumlah aplikasi aktif sesudah [applyQuickStart] terakhir (analitik).
  int quickStartAppsCount = 0;

  /// Mulai cepat (FEATURE_DISCOVERY §5.1): menyimpan [picked] sebagai sumber
  /// dan menyalakan fitur dalam satu simpanan, lalu menyegarkan state.
  /// Bukan event karena pemanggil menunggu hasilnya untuk memutuskan lanjut
  /// ke izin akses.
  ///
  /// [askNotificationPermission]: Plus mendapat notifikasi bertindak secara bawaan
  /// (ADR-044 §3.5), jadi izin memunculkan notifikasi diminta di sini, sebelum
  /// pengguna keluar ke setelan akses.
  Future<QuickStartResult> applyQuickStart(
    List<NotificationSource> picked, {
    bool askNotificationPermission = false,
  }) async {
    final settings = state.settings.copyWith(
      enabled: true,
      sources: mergeQuickStartSources(state.settings.sources, picked),
    );
    if ((await _store.saveSettings(settings)).isLeft()) return QuickStartResult.failed;
    _statusChanges?.notify();
    await syncNotificationCapture(_gateway, settings);
    if (askNotificationPermission && !await _gateway.canPostReminders()) await _gateway.requestReminderPermission();
    final granted = await _gateway.isAccessGranted();
    quickStartAppsCount = settings.sources.where((source) => source.enabled).length;
    add(const NotificationSettingsStarted());
    return granted ? QuickStartResult.ready : QuickStartResult.needsAccess;
  }

  /// Aplikasi peluncur terpasang untuk pemilih sumber.
  Future<Either<Failure, List<InstalledApp>>> loadInstalledApps() => _gateway.installedApps();

  UiEffect _error(Failure failure) =>
      ShowSnackBarEffect(message: failure.userMessage ?? t.common.genericErrorMessage, severity: .error);
}
