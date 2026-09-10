# Konvensi pengujian: `mocktail` dan `bloc_test`

## 1. Metadata

- **Decision ID:** ADR-010
- **Tanggal:** 2026-09-10, direvisi 2026-09-10
- **Fase roadmap:** Fase 1
- **Status:** Accepted (revisi)
- **Cakupan:** Global

> **Catatan revisi (2026-09-10):** Versi pertama ADR ini memilih fake tulis
> tangan tanpa pustaka mocking, mengikuti persis konvensi produksi
> `flutter-architecture-studi-bank`. Pemilik secara eksplisit meminta
> `mocktail` dan `bloc_test` dipakai sebagai gantinya. Keputusan ini dibalik
> atas permintaan langsung, bukan atas temuan teknis baru — dicatat di
> bagian 2 dan 5.

## 2. Konteks

Versi pertama ADR ini (10 September 2026) memilih fake tulis tangan
berdasarkan pembacaan `pubspec.yaml` dan berkas uji `flutter-architecture-studi-bank`
(`lib/v2/`), yang memang tidak memakai `mocktail` maupun `bloc_test` di mana
pun — seluruh pengujian bloc dan domain di sana memakai kelas `_FakeXyz
implements Interface` tulis tangan.

Pemilik kemudian meminta konvensi itu diganti: Saldough memakai `mocktail`
dan `bloc_test`. Ini bukan koreksi atas temuan yang salah seperti pembalikan
[ADR-0005](0005-either-failure-convention.md) — bukti dari repo acuan tetap
berdiri, hanya tidak diikuti untuk urusan pengujian. Alasan pemilik tidak
diuraikan di sini; ADR ini mencatat keputusannya dan konsekuensinya.

## 3. Keputusan

Saldough memakai `mocktail` untuk membuat mock/stub dan `bloc_test` untuk
menguji bloc. Kedua paket ini **ditambahkan kembali** ke `dev_dependencies`.

Mock dibuat dengan `class MockXyz extends Mock implements Interface {}`.
Nilai fallback untuk tipe non-primitif didaftarkan lewat
`registerFallbackValue(...)` di `setUpAll`. Bloc diuji dengan `blocTest(...)`,
bukan memanggil `bloc.add()`/`bloc.stream` secara manual.

## 4. Pola yang dipakai

Mock untuk repository:

```dart
class MockCycleRepository extends Mock implements CycleRepository {}

void main() {
  late MockCycleRepository repository;

  setUpAll(() {
    registerFallbackValue(MonthlyCycle.empty('2026-09'));
  });

  setUp(() {
    repository = MockCycleRepository();
  });

  group('CycleBloc', () {
    blocTest<CycleBloc, CycleState>(
      'sign-in gagal menampilkan pesan dan tetap idle',
      build: () {
        when(() => repository.getCycle(any()))
            .thenAnswer((_) async => left(const SystemFailure(
                  code: FailureCode.unknown,
                  message: 'boom',
                )));
        return CycleBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const CycleRollOverRequested(fromCycleId: '2026-08')),
      expect: () => [
        isA<CycleState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CycleState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.effect, 'effect', isA<ShowSnackBarEffect>()),
      ],
    );
  });
}
```

Use case domain diuji dengan mock yang sama, tanpa `blocTest`:

```dart
class MockGoalRepository extends Mock implements GoalRepository {}

void main() {
  late MockGoalRepository goalRepository;

  setUp(() {
    goalRepository = MockGoalRepository();
  });

  test('menghitung saldo pos dari alokasi dan pinjaman', () async {
    when(() => goalRepository.getGoal(any()))
        .thenAnswer((_) async => right(Goal(id: 'kyoto', name: 'KYOTO', openingBalance: 0)));

    final balance = await CalculateGoalBalance(goalRepository)('kyoto');

    expect(balance, right(1697828));
  });
}
```

## 5. Opsi yang dipertimbangkan

- **Opsi A — Fake tulis tangan, tanpa pustaka mocking** *(dipilih di versi
  pertama ADR ini, sekarang ditolak atas permintaan pemilik)*
- **Opsi B — `mocktail` + `bloc_test` (Dipilih)**

## 6. Analisis konsekuensi

### Opsi A — Fake tulis tangan (ditolak)

Cocok persis dengan konvensi produksi `flutter-architecture-studi-bank` dan
tanpa dependensi mocking. Argumen ini tetap berlaku secara teknis — ditolak
bukan karena argumennya salah, melainkan karena pemilik memilih sebaliknya.

### Opsi B — `mocktail` + `bloc_test` (Dipilih)

Lebih dikenal luas di ekosistem Flutter/BLoC, sehingga dokumentasi, contoh,
dan bantuan komunitas lebih mudah ditemukan. `blocTest(...)` memangkas
boilerplate seputar `addTearDown(bloc.close)` dan perbandingan urutan state,
dan `when(...).thenAnswer(...)` tidak menuntut setiap mock
mengimplementasikan seluruh interface seperti fake tulis tangan.

Kelemahannya: menyimpang dari konvensi produksi yang diverifikasi di
`flutter-architecture-studi-bank`, dan menambah dua dependensi yang terbukti
tidak diperlukan pada skala interface Saldough yang kecil. Kedua kelemahan
ini diterima karena datang dari permintaan eksplisit pemilik, bukan dari
kesalahan analisis.

## 7. Konsekuensi

### Yang menjadi lebih mudah

- Pengembang yang sudah biasa `mocktail`/`bloc_test` langsung produktif.
- `blocTest(...)` memangkas boilerplate pengaturan dan teardown bloc.
- Dokumentasi dan contoh pihak ketiga banyak tersedia.

### Yang menjadi lebih sulit

- Kode uji Saldough tidak lagi bisa dibandingkan langsung dengan pola repo
  acuan arsitektur.
- Setiap tipe non-primitif yang dipakai sebagai argumen matcher (`any()`)
  perlu fallback value terdaftar di `setUpAll`, yang mudah terlupa dan
  baru ketahuan saat runtime test gagal dengan pesan yang tidak jelas.

### Risiko yang diterima

- Dua dependensi tambahan (`mocktail`, `bloc_test`) di `dev_dependencies`
  yang tidak dipakai aplikasi produksi acuan. Diterima atas permintaan
  pemilik.

## 8. Catatan implementasi

### Batasan yang harus dijaga

- Mock dideklarasikan `class MockXyz extends Mock implements Interface {}`,
  satu per interface, bisa dipakai ulang lintas berkas uji lewat
  `test/helpers/mocks.dart` kalau dipakai ≥3 berkas.
- Setiap nilai non-primitif yang dipakai dengan `any()` pada argumen mock
  didaftarkan lewat `registerFallbackValue(...)` di `setUpAll`.
- Uji bloc memakai `blocTest<Bloc, State>(...)`, bukan memanggil
  `bloc.add()`/`bloc.stream` secara manual.
- `when(...).thenAnswer(...)` dipakai untuk stub asinkron; `when(...).thenReturn(...)`
  untuk stub sinkron.

### Antipola yang harus dihindari

- Mencampur fake tulis tangan dan `mocktail` untuk interface yang sama.
- Memanggil metode mock tanpa `when(...)` lebih dulu — `mocktail` melempar
  `MissingStubError` dan itu gejala yang benar, bukan bug yang harus
  ditutupi dengan fallback diam-diam.

## 9. Kriteria peninjauan ulang

- Jumlah interface atau kerumitan stub tumbuh sampai `mocktail` terasa lebih
  menyulitkan daripada fake tulis tangan.
- Pemilik meminta kembali ke konvensi fake tulis tangan yang selaras dengan
  repo acuan.

## 10. Artefak terkait

### Dokumentasi

- [ARCHITECTURE_OVERVIEW.md](../ARCHITECTURE_OVERVIEW.md) bagian pengujian.
- [ADR-0009](0009-core-shared-features-zone-layout.md) untuk konteks
  referensi arsitektur yang tidak diikuti di sini.

### Rujukan kode

- Tidak ada — ini keputusan yang menyimpang dari repo acuan, bukan menyalin
  polanya.

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-10
**Status implementasi:** Disetujui, belum diimplementasikan
