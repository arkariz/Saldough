import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/quick_start_apps.dart';
import 'package:saldough/features/notification_capture/presentation/host/sync_notification_capture.dart';
import 'package:saldough/shared/recurring/recurring.dart';
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
    this.recurringRules = const [],
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

  /// Pola buatan pengguna.
  final List<NotificationPattern> userPatterns;

  /// Rutin yang bisa diikat ke pola (ADR-042 §3.4).
  final List<RecurringRule> recurringRules;

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
    List<NotificationPattern>? userPatterns,
    List<RecurringRule>? recurringRules,
    List<CapturedNotification>? samples,
    List<CapturedNotification>? debugSamples,
    UiEffect? effect,
  }) => NotificationSettingsState(
    isLoading: isLoading ?? this.isLoading,
    settings: settings ?? this.settings,
    accessGranted: accessGranted ?? this.accessGranted,
    canPostReminders: canPostReminders ?? this.canPostReminders,
    wallets: wallets ?? this.wallets,
    userPatterns: userPatterns ?? this.userPatterns,
    recurringRules: recurringRules ?? this.recurringRules,
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
    userPatterns,
    recurringRules,
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
    this._recurringRules,
    this._recurringChanges,
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
    on<BuiltInPatternToggled>(_onBuiltInToggled);
    on<NotificationPatternSaved>(_onPatternSaved);
    on<NotificationPatternDeleted>(_onPatternDeleted);
    on<NotificationPatternBound>(_onPatternBound);
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
  final RecurringRuleRepository? _recurringRules;
  final RecurringChanges? _recurringChanges;

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
        recurringRules: await _loadRules(),
        wallets: wallets,
        accessGranted: await _gateway.isAccessGranted(),
        canPostReminders: await _gateway.canPostReminders(),
        debugSamples: await _gateway.debugSamples(),
      ),
    );
  }

  Future<List<RecurringRule>> _loadRules() async {
    final repository = _recurringRules;
    if (repository == null) return const [];
    return (await repository.listRules()).getOrElse((_) => const []);
  }

  /// Mengikat pola ke rutin (ADR-042 §3.4): satu pola ke satu rutin, satu
  /// rutin ke satu pola. Ikatan lama pola ini dan rutin ini dilepas lebih dulu.
  Future<void> _onPatternBound(NotificationPatternBound event, Emitter<NotificationSettingsState> emit) async {
    final repository = _recurringRules;
    if (repository == null) return;
    final rules = await _loadRules();
    var changed = false;
    for (final rule in rules) {
      final current = rule.notificationBinding;
      final holdsPattern = current?.packageName == event.packageName && current?.patternId == event.patternId;
      final isTarget = rule.id == event.ruleId;
      if (!holdsPattern && !isTarget) continue;
      final next = isTarget
          ? NotificationBinding(
              packageName: event.packageName,
              patternId: event.patternId,
              patternLabel: event.patternLabel,
            )
          : null;
      if (current == next) continue;
      if ((await repository.saveRule(rule.withNotificationBinding(next))).isLeft()) return;
      changed = true;
    }
    if (changed) _recurringChanges?.notifyChanged(source: this);
    emit(state.copyWith(recurringRules: await _loadRules()));
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
    emit(state.copyWith(samples: await _gateway.samples(event.packageName)));
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
    // Pola yang dihapus melepas rutin yang terikat padanya (ADR-042 §3.4).
    final repository = _recurringRules;
    if (repository != null) {
      for (final rule in await _loadRules()) {
        if (rule.notificationBinding?.patternId == event.patternId) {
          await repository.saveRule(rule.withNotificationBinding(null));
        }
      }
      emit(state.copyWith(recurringRules: await _loadRules()));
    }
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
        _statusChanges?.notify();
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

  /// Jumlah aplikasi aktif sesudah [applyQuickStart] terakhir (analitik).
  int quickStartAppsCount = 0;

  /// Mulai cepat (FEATURE_DISCOVERY §5.1): menyimpan [picked] sebagai sumber
  /// dan menyalakan fitur dalam satu simpanan, lalu menyegarkan state.
  /// Bukan event karena pemanggil menunggu hasilnya untuk memutuskan lanjut
  /// ke izin akses.
  Future<QuickStartResult> applyQuickStart(List<NotificationSource> picked) async {
    final settings = state.settings.copyWith(
      enabled: true,
      sources: mergeQuickStartSources(state.settings.sources, picked),
    );
    if ((await _store.saveSettings(settings)).isLeft()) return QuickStartResult.failed;
    _statusChanges?.notify();
    await syncNotificationCapture(_gateway, settings);
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
