# Catat dari notifikasi: penangkap native, pola, tingkat otomatis, kotak masuk

## 1. Metadata

- **Decision ID:** ADR-032
- **Tanggal:** 2026-10-01
- **Fase roadmap:** Fase 11 (Catat Cerdas), milestone M4, T-11.17 s.d. T-11.21
- **Status:** Accepted
- **Cakupan:** `features/record` (`capture/notification/`), `features/home`
  (port ringkasan), `features/account` (entri setelan), `lib/app/` (pemicu
  pemrosesan), `android/app/src/main/kotlin/.../notificationcapture/`
- **Bergantung pada:** ADR-027 (bukti teks, interpreter, draf), ADR-029
  (penyusun draf, paket bahasa), ADR-030 (rute bertipe, `LedgerChanges`),
  ADR-012 (urutan tulis buku besar)
- **Mengubah sebagian:** ADR-027 §3.4 dan §7; aturan 8 `.claude/CLAUDE.md`

## 2. Konteks

ADR-027 menyiapkan `CaptureSource.notification`: notifikasi bank/e-wallet
"cukup butuh penangkap baru". Keputusan pemilik 1 Okt 2026 menambah hal yang
lebih besar dari penangkap:

1. Pengguna memilih **mode penyampaian**: *pengingat + kotak masuk* atau
   *kotak masuk saja*.
2. Pengguna memilih **tingkat otomatis** (tiga tingkat). Draf yang lengkap
   dan tidak ragu boleh langsung tercatat tanpa membuka CATAT.
3. Draf hasil Gemini mengikuti aturan tingkat yang sama.
4. Teks notifikasi boleh dikirim ke Gemini bila aturan ragu, sama seperti
   suara (ADR-027 §3.5).
5. Pengguna sendiri yang memilih **aplikasi yang didengarkan**, **filter
   notifikasinya**, dan **dompetnya**. Filter adalah **whitelist** (keputusan
   pemilik 1 Okt 2026): hanya notifikasi yang memuat salah satu frasa filter
   yang ditangkap. Aplikasi menyediakan filter bawaan berisi frasa yang pasti
   transaksi, jadi promosi tidak perlu disaring terpisah.
6. Ada **pola bawaan** per aplikasi, dan pengguna bisa **menambah pola
   sendiri**.
7. Pemrosesan terjadi **saat aplikasi hidup atau dibuka**, bukan di isolate
   latar.
8. Transaksi yang tercatat otomatis dikenali lewat daftar **"Tercatat
   otomatis"** 7 hari dengan Tinjau/Batalkan; skema `Transaction` tidak
   berubah.

iOS tidak mengizinkan aplikasi membaca notifikasi aplikasi lain, jadi fitur
ini **khusus Android**.

## 3. Keputusan

### 3.1 Penangkap native dan antrean serah-terima

`TransactionNotificationListener` (Kotlin, `NotificationListenerService`)
berjalan walau aplikasi tertutup. Untuk setiap notifikasi:

- dibuang bila paketnya tidak terdaftar sebagai sumber aktif, notifikasinya
  *ongoing* atau ringkasan grup, tidak berisi angka, atau tidak memuat satu pun
  frasa filter sumber (**whitelist**; filter kosong = tidak ada yang
  ditangkap). Sumber baru diisi filter bawaan `defaultNotificationKeywords`
  ("pembayaran berhasil", "dana masuk", "transfer masuk", ...), yang bisa
  diubah dan dikembalikan pengguna. Tidak ada daftar hitam promosi: teks yang
  lolos filter dianggap transaksi;
- **selalu dibuang bila tampak seperti OTP/kode verifikasi**, apa pun setelan
  pengguna — kode rahasia tidak pernah disimpan;
- sisanya dimasukkan ke antrean serah-terima native (maks. 50, dedup kunci +
  isi), lalu diteruskan ke Dart lewat `EventChannel` bila mesin Flutter hidup,
  atau — bila tidak hidup dan mode pengingat aktif — memunculkan pengingat
  generik ("Transaksi dari BRImo tertangkap — ketuk untuk mencatat").

Setiap tangkapan yang lolos membawa **ikonnya** (permintaan pemilik 1 Okt
2026): ikon besar notifikasi (sering logo bank atau merchant), atau ikon
aplikasi pengirim bila tidak ada, dirender PNG 96 px. Ikon disimpan bersama
item kotak masuk dan log *Tercatat otomatis* (ikut kedaluwarsa 7 hari) dan
tampil di kartunya, lalu ikut ke transaksi yang tercatat (§3.10). Sampel
debug tidak menyimpan ikon.

Native tidak menafsirkan apa pun dan tidak menyentuh Hive. **Dart satu-satunya
penulis** penyimpanan aplikasi: antrean dibaca, diproses, lalu di-*ack*.
Pemicu pemrosesan: aplikasi dibuka, kembali ke depan (*resume*), event native,
dan ketukan pengingat.

### 3.2 Sumber notifikasi

`NotificationSource { packageName, appLabel, keywords, walletId?, enabled }`.
Daftar aplikasi diambil lewat kueri intent `MAIN/LAUNCHER` (tanpa
`QUERY_ALL_PACKAGES`, yang dibatasi Play). Dompet sumber mengisi dompet draf;
untuk transfer, notifikasi keluar = sumber → lawan, masuk = lawan → sumber.

### 3.3 Urutan tafsir: pola → aturan → Gemini

1. **Pola** pengguna untuk paket itu, lalu pola bawaan. Pola = templat teks
   literal dengan penanda `{amount}` (wajib), `{note}` (opsional), dan `{*}`
   (bagian berubah-ubah: tanggal, jam, no. referensi, saldo), plus jenis tetap,
   kategori opsional, dan dompet lawan transfer opsional. Pencocokan **utuh dan
   ketat** (tanpa beda huruf besar-kecil, spasi dinormalkan): pola yang tidak
   pas tidak cocok, alih-alih salah membaca. Pola adalah satu
   `TransactionInterpreter` lagi yang mengeluarkan kutipan; resolver tetap
   memvalidasi nominal (ADR-027 §3.3 tidak berubah).
2. Tidak ada pola yang cocok → `CaptureDraftComposer` (ADR-029 §3.4) dengan
   interpreter aturan notifikasi: nominal sesudah kata saldo/limit, nomor
   rekening tersamar, nomor referensi, dan jam dikeluarkan dari calon nominal;
   jenis dari kata arah notifikasi (masuk/keluar). Tanpa kata arah → issue
   `kindUnclear` (khusus notifikasi; suara tetap bawaan pengeluaran).
3. Aturan ragu → Gemini, dengan data yang sama seperti ADR-027 §3.5 butir 4;
   `origin` (nama paket) tidak dikirim.

Urutan nyata (temuan implementasi 1 Okt 2026): pola pengguna dan pola bawaan
**terverifikasi** → aturan/Gemini → pola bawaan **belum terverifikasi** hanya
bila aturan belum yakin. Tanpa urutan ini pola tebakan menutup draf aturan
yang sebenarnya yakin.

**Bahasa notifikasi dideteksi dari teksnya** (kosakata notifikasi paket mana
yang paling banyak cocok; seri → bahasa aplikasi), bukan dari bahasa aplikasi:
pengguna berantarmuka Inggris tetap menerima "Pembayaran Rp25.000" dari bank
Indonesia, dan pemisah ribuan ikut bahasanya.

Pola bawaan ada di kode (`built_in_notification_patterns.dart`); setiap pola
wajib punya uji dari contoh teks, dan pola yang belum dicocokkan dengan sampel
asli diberi tanda di kode. Pola bawaan bisa dinonaktifkan dan digandakan,
tidak disunting. Pola pengguna dibuat dari contoh (item kotak masuk atau teks
yang ditempel) dengan menandai kata — tanpa regex.

### 3.4 Tingkat otomatis

| Tingkat | Dicatat otomatis bila |
|---|---|
| 1. Tinjau semua (bawaan) | tidak pernah |
| 2. Otomatis bila lengkap | `RecordDraft.isConfident`, dompet terisi (dua-duanya untuk transfer), dan kategori terisi (selain transfer) |
| 3. Otomatis bila nominal & dompet yakin | `RecordDraft.isConfident` dan dompet terisi; kategori boleh kosong |

Di layar, tiga tingkat ini tampil sebagai **dua sakelar** (1 Okt 2026, review
UX): *Catat otomatis* (mati = tingkat 1, nyala = tingkat 2) dan, bila nyala,
*Walau kategori belum terbaca* (tingkat 3). Model domain tetap tiga tingkat.

Di semua tingkat, tangkapan yang **mungkin ganda** (dompet + jenis + nominal
yang sama di hari yang sama di buku besar, atau dua tangkapan bernominal sama
dalam 10 menit) selalu masuk kotak masuk. Draf Gemini diperlakukan sama dengan
draf aturan (keputusan pemilik).

### 3.5 Satu jalur tulis

Pencatatan otomatis memanggil **use case yang sama** dengan CATAT,
`RecordTransaction` (urutan tulis ADR-012, sinyal `LedgerChanges` ADR-030
§3.4). Tidak ada repository atau jalur simpan lain. Ini **mengubah ADR-027
§3.4** untuk sumber notifikasi: pada tingkat 2/3, draf yang lolos kebijakan
tersimpan tanpa formulir. Aturan 8 tetap berlaku untuk pencatatan manual: tidak
ada formulir pencatatan selain CATAT; draf yang perlu ditinjau selalu membuka
CATAT.

### 3.6 Kotak masuk, log, dan retensi

- **Perlu ditinjau**: draf + teks bukti + sumber + waktu. Catat → CATAT terisi;
  item dihapus hanya bila transaksi benar-benar tersimpan. Abaikan → dihapus.
  Buat pola → pembuat pola dari contoh ini.
- **Tercatat otomatis**: id dan tanggal transaksi, nominal, sumber, waktu.
  Tinjau → rincian transaksi; Batalkan → `RecordTransaction.delete`.
- Keduanya **kedaluwarsa 7 hari**. Teks bukti disimpan di perangkat hanya
  selama item menunggu, lalu ikut terhapus. Ini **mengubah ADR-027 §7**
  ("jangan simpan teks bukti") untuk sumber notifikasi saja.
- Build debug punya ring buffer native (maks. 20) berisi teks mentah dari paket
  terdaftar sebelum filter, untuk menyusun pola dan uji dari sampel
  asli. Tidak ada di build rilis.

### 3.7 Mode penyampaian

Kotak masuk selalu ada, jadi mode penyampaian tampil sebagai satu sakelar
*Kabari lewat notifikasi* (review UX 1 Okt 2026):

- Mati (`inboxOnly`): tanpa notifikasi dari Tanukonomy; kartu di Beranda.
- Nyala (`reminderAndInbox`): notifikasi Tanukonomy per tangkapan ("Cek
  Rp25.000 dari BRImo" / "Tercatat Rp25.000 · BRImo — ketuk untuk melihat"),
  plus kartu Beranda. Memilih mode ini meminta izin `POST_NOTIFICATIONS`
  (Android 13+). Teks pengingat generik native dikirim Dart dalam bahasa
  aplikasi (ADR-028), bukan bahasa HP.

### 3.8 Persetujuan

Sebelum membuka setelan akses notifikasi sistem, aplikasi menampilkan
pengungkapan jelas (kebijakan Data Pengguna Google Play): apa yang dibaca,
bahwa hanya aplikasi yang dipilih yang diproses, bahwa teks yang ragu bisa
dikirim ke Gemini, dan retensi 7 hari.

### 3.9 Tampilan (review UX 1 Okt 2026)

Kosakata antarmuka memakai **"cek"**, bukan "tinjau"; istilah teknis
(tingkat, mode penyampaian, didengarkan, CATAT sebagai kata kerja) tidak
tampil ke pengguna.

- **Setelan**, urut dari yang wajib ke yang opsional: kartu utama (sakelar
  aktif + keterangan + status izin), kartu peringatan izin bila belum
  diberikan, baris *Kotak masuk*, bagian *Aplikasi* (baris ringkas: nama +
  dompet; peringatan bila dompet atau filter kosong), lalu satu kartu *Saat
  transaksi tertangkap* berisi sakelar §3.4 dan §3.7. Bagian debug paling
  bawah.
- **Satu aplikasi**: sakelar *Dengarkan aplikasi ini*, pemilih dompet yang
  sama dengan CATAT, lalu *Filter dan pola* yang terlipat (terbuka sendiri
  bila filter kosong). Simpan di bilah bawah.
- **Pembuat pola**: pilih penanda (*Nominal*/*Catatan*/*Abaikan*) lalu ketuk
  kata — bukan ketuk berulang untuk berganti peran; jenis memakai
  *Keluar/Masuk/Transfer* seperti CATAT (+ arah bila transfer); templat mentah
  terlipat di *Sunting templat*.
- **Kotak masuk**: nominal berwarna sesuai jenis, catatan draf di atas teks
  notifikasi (redup, maks. 2 baris); aksi utama *Abaikan*/*Catat*, *Buat pola*
  di menu ⋮.

### 3.10 Ikon di riwayat transaksi (keputusan pemilik 1 Okt 2026)

Transaksi dari notifikasi menampilkan **dua ikon**: ikon kategori sebagai
ikon utama dan ikon notifikasi sebagai lencana kecil di sudut kanan
bawahnya (pemilik memilih susunan ini dari tiga opsi).

- **Skema:** `Transaction.sourceIconId: String?` (field tambahan, opsional;
  dokumen lama tanpa field ini tetap terbaca, tanpa migrasi). Isinya hash
  isi PNG; PNG-nya disimpan **sekali per ikon** di `source_icon/<id>`, jadi
  logo yang sama untuk ratusan transaksi hanya satu salinan. Item kotak
  masuk dan log *Tercatat otomatis* menyimpan id yang sama, bukan bytes.
- **Jalur:** pemroses menyimpan ikon saat tangkapan masuk; tingkat otomatis
  menulis `sourceIconId` lewat `RecordTransaction`; *Catat* dari kotak masuk
  membawa id lewat draf ke CATAT; menyunting transaksi mempertahankannya.
- **Tampilan (`TransactionIcon`, dipakai Riwayat, Beranda, rincian dompet
  dan anggaran, rincian transaksi, kotak masuk):** kotak 44 px berwarna
  jenis (satu-satunya penanda warna per baris, ADR-020 §3.3) kini berisi
  **ikon kategori** bila ada — ikon jenis hanya untuk transfer dan transaksi
  tanpa kategori. Lencana sumber 22 px, sudut membulat, cincin warna kartu
  2 px supaya logo berwarna apa pun terpisah dari kotak; lebar kolom ikon
  tidak bertambah. Lencana diabaikan pembaca layar (judul dan dompet sudah
  menjelaskan transaksi).
- Ikon yatim (transaksinya dihapus) tidak dibersihkan dulu; ukurannya kecil
  dan terdeduplikasi.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Isolate Flutter latar dari layanan notifikasi.** Seketika walau
  aplikasi tertutup, tetapi dua isolate bisa menulis Hive bersamaan.
- **Opsi B — Native menampung, Dart memproses saat hidup/dibuka (Dipilih).**
- **Opsi C — Pola per bank saja tanpa interpreter generik.** Rapuh terhadap
  format baru dan aplikasi yang tidak dikenal.

## 5. Analisis konsekuensi

### Opsi A
Butuh kunci penulis tunggal lintas isolate; risiko data ganda atau rusak
bertentangan dengan "ketepatan angka lebih penting daripada kecepatan".

### Opsi B (Dipilih)
Tidak ada tangkapan yang hilang, satu penulis Hive. Kelemahan: bila aplikasi
tertutup penuh, pencatatan terjadi saat dibuka berikutnya (pengingat generik
menjembatani).

### Opsi C
Pola tetap dipakai sebagai lapis pertama (paling tepat), tetapi interpreter
generik + Gemini menangkap sisanya.

## 6. Konsekuensi

### Yang menjadi lebih mudah
- Menambah dukungan aplikasi = satu pola + uji, tanpa rilis bila pengguna
  membuatnya sendiri.

### Yang menjadi lebih sulit
- Transaksi bisa tercatat tanpa ditinjau; daftar "Tercatat otomatis" dan
  Batalkan menjadi penyeimbangnya.
- Formulir Keamanan Data dan kebijakan privasi bertambah (isi notifikasi).

### Risiko yang diterima
- Android 13+ "setelan terbatas" memblokir akses notifikasi untuk APK
  sideload (Play dan `adb install` aman).
- Beberapa pabrikan menghentikan layanan pendengar; layanan meminta
  `requestRebind` saat terputus.

## 7. Catatan implementasi

- Jangan tambah `QUERY_ALL_PACKAGES`.
- Jangan simpan atau proses notifikasi OTP.
- Jangan pernah menaruh `double` di jalur nominal; nominal dari pola tetap
  lewat `SpokenAmountParser`.
- Pemrosesan *single-flight* dan idempoten (id yang sudah diproses dicatat),
  supaya crash sebelum *ack* tidak mencatat dua kali.

## 8. Kriteria peninjauan ulang

- Sinkronisasi (B-7) membutuhkan penanda asal permanen di `Transaction`.
- Pengguna sering membatalkan transaksi otomatis (kebijakan terlalu longgar).

## 9. Artefak terkait

### Dokumentasi
- ADR-027, ADR-029, ADR-030
- `docs/01-product/prd-saldough-2.0.md` FR-NOT-001
- `docs/04-planning/PLAY_DATA_SAFETY.md`

### Rujukan kode
- `lib/features/record/domain/capture/notification/`
- `lib/features/record/data/capture/notification/`
- `lib/features/record/presentation/capture/notification/`
- `android/app/src/main/kotlin/com/arkarizdev/tanukonomy/notificationcapture/`

---

**Penulis keputusan:** Claude (agen), atas keputusan pemilik
**Ditinjau oleh:** pemilik
**Tanggal disetujui:** 2026-10-01
**Status implementasi:** berjalan (T-11.17 s.d. T-11.21)
