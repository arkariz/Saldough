# Monetisasi: hak Plus, uji coba terbalik, dan gerbang fitur

## 1. Metadata

- **Decision ID:** ADR-041
- **Tanggal:** 2026-10-23
- **Fase roadmap:** Plus tahap B (B-41, "Fondasi Plus")
- **Status:** Accepted (pemilik, 2026-10-23: uji coba wajib masuk akun dan
  pengganti paket untuk uji/pengembangan/tinjauan toko atas masukan pemilik;
  P-8, P-9, P-11 disetujui eksplisit, rekomendasi lain di §3.11 berlaku).
  **Revisi 2 (2026-10-23, T-24.1):** hasil pemeriksaan kode dan keputusan
  pemilik atasnya di §3.13; aturan pra-peluncuran, batas proyek, sumber
  notifikasi, dan penundaan gerbang Rencana menggantikan teks yang
  bertentangan di bagian lain.
- **Cakupan:** Modul baru `core/foundation/entitlement/`, fitur baru
  `features/premium/` (+ adaptor RevenueCat), glue akar komposisi
  (`lib/app/premium/`, `lib/app/di/root_module.dart`), gerbang di fitur yang
  sudah ada (`notification_capture`, `recurring`, `analysis`, `budget`,
  `freelance`, `plan`, `shared/capture`), empat kunci penyimpanan baru yang
  didaftarkan ke `BackupRegistry` (ADR-040)

## 2. Konteks

[FREEMIUM_PAYWALL.md](../../01-product/features/FREEMIUM_PAYWALL.md) (§8, §9,
§10, §12, §15, §16) dan laporan bisnis pemilik
[Tanukonomy Plus: Rencana Bisnis dan Spesifikasi Kerja Paywall](https://claude.ai/artifact/SKsV87e4f7hX8h58Qvv7G5)
menetapkan *apa* yang gratis dan *apa* yang Plus, harga, panjang uji coba, dan
aturan keras (pencatatan manual tidak pernah digerbang; turun ke Gratis tidak
mengunci data; Plus yang luring tetap Plus). KT-P1–P18 sudah diputuskan pemilik
(18 dan 23 Okt 2026). Dokumen itu menyerahkan lima hal teknis ke ADR ini:
struktur kode, penyimpanan dan keadaan hak, perhitungan tanggal berakhir uji
coba, gerbang R3, dan pengelolaan offering/ID pengguna RevenueCat (KT-P6).

Keadaan kode yang relevan (diperiksa 23 Okt 2026 di `origin/main`, setelah
Fase 22):

- **Belum ada billing, hak, atau kuota apa pun.** `pubspec.yaml` tidak memuat
  `purchases_flutter`. Satu-satunya "gerbang" yang ada ialah status fitur
  `FeatureStatuses` (`core/discovery/`), yang menjawab *apakah izin sistem ada*,
  bukan *apakah pengguna berhak*.
- **Remote Config sudah dipakai**, tetapi hanya oleh `features/app_update`
  (`FirebaseRemoteConfigGateway`: nilai bawaan kosong, interval ambil 30 menit,
  hanya kunci berawalan `whats_new_`). `core` tidak boleh mengimpor fitur
  (ADR-030), jadi gateway itu tidak bisa dipakai ulang oleh port hak di `core`.
- **Progres onboarding hanya boolean.** `TutorialProgress.onboardingDone`
  tidak mencatat *kapan* onboarding selesai; uji coba (§8.1) butuh tanggal itu.
  Jalur pulihkan-saat-onboarding (T-22.5) juga menandai onboarding selesai
  (`markOnboardingDoneIfRestoring`), tanpa melewati langkah onboarding biasa.
- **Periode keuangan sudah berriwayat** (ADR-038): `financialPeriodOf(date,
  schedule)` satu-satunya cara menghitung periode; `FinancialMonthSchedule`
  disimpan sebagai riwayat berlaku-sejak.
- **Akun opsional** (ADR-023/024): `shared/auth` menyediakan identitas Firebase
  bila pengguna masuk; tanpa masuk, tidak ada ID pengguna.
- **Cadangan manual memuat seluruh kunci kecuali yang didaftarkan `exclude`**
  (ADR-040 §3.3); uji kelengkapan registri gagal bila ada kunci baru yang
  terlewat. Setiap kunci baru di ADR ini harus diputuskan masuk atau tidak.
- **Peristiwa Analytics** sudah memakai `restore_completed`
  (`DataPortabilityEvents`, Fase 22, dengan parameter `surface`), sedangkan
  laporan bisnis (bagian Untuk Engineer) memakai nama yang sama untuk
  *pemulihan pembelian*; daftar di FREEMIUM_PAYWALL §12.5 belum memuatnya. Dua arti pada satu nama akan merusak funnel.

## 3. Keputusan

Saldough menyimpan **satu keadaan paket** (`PlanState`) yang dihitung dari tiga
sumber: uji coba (**hanya bagi yang masuk akun**), hak dari RevenueCat
(pembelian Play atau hadiah), dan tenggang luring. Fitur bertanya ke **satu port** (`Entitlements`) dan
**tidak pernah** ke RevenueCat langsung. Gerbang berada di presentasi atau
use case otomasi, **tidak pernah** di `RecordTransaction`.

### 3.1 Struktur kode (ADR-030)

```
lib/core/foundation/entitlement/
  entitlements.dart            port Entitlements (current, changes, can, tryUse)
  plan_state.dart              PlanState (sealed), PlanSource, TrialWindow
  plus_feature.dart            enum PlusFeature + titik gerbang
  entitlement_limits.dart      EntitlementLimits (nilai bawaan lokal)
  entitlement_config.dart      port EntitlementConfig (batas dari Remote Config)
  trial_rules.dart             trialEndsOn(start, schedule) murni
  entitlement_resolver.dart    resolvePlan(cache, trial, now, grace) murni
lib/features/premium/
  data/    revenuecat_entitlements.dart, firebase_entitlement_config.dart,
           entitlement_cache_store.dart, trial_store.dart, quota_store.dart
  domain/  paywall_trigger.dart (P1..P10), offering_policy.dart
  presentation/ paywall, layar hadiah, rekap nilai, layar turun, bloc
  navigation/premium_route_keys.dart, premium_route_module.dart
lib/app/premium/
  premium_wiring.dart          menyusun adaptor, menyuntikkan ID pengguna
  plan_override.dart           pengganti paket untuk uji/pengembangan (§3.10)
```

- **`core/foundation/entitlement/` tidak mengimpor SDK maupun fitur.** Port
  `Entitlements` dan `EntitlementConfig` hidup di `core`; adaptor
  (`purchases_flutter`, `firebase_remote_config`) hidup di `features/premium/data/`
  dan didaftarkan akar komposisi. Fitur lain memakai `PremiumRouteKeys.paywall`
  dan `Entitlements` (impor dari `core`, bukan dari `features/premium`).
- `features/premium` **tidak** mengimpor fitur lain; fitur lain tidak
  mengimpornya selain lewat `premium_route_keys.dart` (aturan ADR-030 §3.3).
- `test/architecture/import_boundaries_test.dart` diperluas: (a)
  `core/foundation/entitlement/` tidak mengimpor `package:purchases_flutter`,
  `firebase_*`, atau `features/`; (b) tidak ada berkas di luar `lib/app/` dan
  `features/premium/data/` yang mengimpor `purchases_flutter`; (c)
  `lib/features/record/` dan `shared/transaction/` tidak mengimpor
  `entitlement/` (menjaga aturan "CATAT tidak punya cabang hak").

### 3.2 Keadaan paket: `PlanState`

```dart
sealed class PlanState {
  // Gratis: tidak ada hak aktif.
  Free();
  // Uji coba terbalik milik akun yang masuk; berlaku sampai [endsOn]
  // (hari terakhir, inklusif).
  Trial({required DateTime endsOn});
  // Plus. [until] = akhir periode berbayar; [source] = purchase | promotional
  // (RevenueCat) | override (hanya build non-rilis, §3.10) | prelaunch
  // (masuk akun sebelum Plus dijual, §3.13). [inGrace] = Play melaporkan masa
  // tenggang pembayaran: tetap Plus.
  Plus({required DateTime until, required PlanSource source, bool inGrace});
  // Langganan ditahan (billing gagal, lewat masa tenggang Play): perilaku
  // Gratis, dengan ajakan memperbaiki pembayaran.
  OnHold({required DateTime since});
}
```

- `isPlus` = `Trial` | `Plus` (termasuk tenggang). `Free` dan `OnHold` tidak.
- **Prioritas** bila beberapa sumber ada: `Plus` mengalahkan `Trial`. Trial yang
  habis tidak dihitung ulang bila pengguna memasang ulang sesudah membeli.
- **Mulai berlangganan saat masih uji coba** langsung menjadi `Plus`; sisa
  uji coba tidak diperpanjang atau dikembalikan (harga perkenalan §3.5
  mengompensasinya).
- Masa tenggang dan "ditahan" **mengikuti status Play yang dilaporkan
  RevenueCat** (`CustomerInfo`/`EntitlementInfo.billingIssueDetectedAt`,
  `periodType`, `isActive`); aplikasi tidak menghitung sendiri. Bila langganan
  yang ditahan kemudian dibayar, RevenueCat melaporkan aktif lagi dan keadaan
  kembali `Plus` lewat jalan yang sama dengan pembelian baru; tidak ada cabang
  khusus.
- `PlanState` adalah nilai (`Equatable`), `changes` adalah `Stream<PlanState>`
  broadcast yang hanya memancar bila nilainya berubah.

### 3.3 Hak, cache, dan luring

- `Entitlements.current` mengembalikan hasil `resolvePlan(...)` (fungsi murni,
  mudah diuji) dari **tiga masukan**: `TrialRecord?` (§3.4), `CachedPlus?`
  (hak RevenueCat terakhir yang diketahui), dan `now`.
- **Cache hak** (`entitlement_cache`): `{schemaVersion, until, source, lastVerifiedAt}`
  ditulis setiap kali RevenueCat berhasil dibaca. **Tenggang luring 3 hari**
  dihitung dari `max(until, lastVerifiedAt)`: selama `now ≤ until` hak tetap
  berlaku **tanpa koneksi**; sesudah `until` tanpa bisa diverifikasi, hak
  tetap berlaku sampai `until + 3 hari`, lalu jatuh ke `Free`. Pengguna Plus
  yang luring tetap Plus (NFR-REL-001).
- **Gagal membaca hak tidak pernah menghalangi apa pun yang gratis.** Tidak
  ada kondisi galat yang membuat `current` melempar: bila adaptor gagal
  diinisialisasi, `current` dihitung dari cache dan uji coba.
- Penyegaran hak: saat aplikasi dibuka, saat kembali dari latar, dan sesudah
  pembelian. Tidak ada polling terus-menerus.
- Nilai uji `now` diinjeksi (`Clock`), seperti di `RestoreEngine`.

### 3.4 Uji coba terbalik (KT-P2): hanya bagi yang masuk akun

Keputusan pemilik (23 Okt 2026): **uji coba Plus hanya diberikan kepada
pengguna yang masuk akun, termasuk penguji.** Pemakaian inti tetap tanpa akun
(ADR-024); yang butuh akun hanyalah *mencoba Plus gratis*. Tanpa akun, pengguna
tetap `Free` (jatah cicip tetap berlaku, P-8) dan layar hadiah/paywall
menawarkan "Masuk untuk mencoba Plus". Akibatnya ada **jangkar server** yang
selamat dari pasang ulang, tanpa backend sendiri.

`trial_rules.dart` (murni, tanpa Flutter):

```
trialEndsOn(DateTime start, FinancialMonthSchedule schedule, {int minDays = 14}):
  p     = financialPeriodOf(start, schedule)
  sisa  = hari dari start sampai p.end, keduanya dihitung (inklusif)
  return sisa >= minDays ? p.endDay : financialPeriodOf(p.end + 1 hari, schedule).endDay
```

**Awal uji coba (`start`) = jangkar akun**, dihitung di
`TrialAnchor.of(AppUser, {notBefore})`:

- Akun yang **dibuat sesudah** `plus_launch_at` (Remote Config, tanggal rilis
  Plus): `start` = `UserMetadata.creationTime` Firebase Auth, tanggal setempat.
  Nilai ini disimpan server Google, jadi **sama di semua perangkat dan tidak
  berubah oleh pasang ulang**.
- Akun yang **sudah ada** sebelum `plus_launch_at` (penguji dan pengguna
  awal): `start` = **hari pertama akun itu masuk sesudah Plus ada** di perangkat
  ini, disimpan lokal di `entitlement_trial`. Kohort ini kecil dan sebagian besar
  mendapat hadiah penguji (KT-P5); pasang ulang di kohort ini boleh memulai
  ulang uji coba (diterima, diukur lewat `trial_started`).
- `schedule` = jadwal periode yang berlaku saat uji coba **dihitung** (pilihan
  pengguna dari onboarding atau Akun; pulihkan-saat-onboarding membawanya dari
  cadangan).
- **Dihitung sekali per akun per perangkat dan disimpan** di `entitlement_trial`:
  `{schemaVersion, uid, start, endsOn}`. Perubahan `FinancialMonthSchedule`
  sesudahnya (termasuk periode peralihan 13–46 hari) **tidak** menghitung ulang.
  Berganti akun (ADR-024 §3.3) membuat rekaman baru untuk `uid` baru; rekaman
  `uid` lama tidak dipakai.
- Perangkat kedua dengan akun yang sama menghitung `endsOn` dari jangkar yang
  sama dengan jadwalnya sendiri; selisih hanya muncul bila jadwal periode
  berbeda (sesuai pilihan pengguna di perangkat itu). Diterima: selisih paling
  banyak satu periode dan selalu dalam batas 14–~45 hari.
- Plus berlaku sampai **rapor periode itu dibuka, paling lama `endsOn + 1 hari`**
  (hari tenggang untuk rapor). Sampai B-49 (rapor) ada, `Trial.endsOn` sama
  dengan `endsOn`.
- **Masuk dan keluar akun:** keluar akun saat uji coba berjalan menurunkan
  `PlanState` ke `Free` (uji coba milik akun, bukan perangkat); masuk lagi ke
  akun yang sama melanjutkan sisa uji coba tanpa memperpanjangnya.
- **Jalur pulihkan-saat-onboarding (T-22.5):** tidak lagi menyentuh uji coba.
  Uji coba tidak dimulai oleh onboarding, tetapi oleh masuk akun.

### 3.5 RevenueCat, Play, dan ID pengguna (KT-P6)

| Objek | Nilai |
|---|---|
| Entitlement | `plus` (satu-satunya hak) |
| Langganan Play | `plus` dengan base plan `monthly`, `yearly`, `yearly-founder` |
| Harga Pendiri | `yearly-founder` dinonaktifkan untuk pembelian baru sesudah 90 hari sejak rilis publik (pelanggan lama tetap diperpanjang) |
| Offer | `intro-first-year` pada `yearly` (KT-P12: harga perkenalan tahun pertama Rp129.000, lalu Rp179.000) |
| Offering | `default`, `founder`, `post_trial` |

- **Identifier package di RevenueCat (T-24.15):** setiap offering berisi package
  dengan identifier `monthly`, `yearly`, `yearly_founder`, atau `yearly_intro`
  (`PlusPlanKind.id`; package lain diabaikan aplikasi). `default` memuat
  `monthly` + `yearly`; `founder` memuat `yearly_founder` + `monthly`;
  `post_trial` memuat `yearly_intro` + `monthly`. Offering khusus yang kosong
  jatuh ke `default`. Pemilih memberi Pendiri didahulukan atas `post_trial`.
- **Memilih offering** ada di `OfferingPolicy` (domain `premium`, murni):
  `founder` bila `now ≤ founder_until`, `post_trial` dalam 48 jam sesudah uji
  coba berakhir (`post_trial_offer_hours`), selain itu `default`. Harga
  ditampilkan **dari string harga toko** (`StoreProduct.priceString`), tidak ada
  harga di kode atau Remote Config.
- **ID pengguna:** anonim RevenueCat sejak pertama dibuka (cukup untuk membaca
  harga dan membeli). Bila pengguna masuk akun (ADR-024),
  `Purchases.logIn(firebaseUid)`; keluar akun memanggil `Purchases.logOut()`. ID
  yang sama dipakai untuk hak promosi dan pemulihan lintas perangkat.
  **Pemakaian inti tanpa akun tetap penuh.** Membeli tanpa akun tetap
  dimungkinkan (hak terikat ke akun Google Play lewat `restorePurchases`);
  apakah pembelian juga mensyaratkan akun adalah P-9.
- **Kunci SDK RevenueCat** (public SDK key Android) disuntikkan lewat
  `--dart-define=REVENUECAT_ANDROID_KEY=...` di CI dan build lokal. Kunci ini
  memang dirancang publik, tetapi tidak di-commit supaya mudah diganti per
  lingkungan; tanpa kunci, `Entitlements` jatuh ke uji coba lokal dan cache
  (tidak ada pembelian, tombol beli tidak tampil).
- **Hak promosi (hadiah penguji, KT-P5):** karena **semua penguji harus masuk
  akun** (§3.4), hadiah Plus 12 bulan selalu berupa **entitlement promosi
  RevenueCat yang diberikan ke `firebaseUid` penguji** (dasbor atau REST oleh
  pemilik). Tidak ada kode promo Play untuk penguji. Penguji yang sudah punya
  akun Google bisa masuk dengan Google; **peringatan:** selama layar consent
  OAuth proyek Firebase belum terverifikasi, Google Sign-In hanya menerima daftar
  tester eksplisit (ADR-023), jadi daftar penguji Google harus dimasukkan ke
  daftar itu atau diberi akun email/sandi.

### 3.6 Batas dan jatah dari Remote Config

Port `EntitlementConfig` (di `core`) memberi `EntitlementLimits` bertipe;
adaptornya (`features/premium/data/FirebaseEntitlementConfig`) memakai
**instance Remote Config yang sama** dengan `app_update` tetapi **gateway
sendiri** (kunci berbeda, `getAll` difilter per awalan). Nilai bawaan hidup di
`EntitlementLimits.defaults` (kode), sehingga **tanpa koneksi atau Remote Config
gagal, nilai bawaan dipakai** (tidak pernah nol atau tak terbatas).

| Kunci | Bawaan | Arti |
|---|---|---|
| `free_notification_sources` | 1 | Aplikasi sumber notifikasi di Gratis |
| `free_smart_interpretations` | 30 | Tafsir Gemini per periode di Gratis, termasuk foto struk (KT-P14) |
| `taste_ask` / `taste_guardian` | 3 / 1 | Jatah cicip per periode |
| `free_analysis_periods` | 6 | Periode Analisis di Gratis |
| `free_budget_templates` / `free_projects` | 1 / 2 | Batas template (semua, aktif maupun nonaktif) dan proyek freelance (semua; §3.13) |
| `plus_fair_use_interpretations` / `_photo` / `_ask` | 1000 / 150 / 300 | Batas wajar bulanan Plus, tidak ditampilkan |
| `paywall_max_per_day` / `paywall_max_per_period` | 1 / 3 | Batas frekuensi paywall kontekstual |
| `trial_min_days` | 14 | Sisa hari minimum periode berjalan |
| `plus_launch_at` | kosong | Saat Plus mulai dijual; kosong = pra-peluncuran (§3.13) |
| `founder_until` | tanggal | Akhir jendela Harga Pendiri |
| `post_trial_offer_hours` | 48 | Lama penawaran sesudah uji coba |

- Nilai tidak sah (negatif, bukan angka) diabaikan dan dipakai bawaannya.
- Perubahan Remote Config berlaku saat aplikasi berikutnya dibuka atau lewat
  `onConfigUpdated`; **tidak** memengaruhi uji coba yang sudah berjalan.
- Kunci ini adalah parameter biasa, **terpisah** dari `whats_new_*` yang
  disinkronkan `scripts/release_notes.js`. Skrip itu hanya menyentuh awalan
  `whats_new_`, sehingga kedua pemakai tidak saling menghapus.

### 3.7 Jatah cicip dan kuota (penyimpanan per periode)

- `Entitlements.tryUse(PlusFeature, {Clock})` mengembalikan `QuotaResult`
  (`allowed`, `remaining`, `exhausted`) dan **mencatat pemakaian** bila `allowed`.
- Pemakaian disimpan di `entitlement_quota`: `{schemaVersion, periodStart,
  used: {feature: n}}`. Dihitung per **periode keuangan** (`financialPeriodOf`);
  bergantinya periode mereset otomatis. Dengan riwayat jadwal (ADR-038),
  periode lampau tidak dihitung ulang.
- Pengguna **Plus/Trial** tidak dihitung jatah cicip, tetapi tetap dicek **batas
  wajar** (`plus_fair_use_*`) yang tidak ditampilkan kecuali tersentuh.
- **Kuota tafsir Gemini** (`free_smart_interpretations`) digerbang di port
  `shared/capture`, bukan di UI: sesudah habis, hanya parser aturan yang
  berjalan dan **tidak ada yang gagal** (Gratis tetap bisa mencatat).
- Pemakaian yang gagal (jaringan, galat) **tidak** menghabiskan jatah:
  `tryUse` dipanggil sesudah hasil berhasil, atau dikembalikan lewat
  `refund(feature)`.

### 3.8 Titik gerbang yang sudah ada

Satu pola: UI/use case otomasi memanggil `Entitlements`; bila `!can`, tampil
`PaywallTrigger` (tidak pernah mengubah data). Nama pemicu mengikuti tabel
FREEMIUM_PAYWALL §9 (P1 kuota tafsir, P2 sumber notifikasi, P3 contoh Penjaga,
P4 jatah Tanya Tanuki, P5 perkiraan, P6 rapor, P7 freelance terlambat, P8
cadangan, P9 musim laporan, P10 Akun); gerbang fitur lama yang belum punya baris
di tabel itu memakai `recurringAutomation`, `analysisHistory`, dan `limit`.
Revisi 2 (T-24.8) memperbaiki penomoran P-n lama di kolom ini yang tidak cocok
dengan §9.

| Titik | Modul | Perilaku di Gratis | Trigger |
|---|---|---|---|
| Aplikasi sumber notifikasi ke-2 dst. | `notification_capture` | Paywall; **sumber pertama di daftar** tetap diproses, sisanya tidak (§3.13) | `notificationSource` (P2) |
| Tingkat otomatis, pola baru | `notification_capture` | Kembali ke "tinjau semua"; pola lama tetap dipakai | `notificationSource` (P2) |
| Kuota tafsir Gemini | `shared/capture` (port) | Sesudah habis, parser aturan saja | `smartQuota` (P1) |
| Otomasi rutin R3 (Catat otomatis, belum terlihat, kenaikan harga dari notifikasi, menganggur, saran) | `recurring`, `notification_capture` | Rutin yang `autoRecord` kembali menunggu konfirmasi satu ketuk; label R3 tidak tampil; satu deteksi boleh jadi Contoh Penjaga | `recurringAutomation` |
| Analisis > 6 periode (tren 12 bulan belum ada) | `analysis` | Tampilan buram + kartu; Riwayat tetap penuh | `analysisHistory` |
| Template ke-2, proyek ke-3 | `budget`, `freelance` | Yang ada tetap dipakai; membuat baru terhalang. Semua template dan semua proyek dihitung (§3.13) | `limit` |
| ~~Perkiraan lewat +2 bulan, Bagaimana kalau~~ | `plan` | Ditunda ke B-30/B-46 (§3.13) | `forecast` (P5) |

- **Gerbang R3 (ADR-037):** `RecurringRule.autoRecord` **tidak dihapus** saat
  turun ke Gratis; setelan disimpan untuk bila berlangganan lagi. Yang berubah
  adalah *penjalan otomasi*: `AutoRecordHost` (`features/recurring/presentation/host/`,
  ADR-037 §3.2) memeriksa `can(PlusFeature.recurringAutomation)` sebelum
  mencatat; bila tidak, kemunculan dibiarkan berstatus menunggu seolah
  `autoRecord == false` (kartu Menunggu, konfirmasi satu ketuk). Sakelar
  Catat otomatis di "Atur lebih lanjut" tetap tampil dengan label Plus dan
  membuka paywall `recurringAutomation`; nilainya tidak ditulis ulang.
  Transaksi yang sudah tercatat otomatis tetap ada (data tidak dikunci).
- **Pengecualian aturan 8 tetap berlaku:** kemunculan rutin bernominal tetap
  yang dikonfirmasi pengguna satu ketuk memakai `RecordTransaction` di Gratis
  maupun Plus; tidak ada cabang hak di sana.
- Pemeriksaan hak **tidak boleh** dilakukan di `RecordTransaction`,
  `TransactionRepository`, atau layar CATAT. Uji arsitektur §3.1(c) menjaganya.

### 3.9 Turun ke Gratis, `restore`, dan data

- **Turun tidak menghapus atau mengunci data** (FREEMIUM_PAYWALL §10). Semua
  gerbang di §3.8 hanya mengubah *pekerjaan baru*; tidak ada penulisan yang
  dilakukan saat turun.
- **Pemulihan data (ADR-040) tidak menyalin hak.** Empat kunci baru
  **ditandai `exclude`** di `BackupRegistry` dengan alasan:
  - `entitlement_trial` — rekaman uji coba milik akun dan perangkat, bukan data
    pengguna; menyalinnya ke ponsel lain atau akun lain bisa memperpanjang atau
    memulai ulang uji coba secara tidak sah.
  - `entitlement_cache` — hak tercantum pada akun Play/RevenueCat, bukan
    berkas; menyalin cache bisa memberi Plus ke ponsel yang tidak berhak.
  - `entitlement_quota` — jatah per periode milik perangkat; memulihkan tidak
    boleh mereset jatah.
  - `entitlement_debug_override` — pilihan pengganti uji (§3.10), milik perangkat
    dan hanya dibaca di build non-rilis.
- **Pulihkan pembelian** (`Purchases.restorePurchases`) adalah tindakan terpisah
  di layar Akun/paywall untuk memulihkan hak di ponsel baru; ia **tidak**
  terkait pemulihan data.

### 3.10 Pengganti paket untuk uji, pengembangan, dan tinjauan toko

Kebutuhan: tim (pengembang, QA, penguji) dan peninjau toko harus bisa memakai
**semua fitur Plus tanpa membeli dan tanpa menunggu uji coba**, tanpa membuka
celah di build yang dirilis ke publik. Dua jalur, dipisah menurut jenis build:

**a. Build non-rilis (debug dan profile; pengembangan dan QA di emulator/ponsel
sendiri).** Pengganti paket di klien, dikunci `kReleaseMode`:

- `PlanOverride { auto, free, trial, plus }` (bawaan `auto` = tanpa pengganti).
  Nilai awal dari `--dart-define=PLAN_OVERRIDE=plus` dan dapat diganti saat
  berjalan dari **menu pengembang** (tombol debug yang sudah ada di `app.dart`,
  `!kDebugMode` tersembunyi) tanpa memulai ulang. Pilihan disimpan di kunci
  `entitlement_debug_override` (tidak ikut cadangan, `exclude`).
- Hasilnya masuk `resolvePlan` sebagai sumber paling prioritas dengan
  `PlanSource.override`. `plus` memberi `Plus` tanpa batas waktu; `trial` memberi
  `Trial` yang berakhir besok (menguji layar turun dan momen terjadwal); `free`
  memaksa Gratis meski hak ada.
- **Tidak mungkin aktif di build rilis:** (1) seluruh pembacaan `PLAN_OVERRIDE`
  dan kunci debug berada di satu berkas `lib/app/premium/plan_override.dart`
  yang mengembalikan `auto` bila `kReleaseMode`; (2) uji arsitektur gagal bila
  `PLAN_OVERRIDE` atau `entitlement_debug_override` muncul di berkas lain atau di
  `.github/workflows/`; (3) pipeline rilis tidak pernah memberi `--dart-define`
  itu. Sebuah uji kesetaraan memastikan `resolvePlan` di build rilis tidak
  menerima `PlanSource.override`.

**b. Build rilis yang dibagikan (closed testing, produksi, tinjauan Play).**
**Tidak ada sakelar di klien.** Pengganti selalu berupa **data hak**:

- **Penguji:** entitlement promosi RevenueCat per `firebaseUid` (§3.5). Berlaku
  juga di build rilis sebenarnya, jadi QA menguji jalur yang sama dengan
  pengguna.
- **Peninjau Google Play:** akun **email/sandi** khusus peninjau (sudah ada,
  ADR-023) diberi **entitlement promosi RevenueCat tanpa tanggal berakhir** di
  dasbor, dan kredensialnya ditaruh di "App access" Play Console. Peninjau
  masuk, lalu seluruh fitur Plus terbuka; tombol beli tetap bekerja dan
  menampilkan layar pembelian uji Play. Akun itu **tidak bisa dibuat sendiri
  oleh pengguna** (tidak ada pendaftaran mandiri) dan tidak punya data nyata.
- **Penguji pembelian:** akun **penguji lisensi** Play Console (membeli tanpa
  ditagih) dan angka perpanjangan dipercepat untuk menguji tenggang, ditahan,
  dan kedaluwarsa.
- **Rotasi:** hak promosi peninjau diperiksa tiap rilis publik (daftar periksa
  rilis, `RELEASE_NOTES.md`); kredensial diganti bila bocor, tanpa perubahan
  kode.

Alasan memisahkan: sakelar klien di build rilis adalah satu pembaruan kesalahan
dari "Plus gratis untuk semua" dan tidak bisa dicabut dari server; hak promosi
bisa dicabut kapan saja di RevenueCat dan menguji jalur produksi sebenarnya.

### 3.11 Keputusan yang diminta dari pemilik

Diputuskan pemilik 23 Okt 2026: uji coba **wajib masuk akun**, termasuk penguji
(menggantikan P-1 dan P-4 usulan awal); **perlu sakelar/nilai khusus** untuk
uji, pengembangan, dan tinjauan toko (§3.10).

| # | Hal | Rekomendasi |
|---|---|---|
| P-1 | ~~Hadiah penguji tanpa akun~~ | Selesai: semua penguji masuk akun; entitlement promosi per `firebaseUid` (§3.5). |
| P-2 | Nama peristiwa pemulihan pembelian | Pakai `purchase_restored`; `restore_completed` sudah dipakai Fase 22 untuk pemulihan data. §12.5 FREEMIUM_PAYWALL menambahkan peristiwa ini; laporan bisnis pemilik perlu disesuaikan. |
| P-3 | ~~Uji coba lewat pulihkan-saat-onboarding~~ | Selesai: uji coba dimulai oleh masuk akun, bukan onboarding (§3.4). |
| P-4 | ~~Pasang ulang membuat uji coba baru~~ | Selesai untuk akun baru (jangkar server `creationTime`). Tersisa hanya kohort akun lama sebelum Plus (§3.4), diukur. |
| P-5 | `plus_fair_use_*` memakai angka dokumen | Pakai bawaan dokumen; ukur biaya nyata sejak Plus dijual. |
| P-6 | Kunci SDK RevenueCat lewat `--dart-define` | Setuju; pemilik memberi kunci ke CI. |
| P-7 | Akun RevenueCat, langganan dan base plan di Play Console, offering, entitlement promosi peninjau dan penguji | Pekerjaan pemilik; ADR ini hanya memberi nama objek (§3.5, §3.10). |
| P-8 | Jatah cicip Gratis (3 tanya, 1 Penjaga, 30 tafsir cerdas) tanpa akun | **Disetujui:** tetap boleh tanpa akun (itu fitur Gratis, bukan "mencoba premium"); hanya uji coba penuh dan hadiah penguji yang wajib akun. Konfirmasi: bila jatah cicip juga wajib akun, ubah `can()` dan hitung jatah per `uid`. |
| P-9 | Apakah **membeli** Plus juga wajib masuk akun | **Disetujui:** tidak wajib (kurangi gesekan; hak terikat ke akun Google Play dan bisa dipulihkan), tetapi paywall menawarkan masuk agar hak ikut ke perangkat lain. Bila wajib, pembelian tidak mungkin di build tanpa akun. |
| P-10 | Pengganti uji: menu pengembang + `PLAN_OVERRIDE` hanya di build non-rilis; penguji dan peninjau lewat entitlement promosi, **tanpa sakelar di build rilis** | Rekomendasi: setuju (§3.10). |
| P-11 | `plus_launch_at` = tanggal rilis publik Plus (Remote Config) | **Disetujui:** diisi pemilik sebelum Plus dijual. |

### 3.13a Gerbang tampilan lewat `ActivePlan` (T-24.9)

Gerbang yang cukup tahu "Plus atau bukan" (otomasi R3: sakelar Catat otomatis,
kartu, dan label) membaca `ActivePlan.notifier`
(`lib/core/presentation/plan/active_plan.dart`), pola yang sama dengan
`ActiveCurrency` dan `ActiveFinancialMonth`: diisi `startEntitlements` dari
`Entitlements.changes`, dikembalikan ke Gratis di `_resetGlobalState` saat boot
ulang, dan **bawaannya Gratis** supaya kabel yang terlewat mengunci, bukan
membuka. Gerbang yang butuh batas atau jatah (`allows`, `quota`, `tryUse`)
tetap memakai `Entitlements` yang disuntikkan. Modul `core/foundation/entitlement/`
tetap murni (tanpa Flutter); `ActivePlan` hidup di `core/presentation/plan/`.

### 3.13 Revisi 2: hasil pemeriksaan kode dan keputusan pemilik (23 Okt 2026)

Rencana implementasi Fase 24 memeriksa ADR ini terhadap kode `origin/main`.
Temuan dan keputusannya:

1. **Pra-peluncuran: masuk akun = Plus (diputuskan pemilik).** Gerbang yang
   dirilis sebelum Plus dijual akan menurunkan semua pengguna tanpa uji coba ke
   Gratis. Pemilik memilih **membiarkan gerbang mengunci** dan meminta penguji
   **masuk akun**. Selama `plus_launch_at` kosong (bawaan): pengguna yang masuk
   akun mendapat `Plus(source: prelaunch)` tanpa batas waktu; tanpa akun `Free`;
   uji coba tidak dimulai dan tombol beli tidak tampil. Aturan ini tidak
   bergantung RevenueCat. Mengisi `plus_launch_at` mengakhiri pra-peluncuran:
   sejak itu berlaku §3.4 (uji coba) dan pembelian. Kunci `trial_not_before`
   lama digantikan `plus_launch_at` (satu tanggal untuk keduanya).
   **Prasyarat sebelum build bergerbang dirilis (pemilik):** semua penguji bisa
   masuk (daftar tester OAuth Google atau akun email/sandi, ADR-023), dan catatan
   rilis serta email penguji memberi tahu "masuk akun untuk tetap memakai fitur
   Plus". Halaman paywall sementara (sebelum rupa final) menawarkan masuk lewat
   `AccountRouteKeys.page`.
2. **Proyek freelance tidak punya status aktif/arsip** (`FreelanceProject` hanya
   `id, name, hourlyRate, deductionRules`). **Diputuskan:** batas menghitung
   **semua proyek** (`free_projects`, bawaan 2); arsip proyek jadi antrean baru.
3. **Sumber notifikasi yang tetap saat turun:** `NotificationCaptureSettings.sources`
   berurutan tanpa statistik pemakaian. **Diputuskan:** sumber **pertama** di
   daftar; pengguna mengubahnya dengan menyusun ulang atau memilih ulang sumber.
4. **Gerbang Rencana ditunda.** `PlanMonthState.horizon` sudah 2 bulan dan
   horizon 12 bulan (B-30) serta tren 12 bulan Analisis belum ada, jadi tidak
   ada yang digerbang; gerbangnya ikut B-30/B-46. **Template:** semua template
   dihitung, aktif maupun nonaktif.
5. **`trialAnchor` di `core` menerima primitif** (`uid`, `accountCreatedAt`,
   `firstSeenLocal`, `launchAt`), karena `core` tidak boleh mengimpor `shared`.
   `AppUser` (`shared/auth`) mendapat field `createdAt` dari
   `fb.User.metadata.creationTime`.
6. **Patch Shorebird membawa kunci RevenueCat.** Lane `release_internal` dan
   `patch_ota` di `android/fastlane/Fastfile` keduanya memberi
   `--dart-define=REVENUECAT_ANDROID_KEY`; bila hanya rilis, patch pertama
   membuang kunci dan pembelian berhenti.
7. **Menu pengembang hanya muncul di `kDebugMode`** (`lib/app/app.dart`) dan
   isinya `DevEntry` dari `FeatureRouteModule.devEntries` (paket `navigation`).
   Pilihan `PlanOverride` dipasang sebagai `DevEntry` dari modul rute milik
   `lib/app/`. Build profile hanya bisa memakai `--dart-define=PLAN_OVERRIDE`.
8. **Remote Config satu singleton.** Gateway premium memakai setelan ambil yang
   sama dengan `app_update` (`minimumFetchInterval` 30 menit, `fetchTimeout`
   10 detik) agar keduanya tidak saling menimpa.

### 3.12 Peristiwa Analytics (ADR-023: tanpa nominal, nama, atau isi)

`trial_started{days}`, `trial_moment{pillar}`, `trial_value_recap_shown`,
`trial_ended{outcome}`, `paywall_viewed{trigger}`, `paywall_dismissed{trigger}`,
`purchase_started{plan}`, `purchase_completed{plan}`, `purchase_failed{reason}`,
`purchase_restored`, `plus_feature_used{feature}`,
`taste_quota_exhausted{feature}`.

- `plan` ∈ `monthly | yearly | yearly_founder | yearly_intro`; `reason` ∈
  `cancelled | network | billing | other`; `trigger` = `PaywallTrigger.analyticsName` (`P1`–`P10` mengikuti FREEMIUM_PAYWALL §9, ditambah `recurring_automation`, `analysis_history`, `limit`);
  `outcome` ∈ `purchased | lapsed`.
- Dikelompokkan di `PremiumEvents` (seperti `DataPortabilityEvents`) dengan uji
  parameter. `PLAY_DATA_SAFETY.md` diperbarui: **riwayat pembelian** dan ID
  pengguna dibaca/disimpan RevenueCat (penyedia pihak ketiga); kategori jawaban
  formulir (pembelian, ID perangkat atau lainnya) diperiksa terhadap formulir
  Play saat B-41 dikerjakan, bukan ditebak di sini. Kebijakan privasi situs
  (B-20) memuat RevenueCat.

## 4. Opsi yang dipertimbangkan

| Opsi | Ringkas |
|---|---|
| **A. `purchases_flutter` (RevenueCat) + port `Entitlements` (Dipilih)** | Verifikasi kuitansi di server RevenueCat tanpa backend sendiri; ID anonim cocok dengan akun opsional; siap iOS; hak promosi |
| B. `in_app_purchase` + Cloud Functions | Tanpa pihak ketiga, tetapi butuh Firebase Blaze (T-11.8), verifikasi kuitansi sendiri, dan tidak punya hak promosi |
| C. Hak sepenuhnya lokal (tanpa verifikasi server) | Paling sederhana; mudah dibobol dan tidak punya pemulihan lintas perangkat |
| D. Gerbang di `RecordTransaction` | Satu titik, tetapi melanggar aturan 8 dan bisa menghalangi pencatatan |
| **E. Gerbang di presentasi dan use case otomasi (Dipilih)** | Pencatatan manual bebas cabang hak |

## 5. Konsekuensi

### Opsi A — RevenueCat + port (Dipilih)

- (+) Verifikasi kuitansi dan status tenggang/tahan dilakukan RevenueCat; hak
  promosi untuk penguji; mudah ditukar adaptornya karena fitur hanya melihat
  `Entitlements`.
- (−) Ketergantungan pada pihak ketiga dan biaya (sumber berbeda: US$2.500 MTR
  lalu 1%, atau US$10.000; cek halaman harga resmi sebelum rilis berbayar).
- (−) Satu SDK baru (`purchases_flutter`) dan pembaruan Keamanan Data.

### Opsi B

- (+) Tanpa pihak ketiga. (−) Backend dan Blaze untuk satu fitur; tidak ada
  hak promosi.

### Opsi C

- (−) Tidak cocok untuk produk berbayar; ditolak.

### Opsi D

- (−) Melanggar aturan 8 dan NFR-REL-001; ditolak.

### Opsi E — Presentasi dan use case otomasi (Dipilih)

- (+) CATAT dan kemunculan rutin satu ketuk tidak pernah terhalang.
- (−) Setiap titik gerbang perlu uji widget sendiri; risiko ada titik yang
  terlewat ditutup daftar §3.8 dan uji per titik.

### Risiko

| Risiko | Mitigasi |
|---|---|
| Cache hak basi memberi Plus terlalu lama | Tenggang 3 hari dari `max(until, lastVerifiedAt)`; selewat itu `Free` |
| Hak gagal dibaca saat dibuka | `current` dihitung dari cache dan uji coba; tidak melempar |
| Salah menghitung `trialEndsOn` di periode peralihan | Fungsi murni diuji dengan jadwal berriwayat dan peralihan 13–46 hari |
| Uji coba disalahgunakan lewat pasang ulang atau akun baru | Jangkar `creationTime` server untuk akun baru; akun baru tanpa batas masih bisa dibuat (Google), jadi `trial_started` per akun diukur dan, bila perlu, ditambah syarat verifikasi (tidak di ADR ini) |
| Sakelar uji bocor ke build rilis | Dikunci `kReleaseMode`, satu berkas, uji arsitektur, pipeline tanpa define; jalur rilis memakai hak promosi, bukan sakelar |
| Peninjau Play tidak bisa masuk | Akun email/sandi peninjau (ADR-023) + hak promosi tanpa batas waktu; diperiksa tiap rilis publik |
| Biaya Gemini melebihi pendapatan pemakai berat | Batas wajar; biaya nyata diukur |
| Titik gerbang terlewat | Daftar §3.8 + uji per titik + uji arsitektur |

## 6. Rencana verifikasi

- **Uji murni:** `trialEndsOn` (batas 13/14 hari, periode mulai tanggal 25,
  peralihan, akhir bulan); `resolvePlan` (uji coba, Plus, tenggang, ditahan,
  tenggang luring 3 hari persis, `until` dan `lastVerifiedAt`); `OfferingPolicy`
  (founder, post_trial 48 jam, default); `QuotaStore` (ganti periode, refund).
- **Uji adaptor:** `RevenueCatEntitlements` dengan SDK palsu (pembelian, tenggang,
  ditahan, pulihkan); `FirebaseEntitlementConfig` dengan nilai tidak sah dan
  Remote Config gagal.
- **Uji gerbang per titik** (§3.8): Gratis dan Plus; R3 mengembalikan ke
  konfirmasi satu ketuk **tanpa mengubah `autoRecord`**; CATAT tidak punya
  cabang hak.
- **Uji arsitektur:** §3.1(a)–(c); `PLAN_OVERRIDE` dan kunci debug hanya di
  `plan_override.dart`; uji kelengkapan registri (empat kunci `exclude`
  beserta alasannya, termasuk `entitlement_debug_override`).
- **Uji uji coba:** `TrialAnchor` (akun baru vs akun lama, `plus_launch_at`),
  keluar dan masuk akun, berganti akun, tanpa akun tetap `Free`.
- **Uji pengganti:** `auto/free/trial/plus` memengaruhi `resolvePlan` hanya
  bila bukan rilis; di mode rilis `PlanSource.override` ditolak.
- **Uji bolak-balik:** pulihkan data **tidak** mengubah `entitlement_*`.
- **Perangkat (QA/pemilik, jalur uji Play):** pembelian bulanan dan tahunan,
  uji coba berakhir, penawaran 48 jam, tenggang dan ditahan (angka perpanjangan
  dipercepat di Play), mode pesawat, pulihkan pembelian di ponsel kedua.

## 7. Tidak dikerjakan di ADR ini

- Fitur Plus baru (Penjaga B-44, Catat dari foto B-45, Bagaimana kalau B-46):
  ADR sendiri bila ada keputusan teknis baru.
- iOS (StoreKit lewat RevenueCat): struktur siap, belum diverifikasi.
- Plus Keluarga dan Dompet Bersama (B-60), cadangan otomatis (B-51), kosmetik
  (B-56).
- Eksperimen harga di Play; harga tetap hipotesis yang disetel lewat Remote
  Config dan Play.

## 8. Rujukan

- [FREEMIUM_PAYWALL.md](../../01-product/features/FREEMIUM_PAYWALL.md) §8–§12,
  §15–§16
- [Tanukonomy Plus: Rencana Bisnis dan Spesifikasi Kerja Paywall](https://claude.ai/artifact/SKsV87e4f7hX8h58Qvv7G5)
- [ADR-023](0023-identitas-opsional-firebase-auth-analitik-crashlytics.md),
  [ADR-024](0024-kepemilikan-data-lokal-dan-akun.md),
  [ADR-030](0030-batas-antarfitur-rute-bertipe-dan-sinyal-buku-besar.md),
  [ADR-037](0037-otomasi-rutin-r3.md),
  [ADR-038](0038-periode-keuangan-berriwayat-dan-peralihan.md),
  [ADR-039](0039-pengumuman-pembaruan-play-shorebird-dan-catatan.md),
  [ADR-040](0040-ekspor-cadangan-dan-pemulihan-manual.md)
