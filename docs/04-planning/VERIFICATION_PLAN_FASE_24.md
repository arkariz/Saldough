# Rencana verifikasi perangkat Fase 24 (Fondasi Plus), T-24.18

**Disusun:** 6 November 2026. **Keputusan teknis:** [ADR-041](../02-architecture/adr/0041-monetisasi-hak-plus-dan-uji-coba.md)
§3.2–§3.5, §3.10, §6. **Desain produk:** [FREEMIUM_PAYWALL.md](../01-product/features/FREEMIUM_PAYWALL.md).

Dokumen ini menjadi lembar kerja T-24.18: apa yang harus disiapkan, tiap skenario
(langkah, hasil yang diharapkan, cara mempercepat), dan lembar hasil. Uji murni
dan adaptor (`resolvePlan`, `OfferingPolicy`, `trialEndsOn`, gerbang per titik)
sudah ada di `test/`; yang dikerjakan di sini hanya hal yang butuh **perangkat,
Play, dan RevenueCat sungguhan**.

## 0. Yang sudah dilihat di emulator (6 Nov 2026, belum ada pembelian)

Build debug dengan `--dart-define-from-file=dart_defines.local.json` (kunci SDK
`goog_…` dan `ENTITLEMENT_OVERRIDES=plus_launch_at=2026-10-01`), emulator Android
dengan Google Play dan satu akun Google, belum masuk akun aplikasi:

- Akun › Plus: "Tanukonomy Plus, Gratis", tombol **Lihat Plus** dan **Pulihkan
  pembelian**.
- Paywall membaca **harga toko sungguhan lewat RevenueCat**: *Harga Pendiri*
  Tahunan **Rp129.000/tahun** (coret Rp179.000, "Terkunci selama berlangganan ·
  sampai 31 Des 2026") dan Bulanan **Rp25.000/bulan**; tombol **Berlangganan
  tahunan** dan **Nanti saja**; catatan "Rp129.000 per tahun, diperpanjang
  otomatis. Batalkan kapan saja di Play Store." Artinya produk Play, RevenueCat
  (entitlement/offering), dan Remote Config (`founder_until`) sudah tersambung.
- Tanpa akun: ajakan **Masuk untuk mencoba Plus** (sesuai ADR-041 §3.4).
- **Belum dijalankan:** semua pembelian, uji coba, tenggang, ditahan, mode
  pesawat, pulihkan, dan akun peninjau (daftar di §3).

## 1. Peringatan sebelum membeli apa pun

1. **Hanya beli dengan akun penguji lisensi.** Play Console › Setelan › Pengujian
   lisensi: akun yang dipakai di perangkat harus tercantum di sana. Selain itu
   pembelian **ditagih sungguhan**.
2. Pengujian lisensi hanya membuat pembelian tidak ditagih; jangan menguji
   dengan akun pribadi yang bukan penguji "untuk melihat saja".
3. Mengisi **`plus_launch_at` di Remote Config** berlaku untuk **semua** pengguna
   (menghidupkan uji coba dan tombol beli untuk publik). Untuk uji, pakai build
   debug dengan `ENTITLEMENT_OVERRIDES` (tidak aktif di build rilis), atau beri
   kondisi Remote Config hanya untuk akun penguji. Jangan mengisinya global
   sebelum Plus memang akan dijual.
4. Build debug yang ditandatangani kunci debug **belum tentu bisa membeli**
   (Play bisa menolak tanda tangan yang tidak cocok). Bila pembelian gagal di
   build debug, ulangi dari build rilis yang dipasang lewat **jalur uji internal**
   Play (§2b); itu juga jalur yang paling mirip pengguna sungguhan.

## 2. Persiapan

### a. Build debug di emulator atau ponsel sendiri (cepat, tanpa Play)

```bash
.fvm/flutter_sdk/bin/flutter build apk --debug --dart-define-from-file=dart_defines.local.json
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

`dart_defines.local.json` (di-gitignore) memuat `REVENUECAT_ANDROID_KEY` dan
`ENTITLEMENT_OVERRIDES`. Pengganti paket tanpa pembelian, hanya build debug:
`--dart-define=PLAN_OVERRIDE=free|trial|plus` atau **Menu pengembang** (tombol
di pojok layar). `trial` memberi uji coba yang berakhir besok.

### b. Build rilis lewat jalur uji internal (mirip pengguna)

Disiapkan 6 Nov 2026: `pubspec.yaml` **`1.0.0+22`** dan
`release_notes/22-0.json` (`version` `1.0.0`, tiga butir; wajib disetujui lewat
PR sebelum workflow, [RELEASE_NOTES.md](../03-release/RELEASE_NOTES.md)).

Fakta kode yang menentukan caranya:

- Di build rilis **override debug mati** (`ENTITLEMENT_OVERRIDES` dan
  `PLAN_OVERRIDE` diabaikan). `plus_launch_at` hanya dari Remote Config.
- Kunci SDK RevenueCat di build rilis harus **`goog_…`**; lane menolak `test_…`.
  Kunci itu dibaca dari secret GitHub `REVENUECAT_ANDROID_KEY`.
- Lane `release_internal` mengunggah ke **jalur uji internal** (bukan produksi).
- Workflow juga **menerbitkan catatan rilis ke Remote Config** per nomor build
  (22) sebelum build; pengguna di build lain tidak terpengaruh.

Langkah:

1. Gabungkan perubahan ke `main` lewat PR (atau pilih cabang kerja saat
   menjalankan workflow), dengan `release_notes/22-0.json` sudah disetujui.
2. Jalankan workflow **Shorebird Pipeline** dengan `action_type = release`.
3. Di Play Console pastikan penguji ada di jalur uji internal; pasang dari
   tautan uji dengan **akun penguji lisensi**.
4. Di Firebase Remote Config isi `plus_launch_at` (tanggal lampau) **dengan
   kondisi "Versi aplikasi = 1.0.0"** (atau build 22) saja. Pengguna closed
   testing yang masih di `0.12.2` tidak terpengaruh, dan pra-peluncuran tetap
   berlaku untuk mereka.
5. **Sebelum rilis produksi, hapus atau ubah kondisi itu.** Versi `1.0.0` akan
   dipakai publik; kondisi yang tertinggal akan menghidupkan uji coba dan
   penjualan Plus untuk semua pengguna. Putuskan dulu apakah Plus memang mulai
   dijual saat rilis.
6. Tanpa `plus_launch_at` (belum diisi), build ini berada di pra-peluncuran:
   masuk akun = Plus, tanpa akun = Gratis, tombol beli tidak tampil. Ini juga
   yang diuji di U15.

Build rilis yang dipasang lokal lewat `adb` cukup untuk memeriksa R8 dan
ketiadaan sakelar klien (U15), tetapi **belum tentu bisa membeli** (tanda
tangan), dan di worktree tidak ada `android/key.properties` (jatuh ke kunci
debug).

**Catatan konfigurasi:** konfigurasi VS Code "Saldough (Plus sandbox)" memakai
`flutterMode: release`, padahal override dimatikan di mode rilis; untuk jalur
sandbox yang dijelaskan T-24.18 pakai mode debug.

### c. Konsol yang perlu dicek (pemilik)

| Tempat | Periksa |
|---|---|
| Play Console | Langganan `plus` aktif; base plan `monthly`, `yearly`, `yearly-founder`; offer `intro-first-year` pada `yearly`; **Pengujian lisensi** berisi akun uji |
| RevenueCat | Entitlement `plus` terhubung ke produk; offering `default` (`monthly`, `yearly`), `founder` (`yearly_founder`, `monthly`), `post_trial` (`yearly_intro`, `monthly`); tampilan **Customers** untuk melihat pembelian uji |
| Firebase Remote Config | `plus_launch_at`, `founder_until`, `post_trial_offer_hours` (bawaan 48), `trial_min_days` (bawaan 14), batas Gratis (`free_projects` dkk.) |
| Auth | Akun email/sandi peninjau ada dan punya entitlement promosi RevenueCat **tanpa tanggal berakhir** |

### d. Mempercepat waktu

- Langganan uji Play **diperpendek**: perpanjangan bulanan dan tahunan terjadi
  dalam hitungan menit, uji coba gratis dan masa tenggang juga menit, dengan
  paling banyak beberapa kali perpanjangan. Angka pastinya ada di dokumentasi
  Play ("Test your Google Play Billing Library integration"); cek di sana saat
  menjalankan, karena bisa berubah.
- Kartu uji Play **"always declines"** membuat pembayaran gagal sehingga masa
  tenggang dan penahanan terjadi.
- Untuk jam aplikasi (uji coba berakhir, tenggang luring 3 hari): ubah
  **tanggal ponsel** secara manual (matikan "tanggal dan waktu otomatis").
  `adb shell settings put global auto_time 0` lalu atur lewat Setelan.

## 3. Skenario

Beri tanda di kolom hasil: ✅ lulus, ❌ gagal (tulis temuannya di bawah tabel),
➖ belum.

| # | Skenario | Langkah | Hasil yang diharapkan | Hasil |
|---|---|---|---|---|
| U1 | Tanpa akun | Buka Akun › Plus tanpa masuk | Gratis; paywall mengajak **Masuk untuk mencoba Plus**; uji coba tidak mulai | ✅ 6 Nov 2026, build rilis `1.0.0+22` dari Play di emulator: Akun › Plus "Gratis", paywall "Masuk untuk mencoba Plus", harga toko tampil (Pendiri tahunan Rp129.000, bulanan Rp25.000), tombol beli tampil karena `plus_launch_at` sudah dikondisikan untuk 1.0.0 |
| U2 | Masuk akun: uji coba mulai | Masuk (Google atau email), buka Akun › Plus | Plus berstatus uji coba; berakhir di akhir periode keuangan, paling cepat 14 hari (`trialEndsOn`); sumber *trial* | ✅ 6 Nov 2026: masuk Google di emulator; Akun › Plus "Sampai 30 Nov 2026. Tanpa kartu. Uji coba". Hari ini 6 Nov, periode 1–30 Nov, sisa 25 hari ≥ 14, jadi berakhir 30 Nov sesuai rumus. Paywall di masa uji coba tetap menampilkan opsi beli (bahan U5) |
| U3 | Beli bulanan | Paywall › Bulanan › Berlangganan, penguji lisensi | Layar pembelian uji Play; sesudahnya **Plus** (sumber *purchase*), perayaan tampil, Akun menunjukkan Plus; pembelian terlihat di RevenueCat (sandbox) | ✅ 6 Nov 2026 23:1x: Bulanan Rp25.000/5 menit (langganan uji dipercepat); sheet Play menampilkan "Test card, always approves" dan "This is a test subscription". Sesudah Berlangganan: perayaan "Plus aktif — Paket bulanan, diperpanjang 6 Nov 2026" (Plus, Bulanan, "Sekarang terbuka"); Akun › Plus "Aktif sampai 6 Nov 2026" dengan **Kelola di Play Store**. Dasbor RevenueCat: belum dicek pemilik. Catatan: ketukan `adb` tidak diterima tombol Subscribe di sheet Play; ditekan pemilik langsung |
| U4 | Beli tahunan | Paywall › Tahunan (Pendiri atau default) | Sama seperti U3; harga sesuai penawaran (Pendiri Rp129.000 bila `now ≤ founder_until`) | ✅ 7 Nov 2026 09:02, emulator 5556 (anonim): Tahunan Pendiri Rp129.000, periode uji 30 menit; sheet Play "Test card, always approves" dan "This is a test subscription"; sesudahnya Akun "Aktif sampai 7 Nov 2026 · Plus" |
| U5 | Mulai berlangganan saat uji coba | Dari U2, beli | Langsung **Plus**; sisa uji coba tidak diperpanjang | ✅ Dibeli saat uji coba masih berjalan (uji coba hingga 30 Nov): langsung berstatus Plus pembelian, tanpa tersisa uji coba di Akun |
| U6 | Uji coba berakhir | `PLAN_OVERRIDE=trial` atau majukan tanggal melewati `endsOn` | Turun ke Gratis, **layar turun** tampil; **data tidak terhapus** | ➖ |
| U7 | Penawaran 48 jam | Dalam `post_trial_offer_hours` sesudah uji coba | Paywall memakai offering `post_trial` (tahunan harga perkenalan + bulanan); sesudah 48 jam kembali ke `default` | ➖ |
| U8 | Masa tenggang | Setelah U3/U4, buat pembayaran gagal (kartu "always declines") | Tetap **Plus**, ada ajakan memperbaiki pembayaran (`inGrace`) | ✅ 7 Nov 2026, anonim (tanpa uji coba), beli Bulanan 08:35, kartu diganti ke "always declines" 08:38: pada 08:41–08:45 Akun › Plus "Pembayaran belum berhasil. Plus tetap aktif sampai 7 Nov 2026." (masa tenggang, Plus tetap). Masa tenggang uji sekitar 5 menit |
| U9 | Ditahan | Lewat masa tenggang | Perilaku **Gratis** dengan ajakan memperbaiki; bila dibayar, kembali Plus tanpa cabang khusus | ✅ 7 Nov 2026: 08:46 sekejap Gratis (peralihan), **08:47 "Langganan ditahan karena pembayaran belum berhasil. Perbaiki di Play Store."** (lencana Periksa, Kelola di Play Store). Percobaan 1 (6 Nov, akun masuk) juga ditahan. **Pemulihan lulus (08:49)**: kartu diganti ke "always approves" selagi ditahan, Akun kembali "Aktif sampai 7 Nov 2026 · Plus" tanpa cabang khusus dan tanpa pesan ditahan, stabil 08:49–08:51. Lihat T2 untuk keadaan sesudah kedaluwarsa |
| U10 | Mode pesawat | Plus aktif, nyalakan mode pesawat, majukan tanggal | Selama `now ≤ until` tetap Plus tanpa koneksi; sesudah `until` tetap Plus sampai `until` (atau verifikasi terakhir) + **3 hari**, lalu Gratis. Fitur gratis tidak terganggu | ❌ **gagal, terkonfirmasi waktu nyata** (7 Nov 2026, emulator 5556, anonim). Luring dalam periode → Plus (✅). Dengan jam digeser +2 hari, luring → Gratis; cache terhapus (jam dikembalikan tetap Gratis). **Waktu nyata:** daring dibaca 09:06, mode pesawat 09:07, periode berakhir sekitar 09:32, dibuka luring 09:34 → **Gratis** (spek: Plus sampai `until + 3 hari`). Daring lagi → Plus. Lihat T3 |
| U11 | Pulihkan di ponsel kedua | Pasang di ponsel lain dengan akun Google yang sama, Akun › **Pulihkan pembelian** | Muncul pesan selesai dan Plus kembali; hak lintas perangkat dengan akun masuk yang sama | ✅ 7 Nov 2026 08:58: emulator kedua (5556) dengan akun Google yang sama, aplikasi dipasang dari Play, belum masuk akun aplikasi: Akun › Plus "Gratis"; setelah **Pulihkan pembelian** menjadi "Aktif sampai 7 Nov 2026 · Plus" dengan **Kelola di Play Store**. Tanpa masuk akun aplikasi, jadi hak mengikuti akun Google Play lewat `restorePurchases`. Pesan selesai (snackbar) tidak tertangkap uiautomator |
| U12 | Akun peninjau | Masuk dengan email/sandi peninjau | Seluruh fitur Plus terbuka tanpa batas waktu; tombol beli tetap bekerja; tidak ada pendaftaran mandiri | ➖ |
| U13 | Turun ke Gratis | Dari Plus ke Gratis (U6 atau U9) | Batas hanya menghalangi pekerjaan **baru** (proyek freelance ke-3, sumber notifikasi melebihi batas); data lama tetap terbaca dan bisa dihapus | ➖ |
| U14 | Keluar dan berganti akun | Keluar akun saat uji coba; masuk lagi; masuk akun lain | Keluar: Gratis; masuk lagi akun yang sama: melanjutkan sisa tanpa perpanjang; Plus yang **dibeli** tidak hilang karena keluar akun | ➖ sebagian: sesudah keluar akun, langganan yang dibeli saat masuk tetap dikenali (terlihat sebagai ditahan di U9), jadi `logOut` RevenueCat tidak dipanggil. Belum diuji: keluar saat uji coba, masuk lagi, berganti akun |
| U15 | Build rilis tidak punya sakelar klien | Pasang build rilis (§2b) | Tidak ada Menu pengembang; `PLAN_OVERRIDE` dan `ENTITLEMENT_OVERRIDES` tidak berpengaruh; `plus_launch_at` kosong: masuk akun = Plus (pra-peluncuran), tanpa akun = Gratis | ➖ (sebagian: Menu pengembang tidak ada di build rilis; sisanya setelah §2b langkah 4 dicabut) |
| U16 | Peristiwa analitik | Jalankan U2–U9 dengan DebugView Firebase | Peristiwa tanpa nominal, nama, atau isi (ADR-041 §3.12), mis. `trial_started` | ➖ |

### Yang diperhatikan di tiap skenario

- Harga di paywall **dari toko** (`priceString`), bukan teks tetap.
- Tidak ada layar kosong atau menggantung saat RevenueCat gagal; gagal membaca
  hak tidak menghalangi fitur gratis (ADR-041 §3.3).
- Log: `adb logcat | grep -i -E "Purchases|BillingClient"`.

## 4. Temuan

Tulis di sini (ID skenario, yang terjadi, bukti, tingkat S1–S3). Temuan yang
menghalangi rilis masuk ke TASK_LIST sebagai `T-24.n` baru.

**T1 (S3, desain; diputuskan KT-P19 opsi b dan diperbaiki T-24.21, menunggu uji perangkat): uji coba menutupi langganan yang ditahan atau habis.**
`resolvePlan` memeriksa uji coba **sebelum** `OnHold`
(`entitlement_resolver.dart`, urutan: cache Plus valid, pra-peluncuran, uji
coba, `OnHold`, Gratis). Akibatnya pengguna yang membeli saat uji coba masih
berjalan (U5) lalu pembayarannya gagal melihat status **Uji coba** tanpa ajakan
memperbaiki pembayaran, dan begitu uji coba selesai langsung Gratis. Teramati
6 Nov 2026 23:34: langganan bulanan uji habis karena perpanjangan ditolak,
Akun › Plus kembali ke "Sampai 30 Nov 2026. Tanpa kartu. Uji coba". Mungkin
diterima (Plus tetap terbuka selama uji coba), tetapi pemilik perlu memutuskan
apakah ajakan memperbaiki pembayaran harus tetap tampil. Belum ada tugas.

**T2 (S3, kemungkinan, perlu dikonfirmasi): "ditahan" tidak pernah berakhir
sesudah langganan kedaluwarsa di Play.** Teramati 7 Nov 2026 08:27–08:31: Play
sudah menandai langganan uji **kedaluwarsa** (tidak ada lagi opsi mengganti
metode bayar, hanya berlangganan ulang), tetapi Akun › Plus tetap menampilkan
"Langganan ditahan karena pembayaran belum berhasil. Perbaiki di Play Store.",
dua kali dibuka ulang. Penyebabnya diduga di `PlusSnapshot.onHold =
!isActive && billingIssueSince != null` dan `RevenueCatPlanSource.apply`:
cache hanya dihapus bila tidak aktif **dan tanpa** masalah pembayaran, sedangkan
RevenueCat tampaknya mempertahankan `billingIssueDetectedAt` pada hak yang sudah
habis. Akibatnya pengguna yang langganannya habis karena gagal bayar terus
diminta "memperbaiki" sesuatu yang tidak bisa diperbaiki; satu-satunya jalan
adalah berlangganan ulang. Perilakunya tetap seperti Gratis, jadi hanya pesan
yang menyesatkan. Konfirmasi: lihat pelanggan di dasbor RevenueCat (entitlement
kedaluwarsa dan masalah penagihan masih tercatat). Usul: batasi "ditahan" hanya
selama jendela penahanan Play, atau tampilkan ajakan **berlangganan lagi** bila
`willRenew` salah dan tanggal berakhir sudah lewat. Belum ada tugas.
*Bukti tambahan 7 Nov 2026 10:16:* data aplikasi emulator kedua dibersihkan
(tanpa cache lokal), lalu masuk Google dengan akun yang sama. Akun › Plus
langsung menampilkan "Langganan ditahan karena pembayaran belum berhasil",
padahal langganan lama itu sudah kedaluwarsa. Karena cache lokal kosong, status
itu **berasal dari server RevenueCat**, bukan dari cache aplikasi: RevenueCat
memang masih melaporkan hak tidak aktif **dengan** tanda masalah pembayaran.
Ini memperkuat dugaan T2 (belum dikonfirmasi lewat dasbor; ekspor CSV pelanggan
tidak memuat data penagihan sandbox).

**T3 (S2, terkonfirmasi di waktu nyata; diperbaiki di kode oleh T-24.19, menunggu U10 ulang di build berikutnya): tenggang luring 3 hari tidak bertahan
saat aplikasi dibuka luring sesudah akhir periode.** Terkonfirmasi tanpa menggeser jam: periode berakhir sekitar 09:32, dibuka luring 09:34 → Gratis. Teramati 7 Nov 2026 09:03–09:06
di emulator kedua (langganan Tahunan uji 30 menit aktif, dibaca daring 09:03):
mode pesawat dan buka ulang aplikasi dalam periode → Plus (benar). Jam
digeser +2 hari (9 Nov), masih luring, buka ulang → **Gratis**. Spek ADR-041
§3.3 menjanjikan Plus sampai `until + 3 hari`. Jam dikembalikan ke 7 Nov
(dalam periode), tetap luring → **tetap Gratis**, jadi cache hak sudah
**terhapus**, bukan sekadar dinilai kedaluwarsa; baru daring lagi
mengembalikannya. Log RevenueCat menunjukkan `NetworkError` saat membaca,
jadi SDK kemungkinan mengembalikan `CustomerInfo` lama yang dihitung tidak aktif
terhadap jam perangkat, lalu `RevenueCatPlanSource.apply` memanggil
`cache.clear()` (tidak aktif tanpa masalah pembayaran) dan melewati tenggang
aplikasi. Catatan kehati-hatian: menggeser jam perangkat bisa berbeda dari
berlalunya waktu nyata; konfirmasi dengan uji waktu nyata (daring, buka sekali
dalam periode, mode pesawat, tunggu lewat `until`, buka luring) di bawah.
Usul bila terkonfirmasi: jangan hapus cache bila pembacaan gagal atau data SDK
lebih tua dari `until` (pakai `requestDate` sebagai `lastVerifiedAt`, bukan
`now`), dan hanya hapus bila verifikasi server sesudah `until` melaporkan tidak
aktif.

_(temuan lain: belum ada)_



