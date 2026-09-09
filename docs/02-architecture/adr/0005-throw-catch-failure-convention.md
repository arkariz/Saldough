# Konvensi kesalahan: lempar dan tangkap, bukan Either

## 1. Metadata

- **Decision ID:** ADR-005
- **Tanggal:** 2026-09-09
- **Fase roadmap:** Fase 1
- **Status:** Accepted
- **Cakupan:** Global

## 2. Konteks

Dua sumber acuan Saldough menangani kesalahan dengan cara yang bertentangan, dan
perbedaannya tidak bisa dijembatani tanpa memilih salah satu.

Repositori referensi arsitektur, `new-health-duel`, mewajibkan setiap metode
repository mengembalikan `Either<Failure, T>` memakai `dartz`. Aturan itu
tertulis tegas di `AGENT_CONTEXT.md` proyek tersebut.

Paket internal `failures` versi 2.0.2, yang diminta pemilik, dirancang untuk
pendekatan sebaliknya. `Failure` adalah `sealed class` yang **bukan** turunan
`Exception`, dan seluruh kode di monorepo melemparnya dengan `throw` lalu
menangkapnya dengan `on Failure catch`. Bukti desainnya terlihat dari komentar
`// ignore_for_file: only_throw_errors` yang muncul di kode pelempar, dan dari
ketiadaan `Either` di seluruh lapisan monorepo meski `fpdart` tersedia lewat
`package:dependencies`.

Memakai `Either` di atas paket ini berarti membungkus setiap panggilan dengan
`try`-`catch` lalu menerjemahkannya menjadi `Left`, yaitu menambah lapisan untuk
membatalkan desain paketnya sendiri.

Konteks Saldough juga berbeda dari `new-health-duel`. MVP tidak punya jaringan.
Sumber kegagalan hanya dua: kesalahan penyimpanan, dan pelanggaran aturan bisnis
seperti alokasi persentase yang tidak genap 100. Keduanya jarang dan tidak
berada di jalur eksekusi utama.

## 3. Keputusan

Saldough memakai konvensi lempar dan tangkap dari `package:failures`.

Repository dan use case mengembalikan tipe hasilnya secara langsung. Kegagalan
dilempar sebagai turunan `Failure`. Bloc menangkapnya dengan
`on Failure catch (failure)` lalu memancarkan state gagal atau efek yang sesuai.

`dartz` dan `fpdart` tidak dipakai. Tidak ada `Either` di mana pun.

Lapisan data bertanggung jawab menerjemahkan kesalahan mentah menjadi `Failure`
yang bermakna. Kesalahan Hive menjadi `PersistenceFailure`, pelanggaran aturan
domain menjadi `BusinessRuleFailure` atau `ValidationFailure`.

Antarmuka memilih tampilan lewat `switch` menyeluruh pada tipe tersegel:

```dart
final view = switch (failure) {
  PersistenceFailure() => const StorageErrorView(),
  ValidationFailure(:final fieldErrors) => FormErrorView(fieldErrors),
  BusinessRuleFailure() => RuleViolationView(failure.userMessage),
  _ => GenericErrorView(failure.userMessage),
};
```

## 4. Opsi yang dipertimbangkan

- **Opsi A — `Either<Failure, T>` dengan `dartz`, seperti `new-health-duel`**
- **Opsi B — Lempar dan tangkap `Failure`, sesuai desain paket (Dipilih)**
- **Opsi C — Mengembalikan `T?` dengan null sebagai penanda gagal**

## 5. Analisis konsekuensi

### Opsi A — `Either<Failure, T>` dengan `dartz`

Kegagalan menjadi bagian tanda tangan fungsi, sehingga pemanggil tidak bisa
lupa menanganinya. Ini keunggulan nyata, dan alasan `new-health-duel`
memakainya.

Namun `package:failures` tidak dirancang untuk ini. Setiap pemanggilan harus
dibungkus `try`-`catch` yang menangkap `Failure` lalu mengubahnya menjadi
`Left`, hanya untuk kemudian dibuka lagi dengan `fold`. Lapisan itu tidak
menambah keamanan apa pun yang tidak sudah diberikan `sealed class`, karena
`switch` pada tipe tersegel juga diperiksa kelengkapannya oleh kompilator.

Opsi ini juga menambah dependensi `dartz` yang tidak dipakai monorepo, sehingga
kode Saldough menyimpang dari kode paket yang dipanggilnya.

### Opsi B — Lempar dan tangkap `Failure` (Dipilih)

Sesuai desain paket, sehingga tidak ada lapisan penerjemah. Jalur sukses tetap
bersih dan mudah dibaca, yang penting karena logika domain Saldough berisi
banyak perhitungan berantai: total jam menjadi gaji kotor, menjadi gaji bersih,
menjadi baris pemasukan, menjadi total, menjadi sisa. Membungkus tiap langkah
dengan `Either` akan mengubur rumusnya di balik `fold`.

Kelengkapan penanganan tetap terjaga lewat `switch` menyeluruh pada `Failure`
yang tersegel.

Kelemahannya jelas dan diterima: kompilator tidak memaksa pemanggil menangani
kegagalan. Kalau bloc lupa menangkap, kesalahan lolos ke `AppBlocObserver`.
Risiko ini kecil pada Saldough karena titik kegagalannya sedikit dan
terkonsentrasi di lapisan data.

Satu hal yang mudah luput: karena `Failure` bukan turunan `Exception`,
`on Exception catch` **tidak** akan menangkapnya. Penangkapan harus memakai
`on Failure catch`.

### Opsi C — Mengembalikan `T?` dengan null sebagai penanda gagal

Paling sederhana, tetapi membuang seluruh informasi penyebab kegagalan. Tidak
bisa membedakan penyimpanan gagal dari data memang belum ada. Tidak memadai.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Jalur sukses tetap terbaca, penting untuk rantai perhitungan domain.
- Tidak ada penerjemahan antara desain paket dan gaya kode aplikasi.
- Tidak ada dependensi pemrograman fungsional tambahan.

### Yang menjadi lebih sulit

- Kompilator tidak mengingatkan kalau kegagalan tidak ditangani.
- Pengembang yang terbiasa `new-health-duel` harus menyesuaikan kebiasaan.

### Risiko yang diterima

- Kegagalan yang tidak tertangkap lolos ke pengamat bloc. Ditangani dengan
  aturan bahwa setiap penangan event bloc yang memanggil repository wajib punya
  `on Failure catch`, dan hal ini diperiksa saat tinjauan kode.
- `on Exception catch` diam-diam tidak menangkap `Failure`. Ditangani dengan
  larangan tegas memakainya untuk kegagalan domain.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- Repository dan use case mengembalikan `Future<T>`, bukan
  `Future<Either<Failure, T>>`.
- Setiap penangan event bloc yang menyentuh repository memiliki
  `on Failure catch (failure)`.
- Lapisan data menerjemahkan kesalahan mentah menjadi subtipe `Failure` yang
  tepat. Kesalahan Hive tidak boleh bocor ke domain.
- Pesan untuk pengguna diambil dari `failure.userMessage`. Field `message`
  ditujukan untuk pengembang dan tidak pernah ditampilkan.

### Subtipe yang relevan untuk Saldough

| Subtipe | Dipakai untuk |
|---|---|
| `PersistenceFailure` | Gagal membaca atau menulis penyimpanan |
| `ValidationFailure` | Masukan formulir tidak sah, memakai `fieldErrors` |
| `BusinessRuleFailure` | Pelanggaran invarian domain, misalnya alokasi bukan 100 |
| `SystemFailure` | Kesalahan tak terduga, termasuk kegagalan penguraian |

Subtipe `NetworkFailure`, `ServerFailure`, `AuthenticationFailure`,
`AuthorizationFailure`, dan `SecurityFailure` tersedia tetapi belum relevan
sebelum tahap sinkronisasi.

### Antipola yang harus dihindari

- Memakai `Either`, `dartz`, atau `fpdart`.
- Memakai `on Exception catch` untuk menangkap `Failure`.
- Menangkap `Failure` di lapisan data hanya untuk melemparnya kembali tanpa
  menambah konteks.
- Menampilkan `failure.message` kepada pengguna.

## 8. Kriteria peninjauan ulang

- Kegagalan yang tidak tertangkap mulai muncul berulang di log.
- Tahap sinkronisasi memperbanyak titik kegagalan jaringan secara signifikan,
  sehingga penanganan eksplisit di tanda tangan fungsi menjadi lebih berharga.
- Paket `failures` mengubah desainnya menjadi berbasis hasil.

## 9. Artefak terkait

### Dokumentasi

- [ARCHITECTURE_OVERVIEW.md](../ARCHITECTURE_OVERVIEW.md) bagian lapisan.
- [ADR-0003](0003-effect-bloc-state-management.md) untuk penanganan di bloc.
- [DOMAIN_MODEL.md](../DOMAIN_MODEL.md) bagian invarian, yang menjadi sumber
  `BusinessRuleFailure`.

### Rujukan kode

- `advance-mobile-platform/core/failures/lib/`
- `advance-mobile-platform/app_example/lib/features/auth/presentation/bloc/auth_bloc.dart`

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-09
**Status implementasi:** Disetujui, belum diimplementasikan
