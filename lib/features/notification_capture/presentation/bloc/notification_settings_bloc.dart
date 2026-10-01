import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
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
    this.userPatterns = const [],
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

  /// Pola buatan pengguna.
  final List<NotificationPattern> userPatterns;

  /// Sampel debug (ADR-032 §3.6).
  final List<CapturedNotification> debugSamples;

  @override
  NotificationSettingsState copyWith({
    bool? isLoading,
    NotificationCaptureSettings? settings,
    bool? accessGranted,
    bool? canPostReminders,
    List<Wallet>? wallets,
    List<NotificationPattern>? userPatterns,
    List<CapturedNotification>? debugSamples,
    UiEffect? effect,
  }) => NotificationSettingsState(
    isLoading: isLoading ?? this.isLoading,
    settings: settings ?? this.settings,
    accessGranted: accessGranted ?? this.accessGranted,
    canPostReminders: canPostReminders ?? this.canPostReminders,
    wallets: wallets ?? this.wallets,
    userPatterns: userPatterns ?? this.userPatterns,
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
    userPatterns,
    debugSamples,
  ];
}

/// Bloc layar setelan Catat dari notifikasi (ADR-032 §3.2–3.8). Setiap
/// perubahan setelan disimpan lalu dikirim ke layanan native.
final class NotificationSettingsBloc extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  /// Membuat [NotificationSettingsBloc].
  NotificationSettingsBloc({required this._gateway, required this._store, required this._walletRepository})
    : super(const NotificationSettingsState()) {
    on<NotificationSettingsStarted>(_onStarted);
    on<NotificationSettingsResumed>(_onResumed);
    on<NotificationCaptureToggled>((e, emit) => _saveSettings(state.settings.copyWith(enabled: e.enabled), emit));
    on<NotificationDeliveryChanged>(_onDeliveryChanged);
    on<AutoRecordLevelChanged>((e, emit) => _saveSettings(state.settings.copyWith(autoRecordLevel: e.level), emit));
    on<NotificationSourceSaved>(_onSourceSaved);
    on<NotificationSourceRemoved>(_onSourceRemoved);
    on<BuiltInPatternToggled>(_onBuiltInToggled);
    on<NotificationPatternSaved>(_onPatternSaved);
    on<NotificationPatternDeleted>(_onPatternDeleted);
    on<DebugSamplesRequested>(_onDebugSamples);
  }

  final NotificationCaptureGateway _gateway;
  final NotificationCaptureStore _store;
  final WalletRepository _walletRepository;

  Future<void> _onStarted(NotificationSettingsStarted event, Emitter<NotificationSettingsState> emit) async {
    final settings = (await _store.loadSettings()).getOrElse((_) => const NotificationCaptureSettings());
    final patterns = (await _store.loadPatterns()).getOrElse((_) => const []);
    final wallets = (await _walletRepository.listWallets())
        .getOrElse((_) => const [])
        .where((w) => w.isActive)
        .toList();
    emit(
      state.copyWith(
        isLoading: false,
        settings: settings,
        userPatterns: patterns,
        wallets: wallets,
        accessGranted: await _gateway.isAccessGranted(),
        canPostReminders: await _gateway.canPostReminders(),
        debugSamples: await _gateway.debugSamples(),
      ),
    );
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
    final patterns = [
      for (final p in state.userPatterns)
        if (p.packageName != event.packageName) p,
    ];
    if (patterns.length != state.userPatterns.length) await _savePatterns(patterns, emit);
  }

  Future<void> _onBuiltInToggled(BuiltInPatternToggled event, Emitter<NotificationSettingsState> emit) async {
    final disabled = {...state.settings.disabledBuiltInPatternIds};
    if (event.enabled) {
      disabled.remove(event.patternId);
    } else {
      disabled.add(event.patternId);
    }
    await _saveSettings(state.settings.copyWith(disabledBuiltInPatternIds: disabled), emit);
  }

  Future<void> _onPatternSaved(NotificationPatternSaved event, Emitter<NotificationSettingsState> emit) async {
    final patterns = [...state.userPatterns];
    final index = patterns.indexWhere((p) => p.id == event.pattern.id);
    if (index < 0) {
      patterns.add(event.pattern);
    } else {
      patterns[index] = event.pattern;
    }
    await _savePatterns(patterns, emit);
  }

  Future<void> _onPatternDeleted(NotificationPatternDeleted event, Emitter<NotificationSettingsState> emit) async {
    await _savePatterns([
      for (final p in state.userPatterns)
        if (p.id != event.patternId) p,
    ], emit);
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
        await syncNotificationCapture(_gateway, settings);
    }
  }

  Future<void> _savePatterns(List<NotificationPattern> patterns, Emitter<NotificationSettingsState> emit) async {
    switch (await _store.savePatterns(patterns)) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _error(failure)));
      case Right():
        emit(state.copyWith(userPatterns: patterns));
    }
  }

  /// Membuka setelan akses notifikasi sistem (sesudah pengungkapan jelas,
  /// ADR-032 §3.8). Bukan event: tidak mengubah state; layar mengecek ulang
  /// akses saat kembali (`NotificationSettingsResumed`).
  Future<void> openAccessSettings() => _gateway.openAccessSettings();

  /// Aplikasi peluncur terpasang untuk pemilih sumber.
  Future<Either<Failure, List<InstalledApp>>> loadInstalledApps() => _gateway.installedApps();

  UiEffect _error(Failure failure) =>
      ShowSnackBarEffect(message: failure.userMessage ?? t.common.genericErrorMessage, severity: .error);
}
