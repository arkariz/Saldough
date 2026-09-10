# Konvensi pengujian: fake tulis tangan, tanpa mocktail atau bloc_test

## 1. Metadata

- **Decision ID:** ADR-010
- **Tanggal:** 2026-09-10
- **Fase roadmap:** Fase 1
- **Status:** Accepted
- **Cakupan:** Global

## 2. Konteks

ARCHITECTURE_OVERVIEW.md versi pertama menetapkan `bloc_test` dan `mocktail`
sebagai alat pengujian, mengikuti kebiasaan umum ekosistem Flutter/BLoC.
Belum ada kode yang ditulis memakai kedua paket itu.

Pembacaan `pubspec.yaml` milik `flutter-architecture-studi-bank`
(`lib/v2/`, referensi arsitektur Saldough sejak [ADR-0009](0009-core-shared-features-zone-layout.md))
menunjukkan **tidak ada `mocktail` maupun `bloc_test`** di `dev_dependencies`
mereka — hanya `flutter_test`, `build_runner`, `injectable_generator`, dan
paket `linter` internal. Seluruh pengujian bloc dan domain di sana memakai
fake tulis tangan: kelas kecil bernama `_FakeXyz implements Interface`,
privat per berkas uji, dengan callback atau field sederhana untuk mengatur
perilaku per kasus uji.

Pola ini masuk akal untuk mereka dan untuk Saldough karena alasan yang sama:
interface yang diuji umumnya sempit. `AuthRepository` di repo acuan punya 14
metode, tapi setiap metode independen dan mudah di-fake satu per satu.
Interface Saldough (`CycleRepository`, `GoalRepository`, dst.) bahkan lebih
sempit — 2 sampai 4 metode.

## 3. Keputusan

Saldough memakai fake tulis tangan untuk seluruh pengujian domain dan bloc,
mengikuti pola repo acuan persis. `mocktail` dan `bloc_test` **tidak**
menjadi dependensi.

Fake ditulis sebagai `final class _FakeXyz implements Interface`, privat di
berkas uji, dikumpulkan di bagian atas berkas dengan komentar banner
`// ── Fakes ──`. Bloc diuji langsung lewat `bloc.add(...)` diikuti
`await bloc.stream.firstWhere((s) => ...)` atau `pumpEventQueue()`, bukan
lewat `blocTest(...)`. Setiap pembuatan bloc dalam uji diikuti
`addTearDown(bloc.close)`.

## 4. Verbatim dari eksplorasi

Fake untuk bloc:

```dart
final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({Future<Either<Failure, User>> Function()? login}) : _login = login;
  final Future<Either<Failure, User>> Function()? _login;
  int loginCalls = 0;

  @override
  Future<Either<Failure, User>> login({required String username, required String password}) async {
    loginCalls++;
    return _login!();
  }

  @override
  Future<Either<Failure, String>> enableFingerprint() => throw UnimplementedError();
  // metode lain yang tidak dipakai skenario ini cukup throw UnimplementedError()
}
```

Pola uji bloc:

```dart
test('sign-in gagal menampilkan pesan dan tetap idle', () async {
  final bloc = makeBloc(
    login: () async => left(const SystemFailure(code: FailureCode.unknown, message: 'boom')),
  );
  addTearDown(bloc.close);

  bloc.add(const AuthStarted());
  await bloc.stream.first;
  bloc.add(const AuthSignInSubmitted(username: 'x', password: 'y'));
  final state = await bloc.stream.firstWhere((s) => s.hasEffect);

  expect(state, isA<AuthAnonymous>());
  expect((state.effect! as ShowSnackBarEffect).message, 'boom');
});
```

Fake untuk use case domain:

```dart
final class _FakeSessionStore implements SessionStore {
  String? savedUsername;
  @override
  Future<String?> get username async => savedUsername;
  @override
  Future<void> setUsername(String value) async => savedUsername = value;
  // ...
}
```

Untuk Saldough, contoh setaranya:

```dart
final class _FakeCycleRepository implements CycleRepository {
  _FakeCycleRepository({Either<Failure, MonthlyCycle> Function(String)? getCycle})
      : _getCycle = getCycle;
  final Either<Failure, MonthlyCycle> Function(String)? _getCycle;

  @override
  Future<Either<Failure, MonthlyCycle>> getCycle(String id) async =>
      _getCycle?.call(id) ?? right(MonthlyCycle.empty(id));
}
```

## 5. Opsi yang dipertimbangkan

- **Opsi A — `mocktail` + `bloc_test`** *(rencana awal)*
- **Opsi B — fake tulis tangan, tanpa pustaka mocking (Dipilih)**

## 6. Analisis konsekuensi

### Opsi A — `mocktail` + `bloc_test`

Lebih ringkas untuk interface besar dengan banyak metode yang tidak relevan
per kasus uji (`when(...).thenAnswer(...)` tidak perlu mengimplementasikan
seluruh interface). Lebih dikenal luas di ekosistem Flutter, sehingga
kontributor baru lebih cepat produktif.

Tapi menyimpang dari konvensi produksi yang sudah divalidasi sebagai referensi
arsitektur, dan menambah dua dependensi yang terbukti tidak diperlukan pada
skala interface Saldough.

### Opsi B — fake tulis tangan, tanpa pustaka mocking (Dipilih)

Cocok persis dengan referensi arsitektur. Tidak ada dependensi mocking untuk
dipelajari. Kompilator memaksa setiap fake mengimplementasikan seluruh
interface, yang untuk interface sempit (2-4 metode) bukan beban — dan
justru membuat perubahan interface cepat ketahuan (setiap fake yang tidak
ikut diperbarui langsung gagal kompilasi, bukan diam-diam lolos seperti
`mocktail` yang membiarkan metode tak terpakai).

Kelemahannya muncul kalau nanti ada interface besar (tidak terlihat di MVP
Saldough): setiap fake harus mengimplementasikan seluruh metode, meski
sebagian besar cukup `throw UnimplementedError()`. Diterima, karena interface
Saldough memang kecil by design (lihat [DOMAIN_MODEL.md](../DOMAIN_MODEL.md)).

## 7. Konsekuensi

### Yang menjadi lebih mudah

- Tidak ada dependensi mocking untuk dipelajari atau di-upgrade.
- Perubahan interface langsung ketahuan dari galat kompilasi di setiap fake.
- Kode uji bisa dibandingkan langsung dengan pola repo acuan.

### Yang menjadi lebih sulit

- Fake untuk interface besar (kalau muncul nanti) lebih verbose daripada
  mocktail.
- Tidak ada `verify(...).called(n)` siap pakai — verifikasi jumlah panggilan
  memakai counter manual (`int loginCalls = 0`) di dalam fake.

### Risiko yang diterima

- Kalau sebuah interface tumbuh jadi besar di luar rencana, biaya menulis
  fake ikut naik. Ditangani dengan menjaga interface tetap sempit sesuai
  prinsip domain Saldough, bukan dengan menambah mocktail saat itu terjadi.

## 8. Catatan implementasi

### Batasan yang harus dijaga

- Fake dideklarasikan `final class`, privat (`_FakeXyz`), di dalam berkas uji
  yang memakainya — tidak diekspor ke berkas lain.
- Metode yang tidak relevan untuk skenario tertentu cukup
  `=> throw UnimplementedError();`.
- Setiap pembuatan bloc dalam uji diikuti `addTearDown(bloc.close)`.
- Uji bloc memakai `bloc.add()` + `await bloc.stream.firstWhere(...)`, bukan
  `blocTest(...)`.

### Antipola yang harus dihindari

- Menambahkan `mocktail` atau `bloc_test` ke `pubspec.yaml`.
- Membuat fake bersama (`test/fakes/`) yang dipakai lintas berkas uji sebelum
  ada kebutuhan nyata — duplikasi kecil antar berkas uji lebih disukai
  daripada abstraksi dini.

## 9. Kriteria peninjauan ulang

- Sebuah interface tumbuh melewati ~8 metode dan fake-nya mulai terasa berat
  ditulis ulang di banyak berkas.
- Referensi arsitektur berganti ke konvensi yang memakai pustaka mocking.

## 10. Artefak terkait

### Dokumentasi

- [ARCHITECTURE_OVERVIEW.md](../ARCHITECTURE_OVERVIEW.md) bagian pengujian.
- [ADR-0009](0009-core-shared-features-zone-layout.md) untuk konteks
  penggantian referensi arsitektur.

### Rujukan kode

- `flutter-architecture-studi-bank`, `test/v2/features/auth/landing/presentation/bloc/auth_bloc_test.dart`,
  `test/v2/shared/session/handoff/domain/handoff_to_legacy_session_use_case_test.dart`.

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-10
**Status implementasi:** Disetujui, belum diimplementasikan
