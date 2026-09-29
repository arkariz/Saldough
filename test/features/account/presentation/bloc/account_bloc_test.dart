import 'package:bloc_test/bloc_test.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/account/presentation/bloc/account_bloc.dart';
import 'package:saldough/features/account/presentation/bloc/account_state.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:state_management/state_management.dart';

import '../../../../helpers/fake_auth_repository.dart';

AuthenticationFailure _auth(FailureCode code) => AuthenticationFailure(code: code, message: 'uji');

void main() {
  late FakeAuthRepository repository;
  late CurrencyPreferenceRepository currencyRepository;

  setUp(() {
    repository = FakeAuthRepository();
    currencyRepository = CurrencyPreferenceRepositoryImpl(storage: InMemoryKeyValueStorage());
  });

  AccountBloc buildBloc() => AccountBloc(authRepository: repository, currencyRepository: currencyRepository);

  String? messageOf(AccountState state) => (state.effect as ShowSnackBarEffect?)?.message;
  FeedbackSeverity? severityOf(AccountState state) => (state.effect as ShowSnackBarEffect?)?.severity;

  group('masuk', () {
    blocTest<AccountBloc, AccountState>(
      'Google berhasil: pending googleSignIn lalu pengguna terisi dengan pesan sukses',
      build: buildBloc,
      act: (bloc) => bloc.add(const AccountGoogleSignInRequested()),
      expect: () => [
        isA<AccountState>().having((s) => s.pending, 'pending', AccountAction.googleSignIn),
        isA<AccountState>()
            .having((s) => s.pending, 'pending', isNull)
            .having((s) => s.user, 'user', FakeAuthRepository.user)
            .having(messageOf, 'pesan', t.account.signedInMessage),
      ],
    );

    blocTest<AccountBloc, AccountState>(
      'Google dibatalkan pengguna: tidak ada pesan galat',
      build: buildBloc,
      setUp: () => repository.nextGoogle = left(_auth(AuthFailureCodes.canceled)),
      act: (bloc) => bloc.add(const AccountGoogleSignInRequested()),
      expect: () => [
        isA<AccountState>().having((s) => s.pending, 'pending', AccountAction.googleSignIn),
        isA<AccountState>()
            .having((s) => s.pending, 'pending', isNull)
            .having((s) => s.user, 'user', isNull)
            .having((s) => s.effect, 'effect', isNull),
      ],
    );

    blocTest<AccountBloc, AccountState>(
      'galat jaringan: pesan jaringan dari i18n',
      build: buildBloc,
      setUp: () => repository.nextGoogle = left(const NetworkFailure(code: AuthFailureCodes.network, message: 'uji')),
      act: (bloc) => bloc.add(const AccountGoogleSignInRequested()),
      skip: 1,
      expect: () => [
        isA<AccountState>()
            .having(messageOf, 'pesan', t.account.errors.network)
            .having(severityOf, 'severity', FeedbackSeverity.error),
      ],
    );

    blocTest<AccountBloc, AccountState>(
      'email/sandi salah: pesan kredensial salah',
      build: buildBloc,
      setUp: () => repository.nextEmail = left(_auth(AuthFailureCodes.wrongCredentials)),
      act: (bloc) => bloc.add(const AccountEmailSignInRequested(email: 'a@b.c', password: 'x')),
      expect: () => [
        isA<AccountState>().having((s) => s.pending, 'pending', AccountAction.emailSignIn),
        isA<AccountState>().having(messageOf, 'pesan', t.account.errors.wrongCredentials),
      ],
    );

    blocTest<AccountBloc, AccountState>(
      'email kosong: peringatan tanpa memanggil repository',
      build: buildBloc,
      act: (bloc) => bloc.add(const AccountEmailSignInRequested(email: '', password: 'x')),
      expect: () => [
        isA<AccountState>()
            .having(messageOf, 'pesan', t.account.emailRequired)
            .having(severityOf, 'severity', FeedbackSeverity.warning)
            .having((s) => s.pending, 'pending', isNull),
      ],
    );
  });

  group('keluar', () {
    blocTest<AccountBloc, AccountState>(
      'berhasil: pengguna dikosongkan dengan pesan',
      build: () {
        repository = FakeAuthRepository(signedIn: FakeAuthRepository.user);
        return buildBloc();
      },
      seed: () => const AccountState(user: FakeAuthRepository.user),
      act: (bloc) => bloc.add(const AccountSignOutRequested()),
      expect: () => [
        isA<AccountState>().having((s) => s.pending, 'pending', AccountAction.signOut),
        isA<AccountState>()
            .having((s) => s.user, 'user', isNull)
            .having(messageOf, 'pesan', t.account.signedOutMessage),
      ],
    );
  });

  group('hapus akun', () {
    blocTest<AccountBloc, AccountState>(
      'berhasil: pengguna dikosongkan dengan pesan dihapus',
      build: buildBloc,
      seed: () => const AccountState(user: FakeAuthRepository.user),
      act: (bloc) => bloc.add(const AccountDeletionRequested()),
      expect: () => [
        isA<AccountState>().having((s) => s.pending, 'pending', AccountAction.delete),
        isA<AccountState>().having((s) => s.user, 'user', isNull).having(messageOf, 'pesan', t.account.deletedMessage),
      ],
    );

    blocTest<AccountBloc, AccountState>(
      'butuh sandi: needsPassword, lalu dikirim ulang dengan sandi dan berhasil',
      build: buildBloc,
      setUp: () => repository.nextDeletes.add(left(_auth(AuthFailureCodes.passwordRequired))),
      seed: () => const AccountState(user: FakeAuthRepository.user),
      act: (bloc) async {
        bloc.add(const AccountDeletionRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AccountDeletionRequested(password: 'rahasia'));
      },
      expect: () => [
        isA<AccountState>().having((s) => s.pending, 'pending', AccountAction.delete),
        isA<AccountState>()
            .having((s) => s.needsPassword, 'needsPassword', isTrue)
            .having((s) => s.effect, 'effect', isNull)
            .having((s) => s.user, 'user', FakeAuthRepository.user),
        isA<AccountState>()
            .having((s) => s.pending, 'pending', AccountAction.delete)
            .having((s) => s.needsPassword, 'needsPassword', isFalse),
        isA<AccountState>().having((s) => s.user, 'user', isNull),
      ],
      verify: (_) => expect(repository.deletePasswords, [null, 'rahasia']),
    );
  });

  blocTest<AccountBloc, AccountState>(
    'AccountStarted membaca pengguna saat ini lalu mengikuti perubahan status masuk',
    build: () {
      repository = FakeAuthRepository(signedIn: FakeAuthRepository.user);
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const AccountStarted());
      await Future<void>.delayed(Duration.zero);
      await repository.signOut();
    },
    expect: () => [
      isA<AccountState>().having((s) => s.user, 'user', FakeAuthRepository.user),
      isA<AccountState>().having((s) => s.user, 'user', isNull),
    ],
  );

  group('mata uang (ADR-025)', () {
    tearDown(() => ActiveCurrency.notifier.value = AppCurrency.idr);

    blocTest<AccountBloc, AccountState>(
      'menyimpan pilihan, memasang mata uang aktif, lalu memberi pesan sukses',
      build: buildBloc,
      act: (bloc) => bloc.add(const AccountCurrencyChangeRequested(AppCurrency.usd)),
      expect: () => [
        isA<AccountState>()
            .having(messageOf, 'pesan', t.currency.changedMessage(code: 'USD'))
            .having(severityOf, 'severity', FeedbackSeverity.success),
      ],
      verify: (_) async {
        expect(ActiveCurrency.value, AppCurrency.usd);
        expect((await currencyRepository.load()).getOrElse((_) => AppCurrency.idr), AppCurrency.usd);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'memilih mata uang yang sedang aktif tidak melakukan apa-apa',
      build: buildBloc,
      act: (bloc) => bloc.add(const AccountCurrencyChangeRequested(AppCurrency.idr)),
      expect: () => <AccountState>[],
    );
  });
}
