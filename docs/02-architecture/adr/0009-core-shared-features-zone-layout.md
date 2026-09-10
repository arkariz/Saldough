# Struktur folder: zona core / shared / features

## 1. Metadata

- **Decision ID:** ADR-009
- **Tanggal:** 2026-09-10
- **Fase roadmap:** Fase 1
- **Status:** Accepted
- **Cakupan:** Global

## 2. Konteks

ARCHITECTURE_OVERVIEW.md versi pertama menyusun struktur folder Saldough
sebagai feature-first sederhana: setiap fitur punya `data/`, `domain/`,
`presentation/` sendiri, diambil dari asumsi terhadap `new-health-duel`.
Struktur itu tidak salah, tapi tidak punya jawaban untuk satu pertanyaan yang
pasti muncul begitu ada dua fitur yang butuh entitas atau repository yang
sama: di mana kode itu tinggal?

Pemilik mengarahkan referensi arsitektur ke
`arkariz/flutter-architecture-studi-bank` (branch `refactor/platform-migration`,
folder `lib/v2`), aplikasi produksi yang sudah menjawab pertanyaan itu lewat
dua ADR internalnya sendiri (diberi nomor berbeda dari ADR Saldough — disebut
sebagai "ADR-002" dan "ADR-006" milik repo itu untuk membedakan dari ADR
Saldough):

- **ADR-002 mereka** ("Domain Layer Placement Strategy"): entitas dan
  interface repository tinggal bersama fitur pemiliknya secara default.
  `core/` tidak boleh berisi entitas bisnis sama sekali — ia murni
  infrastruktur (pemetaan kesalahan, kelas dasar, ekstensi generik). Promosi
  ke lapisan bersama terjadi saat sebuah entitas dipakai 3 atau lebih fitur.
- **ADR-006 mereka** ("Shared Module Structure"): memperbaiki *tata letak
  fisik* dari lapisan bersama itu. Semula `shared/domain/**` dan
  `shared/data/**` disusun layer-first (menyatukan semua domain lintas
  modul dalam satu folder, semua data lintas modul di folder lain) — ini
  menyulitkan melihat satu kapabilitas sebagai satu kesatuan dan mempersulit
  penghapusan atau ekstraksi modul itu jadi paket terpisah. Solusinya:
  module-first — `shared/<module>/{domain,data}/` di balik satu barrel,
  ambang promosi diturunkan ke 2+ konsumen untuk kapabilitas yang memang
  berdiri sendiri.

Hasilnya adalah tiga zona yang tidak saling tumpang tindih:

```
lib/v2/
├── core/        — infrastruktur lintas fitur, TANPA makna bisnis
├── shared/<module>/   — kapabilitas bisnis dipakai ≥2 fitur, module-first
└── features/<feature>/  — graf milik satu fitur
```

Struktur ini tervalidasi sebagai kode produksi nyata, bukan contoh kecil, dan
menjawab persis pertanyaan yang belum terjawab di ARCHITECTURE_OVERVIEW.md
versi pertama.

## 3. Keputusan

Saldough memakai tiga zona yang sama: `core/`, `shared/<module>/`,
`features/<feature>/`.

**`core/`** — infrastruktur lintas fitur tanpa makna bisnis: DI, navigasi,
effect handler, tema, pemformat uang/tanggal, i18n, widget bersama
(`AppCard`, `AppButton`, dst.), dan `RepositoryGuard`. Kalau sebuah berkas
mengenkode konsep keuangan (siklus, pos tujuan, transaksi), berkas itu bukan
milik `core/`.

**`shared/<module>/`** — satu kapabilitas bisnis mandiri yang dipakai ≥2
fitur, disusun module-first: `domain/` + `data/` di balik satu barrel
`<module>.dart`. **Tanpa `presentation/`**, kecuali kasus yang benar-benar
perlu UI dipakai ulang lintas fitur — dan kalaupun itu terjadi, harus dicatat
eksplisit sebagai pengecualian terdokumentasi, bukan dianggap pola kedua yang
setara.

Satu-satunya `shared/<module>/` yang sudah teridentifikasi untuk MVP Saldough:

```
lib/shared/goal/
├── goal.dart                      # barrel
├── domain/
│   ├── goal.dart                  # entitas Goal
│   └── goal_repository.dart       # abstract interface class
└── data/
    ├── goal_model.dart            # serialisasi
    └── goal_repository_impl.dart
```

`Goal` dipakai oleh fitur `investment` (alokasi persentase) dan oleh
pencatatan pinjaman antar pos (`GoalLoan`, juga bagian dari fitur
`investment` — lihat ADR-0008). Karena dua kebutuhan itu berasal dari fitur
yang sama, `Goal` sebenarnya baru menyentuh ambang 1 fitur hari ini; ia naik
ke `shared/` lebih awal dari ambang "2+ konsumer" karena desainnya memang
dipikirkan sebagai registry terbuka yang wajar dipakai fitur lain nanti
(misalnya kalau Fase 7 menambah fitur laporan yang membaca saldo pos). Ini
satu-satunya pengecualian yang disengaja terhadap aturan "jangan promosikan
spekulatif" — dicatat di sini supaya tidak jadi kebiasaan.

**`features/<feature>/`** — graf milik satu fitur: `domain/` dan `data/`
privat (tidak diimpor fitur lain), `presentation/{bloc,navigation,pages,widgets}`,
dan `di/<feature>_scope.dart` sendiri. Tujuh fitur MVP:
`cycle`, `income`, `worklog`, `grocery`, `card`, `investment`, `seed`.

### Aturan penempatan domain

Entitas dan interface repository tinggal di fitur pemiliknya secara default.
Naik ke `shared/<module>/domain/` hanya saat dipakai ≥2 fitur (kecuali
pengecualian `Goal` di atas). `core/` tidak pernah berisi entitas bisnis.

### Pola DI (ringkas dari decision tree repo acuan)

| Yang didaftarkan | Pola |
|---|---|
| Bloc screen-local, tanpa dependensi repository | `BlocProvider.create()` di level rute |
| Singleton app-wide, kelas sendiri, constructor sinkron | `@LazySingleton(as: Interface)` langsung — default |
| Tipe pihak ketiga / async / `@Named` | Factory method di kelas `@module` |
| Graf milik satu fitur, dependensi induk perlu dibatasi, atau ada urutan async | `IsolatedScope` di `features/<fitur>/di/<fitur>_scope.dart` |

Heuristik satu baris: **`shared/` → root injectable · `features/` → scope ·
bloc screen-local → route provider.**

`IsolatedScope` punya tiga hook berurutan dan mengikat:
`bridge()` (whitelist dependensi induk satu per satu, jangan teruskan
seluruhnya) → `register()` (wiring lokal dari dependensi yang sudah di-bridge)
→ `afterInit()` (urutan async seperti `allReady()` atau migrasi skema — tidak
pernah mendaftar dependensi baru).

### Yang TIDAK disalin

Repo acuan sedang migrasi dari GetX legacy ke stack ini (pola *Strangler
Fig*). Bagian berikut spesifik untuk migrasi mereka dan tidak relevan untuk
Saldough yang greenfield — **tidak disalin dalam bentuk apa pun**:

- `ArchitectureBride*` (jembatan boot dari legacy GetX ke shell v2).
- Seam `Get.find()`/`Get.put()` dan `getx_nav_effect_handler`.
- `StartupDestination` varian legacy, dan ADR mereka soal strangler fig.
- `mobile_dsl` (design system privat mereka) — theming Saldough tetap dari
  `new-health-duel`, lihat [ADR-0006](0006-design-token-semantic-color-mapping.md).

Boot Saldough tetap `main()` → `runApp()` langsung seperti sudah ditulis di
ARCHITECTURE_OVERVIEW.md. Yang dipertahankan dari repo acuan hanyalah
**urutannya**: pasang `Bloc.observer` → jalankan `di.run()` → daftarkan
effect handler → render router → jalankan `di.warmUp()` setelah frame
pertama.

Repo acuan juga konsisten memakai dua ejaan tidak baku (`fondation`,
`architecture_bride`). Saldough memakai ejaan baku: `foundation/`, dan tidak
perlu nama khusus untuk "jembatan" karena tidak ada legacy untuk dijembatani.

## 4. Opsi yang dipertimbangkan

- **Opsi A — feature-first 3 lapis tanpa zona bersama** *(rencana awal,
  sekarang diperkaya)*
- **Opsi B — tiga zona core/shared/features, module-first (Dipilih)**
- **Opsi C — layer-first (`shared/domain/**`, `shared/data/**`)**

## 5. Analisis konsekuensi

### Opsi A — feature-first 3 lapis tanpa zona bersama

Sederhana untuk fitur yang berdiri sendiri, dan itulah sebabnya dipilih di
rencana awal. Tapi begitu `Goal` dibutuhkan fitur investment, tidak ada
tempat yang jelas untuk entitas itu tinggal selain menumpuknya di satu fitur
dan fitur lain mengimpor langsung lintas fitur — persis duplikasi/ketergantungan
liar yang ADR-002 milik repo acuan dirancang untuk mencegah.

### Opsi B — tiga zona core/shared/features, module-first (Dipilih)

Menjawab langsung pertanyaan yang belum terjawab di Opsi A, dengan aturan
promosi yang jelas (2+ konsumen) dan bentuk fisik yang sudah diuji tidak
menyulitkan ekstraksi modul (module-first, bukan layer-first). Tervalidasi
sebagai kode produksi, bukan sekadar ide.

Kelemahannya: satu tingkat keputusan tambahan setiap kali menulis kode baru
("ini milik fitur, atau sudah waktunya naik ke shared?"). Diterima, karena
keputusan itu justru yang mencegah duplikasi diam-diam.

### Opsi C — layer-first (`shared/domain/**`, `shared/data/**`)

Ini yang ditolak ADR-006 milik repo acuan sendiri, dengan bukti konkret:
modul `session/` mereka yang paling matang harus dipecah-pecah untuk "patuh"
ke layout ini, padahal secara alami sudah tersusun module-first. Alasan
penolakan itu berlaku sama persis untuk Saldough, jadi tidak dipertimbangkan
ulang secara independen — diwariskan langsung dari bukti mereka.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Tempat sebuah entitas/interface tinggal punya aturan jelas (fitur vs
  shared vs core), tidak lagi soal selera.
- Modul `shared/<module>/` bisa dibaca, diuji, atau diekstrak jadi paket
  terpisah sebagai satu kesatuan.
- Pola DI punya aturan eksplisit, mengurangi perdebatan "GetIt langsung atau
  scope?" di setiap fitur baru.

### Yang menjadi lebih sulit

- Ada satu keputusan tambahan (promosi ke shared) yang harus dijaga
  konsisten lewat tinjauan kode, bukan alat otomatis.
- Pengecualian `Goal` (promosi lebih awal dari ambang 2+ konsumen) harus
  diingat agar tidak jadi alasan mempromosikan segala sesuatu secara
  spekulatif.

### Risiko yang diterima

- Tim bisa terlalu cepat mempromosikan sesuatu ke `shared/` "untuk
  jaga-jaga." Ditangani dengan aturan tegas: promosi hanya saat ada
  konsumer kedua yang nyata, kecuali `Goal` yang sudah dicatat sebagai
  pengecualian sadar.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- `core/` tidak pernah mengimpor entitas domain milik fitur atau shared.
- Satu-satunya cara mengimpor `shared/<module>/` adalah lewat barrelnya
  (`package:saldough/shared/goal/goal.dart`), tidak pernah lewat jalur
  berkas di dalamnya.
- `shared/<module>/` tidak punya `presentation/` kecuali dicatat eksplisit
  sebagai pengecualian di ADR ini.
- `IsolatedScope.bridge()` mendaftarkan dependensi induk satu per satu
  (`c.registerSingleton<Dio>(parent<Dio>())`), tidak pernah meneruskan
  `parent` secara utuh.

### Antipola yang harus dihindari

- Membuat `shared/<module>/` kosong sebagai persiapan sebelum ada konsumer
  kedua yang nyata.
- Meletakkan entitas bisnis di `core/`.
- Menyalin `ArchitectureBride`, seam `Get.find()`, atau `mobile_dsl` dari
  repo acuan.

## 8. Kriteria peninjauan ulang

- Muncul `shared/<module>/` ketiga atau keempat — saat itu, tinjau ulang
  apakah pengecualian `Goal` (promosi dini) masih satu-satunya, atau sudah
  jadi kebiasaan yang perlu diperbaiki.
- Tahap sinkronisasi (Fase 7) menambah kebutuhan shared module baru untuk
  sesi/autentikasi — pola `shared/session/` milik repo acuan jadi relevan
  untuk ditiru saat itu.

## 9. Artefak terkait

### Dokumentasi

- [ARCHITECTURE_OVERVIEW.md](../ARCHITECTURE_OVERVIEW.md) bagian struktur
  folder dan cara memilih pola DI.
- [ADR-0005](0005-either-failure-convention.md) — divalidasi dari eksplorasi
  yang sama.
- [ADR-0008](0008-monthly-cycle-template-and-rollup.md) untuk `GoalLoan`.

### Rujukan kode

- `flutter-architecture-studi-bank`, `lib/v2/core/`, `lib/v2/shared/session/`,
  `lib/v2/features/auth/landing/`, `.docs/architecture/ADR-002-*.md`,
  `.docs/architecture/ADR-006-*.md`, `.docs/architecture/ADR-007-*.md`.

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-10
**Status implementasi:** Disetujui, belum diimplementasikan
