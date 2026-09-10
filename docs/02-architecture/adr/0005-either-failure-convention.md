# Konvensi kesalahan: `Either<Failure, T>` via fpdart

## 1. Metadata

- **Decision ID:** ADR-005
- **Tanggal:** 2026-09-09, direvisi 2026-09-10
- **Fase roadmap:** Fase 1
- **Status:** Accepted (revisi)
- **Cakupan:** Global

> **Catatan revisi (2026-09-10):** Versi pertama ADR ini memilih konvensi
> lempar dan tangkap (`throw Failure` / `on Failure catch`). Keputusan itu
> **salah** dan sekarang dibalik. Alasannya ada di bagian 2. Seluruh isi di
> bawah ini menggantikan versi pertama; bagian 5 tetap mencantumkan opsi
> throw/catch sebagai opsi yang ditolak, dengan alasan penolakan yang baru.

## 2. Konteks

Versi pertama ADR ini (9 September 2026) memilih lempar dan tangkap
berdasarkan pembacaan `app_example`, proyek contoh kecil satu fitur di
`advance-mobile-platform`. Contoh itu memang menulis `throw Failure` dan
`on Failure catch`, dan `dartz`/`fpdart` memang tidak dipakai di sana.

Keesokan harinya, pemilik mengarahkan referensi arsitektur Saldough ke
`arkariz/flutter-architecture-studi-bank` (branch `refactor/platform-migration`,
folder `lib/v2`) — aplikasi mobile banking produksi yang memakai paket
**mobile-platform** dari GitLab privat, yaitu counterpart persis dari
`advance-mobile-platform` yang sudah dipakai Saldough. Nama paket dan versi
tag-nya identik: `failures-v2.0.2`, `state_management-v2.2.0`, `di-v1.1.2`,
dan seterusnya.

Pembacaan `lib/v2/` secara menyeluruh menunjukkan **bukti yang jauh lebih
kuat dan bertentangan langsung** dengan keputusan pertama:

- 104 kecocokan `Either<Failure` tersebar di 34 berkas.
- 0 (nol) kecocokan `throw.*Failure` atau `on Failure catch` di seluruh
  `lib/v2/`.
- `package:dependencies` (paket yang sudah jadi dependensi Saldough sejak
  ADR-0001, tapi belum benar-benar dipakai) ternyata berfungsi sebagai
  re-export `fpdart`:
  ```dart
  // advance-mobile-platform/shared/dependencies/lib/dependencies.dart
  export 'package:fpdart/fpdart.dart';
  ```
- Ada satu mixin bersama, `RepositoryGuard`, yang memusatkan pemetaan
  exception ke `Failure` supaya setiap implementasi repository tidak menulis
  `try`/`catch` sendiri-sendiri.

Singkatnya: `app_example` adalah contoh kecil yang tidak representatif.
Aplikasi produksi nyata yang memakai paket identik memilih `Either<Failure, T>`
secara konsisten dan tanpa pengecualian. Keputusan pertama ADR ini diambil
dari bukti yang terlalu tipis, dan sekarang dikoreksi.

## 3. Keputusan

Saldough memakai `Either<Failure, T>` dari fpdart, diimpor lewat
`package:dependencies`, sebagai satu-satunya cara repository dan use case
melaporkan kegagalan.

Repository dan use case mengembalikan `Future<Either<Failure, T>>`. Tidak ada
`throw Failure` di lapisan domain maupun data. Setiap implementasi repository
memakai mixin `RepositoryGuard` untuk memusatkan pemetaan exception mentah
(Hive, penguraian, dll.) menjadi `Failure` yang tepat, lewat `guard<T>()` atau
`guardVoid()`.

Bloc membaca hasilnya dengan pencocokan pola Dart 3:

```dart
switch (result) {
  case Left(value: final failure):
    emit(state.copyWith(effect: _effectError(failure)));
  case Right(value: final cycle):
    emit(state.copyWith(cycle: cycle, effect: _effectSaved()));
}
```

`Failure` sendiri tetap `sealed class` dari `package:failures` seperti
sebelumnya — yang berubah hanya cara ia disalurkan (dibungkus `Either`,
bukan dilempar).

## 4. Verbatim dari eksplorasi: `RepositoryGuard`

```dart
// lib/v2/core/fondation/repository_guard.dart
mixin RepositoryGuard {
  Future<Either<Failure, T>> guard<T>(Future<T> Function() run) async {
    try {
      return right(await run());
    } on FlowError catch (e) {
      return left(mapFlowError(e));
    } on DioException catch (e) {
      return left(mapDioError(e));
    } catch (e) {
      final custom = mapCustomError(e);
      if (custom != null) return left(custom);
      return left(SystemFailure(code: FailureCode.unknown, message: e.toString()));
    }
  }

  Future<Either<Failure, Unit>> guardVoid(Future<void> Function() run) =>
      guard(() async { await run(); return unit; });

  Failure? mapCustomError(Object error) => null; // hook — dioverride per fitur
}
```

Contoh pemakaian nyata (disederhanakan dari `AuthRepositoryImpl`):

```dart
final class AuthRepositoryImpl with RepositoryGuard implements AuthRepository {
  const AuthRepositoryImpl({required this._dataSource});
  final AuthDataSource _dataSource;

  @override
  Future<Either<Failure, User>> login({required String username, required String password}) =>
      guard(() => _dataSource.login(username: username, password: password));

  @override
  Failure? mapCustomError(Object error) =>
      error is AuthBusinessError ? _mapBusinessError(error.code) : null;
}
```

Untuk Saldough, `mapFlowError`/`mapDioError` tidak relevan (tidak ada jaringan
di MVP). Versi `RepositoryGuard` Saldough cukup menangani exception Hive dan
exception penguraian JSON:

```dart
mixin RepositoryGuard {
  Future<Either<Failure, T>> guard<T>(Future<T> Function() run) async {
    try {
      return right(await run());
    } on FormatException catch (e, st) {
      return left(SystemFailure(
        code: const FailureCode('PERSISTENCE_PARSE_ERROR'),
        message: e.message,
        details: FailureDetails(cause: e, stackTrace: st),
      ));
    } catch (e) {
      final custom = mapCustomError(e);
      if (custom != null) return left(custom);
      return left(PersistenceFailure(
        code: StorageFailureCode.keyNotFound,
        message: e.toString(),
      ));
    }
  }

  Future<Either<Failure, Unit>> guardVoid(Future<void> Function() run) =>
      guard(() async { await run(); return unit; });

  Failure? mapCustomError(Object error) => null;
}
```

## 5. Opsi yang dipertimbangkan

- **Opsi A — `throw Failure` / `on Failure catch`** *(dipilih di versi
  pertama ADR ini, sekarang ditolak)*
- **Opsi B — `Either<Failure, T>` via fpdart, dengan `RepositoryGuard`**
  *(dipilih)*
- **Opsi C — mengembalikan `T?` dengan null sebagai penanda gagal**

## 6. Analisis konsekuensi

### Opsi A — `throw Failure` / `on Failure catch` (ditolak)

Alasan ditolak bukan lagi soal desain paket `failures` itu sendiri (yang
memang dirancang agar bisa dipakai dengan cara apa pun), melainkan soal
**konsistensi dengan referensi arsitektur yang diminta pemilik**. Aplikasi
produksi yang memakai paket identik memilih `Either` secara eksklusif. Menulis
Saldough dengan throw/catch berarti menyimpang dari konvensi nyata yang justru
ingin ditiru, dan menyulitkan siapa pun yang membandingkan kode Saldough
dengan repo acuannya.

### Opsi B — `Either<Failure, T>` via fpdart, dengan `RepositoryGuard`
(Dipilih)

Cocok persis dengan konvensi produksi yang divalidasi. Kompilator memaksa
pemanggil menangani kedua cabang `Either` (lewat `switch` yang diperiksa
kelengkapannya), sehingga kegagalan yang lupa ditangani ketahuan saat
kompilasi — kebalikan dari kelemahan Opsi A. `RepositoryGuard` menghapus
kebutuhan menulis `try`/`catch` berulang di setiap implementasi repository.

Kelemahannya: satu lapisan abstraksi tambahan (`Either`) yang harus dipahami
pengembang yang belum biasa dengan pemrograman fungsional, dan pencocokan
pola `Left`/`Right` sedikit lebih verbose daripada `try`/`catch` biasa untuk
kasus yang sangat sederhana. Diterima, karena keuntungan konsistensi dan
keamanan kompilasi lebih besar.

### Opsi C — mengembalikan `T?` dengan null sebagai penanda gagal

Tidak dipertimbangkan ulang — tetap ditolak dengan alasan yang sama seperti
versi pertama ADR ini: membuang seluruh informasi penyebab kegagalan.

## 7. Konsekuensi

### Yang menjadi lebih mudah

- Kode Saldough bisa dibandingkan langsung dengan repo acuan arsitektur.
- Kompilator memeriksa kelengkapan penanganan kegagalan lewat `switch`
  menyeluruh pada `Either`.
- `RepositoryGuard` menghapus duplikasi `try`/`catch` di setiap repository.

### Yang menjadi lebih sulit

- Pengembang yang belum biasa `Either` butuh waktu adaptasi.
- Setiap pemanggilan repository perlu membongkar `Either`, sedikit lebih
  verbose daripada akses langsung.

### Risiko yang diterima

- Seluruh kode yang mungkin sudah ditulis mengikuti versi pertama ADR ini
  (throw/catch) harus ditulis ulang. Pada titik revisi ini belum ada kode
  Flutter sama sekali, jadi dampaknya nol — ini sebabnya koreksi dilakukan
  sekarang, sebelum implementasi dimulai.

## 8. Catatan implementasi

### Batasan yang harus dijaga

- Repository dan use case mengembalikan `Future<Either<Failure, T>>`, tidak
  pernah `Future<T>` polos dan tidak pernah melempar `Failure`.
- Setiap implementasi repository memakai `with RepositoryGuard` dan
  memanggil `guard()`/`guardVoid()`, bukan `try`/`catch` manual.
- Bloc membongkar `Either` dengan `switch` pada `Left`/`Right`, tidak dengan
  `result.fold(...)` kecuali untuk kasus transformasi satu baris yang lebih
  ringkas ditulis begitu.
- Impor `Either`/`left`/`right`/`unit` dari `package:dependencies`, bukan
  langsung dari `package:fpdart`.

### Antipola yang harus dihindari

- Mencampur `throw Failure` dan `Either<Failure, T>` dalam satu repository.
- Memanggil `.getLeft()`/`.getRight()` lalu memeriksa null secara manual —
  pakai `switch` atau `.fold()`.
- Menulis `try`/`catch` manual di repository tanpa `RepositoryGuard`.

## 9. Kriteria peninjauan ulang

- Referensi arsitektur berganti lagi dan referensi barunya memakai konvensi
  berbeda.
- Tim menilai `Either` menambah beban kognitif yang tidak sepadan untuk
  domain Saldough yang jauh lebih kecil daripada aplikasi bank.

## 10. Artefak terkait

### Dokumentasi

- [ARCHITECTURE_OVERVIEW.md](../ARCHITECTURE_OVERVIEW.md) bagian lapisan dan
  contoh "Menulis satu fitur".
- [ADR-0009](0009-core-shared-features-zone-layout.md) untuk struktur folder
  yang divalidasi bersamaan dengan temuan ini.
- [ADR-0003](0003-effect-bloc-state-management.md) untuk penanganan di bloc.

### Rujukan kode

- `flutter-architecture-studi-bank` (`lib/v2/core/fondation/repository_guard.dart`,
  `lib/v2/features/auth/landing/data/repositories/auth_repository_impl.dart`)
- `advance-mobile-platform/core/failures/lib/`
- `advance-mobile-platform/shared/dependencies/lib/dependencies.dart`

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-09, direvisi 2026-09-10
**Status implementasi:** Disetujui, belum diimplementasikan
