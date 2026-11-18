# Harga investasi dari Google Sheet milik pengguna

## 1. Metadata

- **Decision ID:** ADR-051
- **Tanggal:** 2026-11-18
- **Fase roadmap:** Fase 33 (B-101, lihat TASK_LIST)
- **Status:** Accepted (18 Nov 2026; §3.4 tanpa pratinjau dan §3.1 perkiraan emas atas keputusan pemilik)
- **Cakupan:** `shared/investment` (sumber harga, tautan Sheet), `features/investment`
  (Hubungkan Google Sheet, pengambilan otomatis, Segarkan),
  `shared/auth` (izin tambahan `drive.file`), `features/premium` (pemicu baru),
  `features/data_portability` (cadangan), `core/foundation/entitlement`
- **Bergantung pada:** ADR-023, ADR-024, ADR-041, ADR-049
- **Rancangan produk:** [WEALTH_ASSETS.md](../../01-product/features/WEALTH_ASSETS.md)
  §5.4, keputusan 12, KT-A4

## 2. Konteks

Harga investasi tidak boleh diambil dari API pihak ketiga atau scraping
(lisensi data IDX tidak jelas, WEALTH_ASSETS §5.4). Pemilik memilih (17 Nov
2026) **Google Sheet milik pengguna** sebagai sumber: aplikasi membuatkan Sheet
privat berisi `GOOGLEFINANCE`, lalu membaca nilainya. KT-A4 (18 Nov 2026):
fitur ini **Plus seluruhnya**; Perbarui nilai manual tetap Gratis.

Spike T-33.0 (18 Nov 2026) membuktikan: izin `drive.file` lewat
`google_sign_in` 7.2 `authorizationClient` berhasil; Sheet bisa dibuat lewat
Sheets API; harga saham `IDX:<kode>` terbaca sebagai angka langsung sesudah
rumus ditulis, tanpa Sheet dibuka. **Emas tidak tersedia** di GOOGLEFINANCE
(`CURRENCY:XAUIDR`, `XAUUSD`, `COMEX:GCW00` galat); reksa dana Indonesia tidak
tercakup.

## 3. Keputusan

### 3.1 Cakupan otomatis: saham dengan kode, dan perkiraan emas

Hanya instrumen berjenis **Saham** yang punya **kode** (`Instrument.code`)
yang harganya diambil dari Sheet, dengan rumus
`=IFERROR(GOOGLEFINANCE("IDX:<KODE>","price"),"")`. Harga per lembar dalam
rupiah, langsung menjadi `unitPrice` (ADR-049 §3.4).

**Emas** (keputusan pemilik 18 Nov 2026) memakai **perkiraan** dari ETF emas
dan kurs, karena GOOGLEFINANCE tidak punya harga emas langsung
(`CURRENCY:XAUUSD`/`XAUIDR` galat di spike):

`=IFERROR(GOOGLEFINANCE("NYSEARCA:GLD","price")/<ONS_PER_LEMBAR>*GOOGLEFINANCE("CURRENCY:USDIDR")/31.1035,"")`

`<ONS_PER_LEMBAR>` adalah kandungan emas per lembar GLD (≈0,0919 ons, turun
pelan karena biaya pengelolaan), disimpan sebagai konstanta aplikasi
(`goldOuncesPerGldShare`) yang bisa diperbarui lewat Remote Config tanpa
rilis. Hasilnya rupiah per gram, untuk estimasi nilai pasar dan untung/rugi.
Valuasinya bersumber `sheetEstimate`, dan tampilannya selalu menyebut
**"perkiraan"** (mis. "Perkiraan dari harga emas dunia · 19.25") karena berbeda
beberapa persen dari harga spot dan bukan harga jual Antam. Pengguna yang
punya harga Antam bisa menimpanya lewat Perbarui nilai (isian manual menang,
§3.4).

**Reksa dana, obligasi, dan lainnya** tidak diambil otomatis. Barisnya tetap
dibuat di Sheet dengan kolom Harga kosong yang **boleh diisi pengguna
sendiri** (mis. dari aplikasi reksa dana); bila terisi angka, aplikasi
membacanya seperti harga saham.

### 3.2 Izin dan akun

- Butuh masuk dengan Google (ADR-023). Pengguna email/sandi atau tanpa akun
  tidak melihat pintu ini (tetap bisa Perbarui nilai manual). Akun tetap
  opsional (ADR-024).
- Izin tambahan **`drive.file`** diminta dari ketukan Hubungkan Google Sheet
  (bukan saat masuk): `authorizationForScopes` lebih dulu, lalu
  `authorizeScopes` bila belum ada. Scope ini hanya memberi akses ke berkas
  buatan aplikasi.
- Panggilan langsung dari perangkat ke `sheets.googleapis.com` dengan token
  pengguna; tanpa server Tanukonomy, tanpa kunci API.

### 3.3 Sheet

- Satu Sheet per pengguna, judul "Tanukonomy – Harga investasi", locale
  `en_US` (pemisah argumen koma, desimal titik).
- Kolom: `id` (id instrumen, kunci pencocokan), `Nama`, `Kode`, `Harga`.
  **Tanpa jumlah atau nominal kepemilikan.** Baris pertama judul kolom.
- Sinkron baris (tulis saja): instrumen Aktif baru ditambah, nama/kode yang
  berubah diperbarui; baris yang ditambahkan pengguna dan baris instrumen
  Selesai tidak dihapus aplikasi.
- ID Sheet disimpan lokal di `investment_sheet_link` (ikut cadangan). Sesudah
  pulihkan atau ganti akun Google, tautan diperiksa: Sheet tak terjangkau →
  pengguna ditawari membuat Sheet baru (ADR-024 §3.3).

### 3.4 Harga diambil otomatis saat layar investasi dibuka

Tanpa pratinjau (keputusan pemilik 18 Nov 2026): valuasi bukan transaksi,
tidak memindahkan uang dan tidak mengubah saldo, jadi harga terbaru langsung
dipakai.

- **Kapan:** saat segmen Investasi, rincian instrumen, atau CATAT › Investasi
  dibuka, bila pengambilan terakhir lebih dari **15 menit** lalu (cukup untuk
  harga yang bisa tertunda hingga 20 menit, dan hemat kuota). Juga tombol
  **Segarkan** kecil di segmen untuk mengambil sekarang.
- **Apa:** kolom Harga dibaca (`valueRenderOption=UNFORMATTED_VALUE`),
  dicocokkan lewat `id`; tiap angka disimpan sebagai valuasi `source: sheet`
  bertanggal hari ini. Baris kosong, teks, atau galat diabaikan. Saham yang
  masih kosong (rumus belum selesai dihitung) dicoba ulang dua kali berjeda 2
  detik.
- **Satu per hari:** valuasi Sheet hari yang sama menggantikan valuasi Sheet
  sebelumnya hari itu. Valuasi **manual** hari itu tidak ditimpa: isian
  pengguna selalu menang.
- **Tampilan:** penanda kesegaran menyebut sumbernya, mis. "Dari Google Sheet
  · 19.25"; selama pengambilan berjalan, angka lama tetap tampil (tanpa
  kerangka) dan nilai baru masuk dengan hitung naik.
- **CATAT › Investasi:** saran nominal (ADR-049 §3.11a) memakai harga yang
  baru diambil; pengguna tetap menyesuaikan nominal dan jumlah sebelum
  menyimpan beli/jual.
- **Perbarui nilai** manual tetap ada untuk instrumen non-saham dan untuk
  mengoreksi harga.

Tetap "mencatat, bukan melakukan": harga hanya dicatat dari Sheet milik
pengguna; aplikasi tidak membeli, menjual, atau mendistribusikan ulang harga.

### 3.5 Plus (KT-A4)

`PlusFeature.sheetPrices` dengan jatah Gratis 0. Pengguna Gratis melihat pintu
**Hubungkan Google Sheet** yang membuka paywall pemicu baru
`PaywallTrigger.sheetPrices`. Plus berakhir: Sheet dan tautannya tetap,
Ambil harga membuka paywall; Perbarui nilai manual tetap jalan.

### 3.6 Galat dan luring

Tanpa jaringan, izin dicabut, Sheet dihapus, atau kuota API habis: tidak ada
yang berubah, pesan jelas, dan pencatatan inti tetap luring (NFR-REL-001).

### 3.7 Analitik dan privasi

`valuation_sheet_synced` (`count_bucket` harga terbaca), `sheet_linked`.
Tanpa kode, nama, harga, atau nominal. PLAY_DATA_SAFETY dan kebijakan privasi
situs diperbarui: aplikasi membuat, menulis, dan membaca **satu berkas** di
Google Drive pengguna atas izinnya; isinya nama dan kode instrumen.

## 4. Opsi yang dipertimbangkan

| Opsi | Alasan |
|---|---|
| Emas dari `CURRENCY:XAUUSD` × USDIDR | Tidak bisa: XAUUSD galat di spike. |
| **Emas dari GLD × USDIDR, ditandai perkiraan** | Dipilih pemilik. |
| Sheet dipublikasikan sebagai CSV | Ditolak: tautan publik membuka daftar instrumen pengguna. |
| Pratinjau di Perbarui nilai sebelum tersimpan | Ditolak (pemilik): langkah tambahan tanpa manfaat, karena valuasi tidak menyentuh uang. |
| **Sheet privat, saham otomatis, lainnya diisi pengguna di Sheet** | Dipilih. |

## 5. Konsekuensi

- **Positif:** harga saham terkini tanpa API berbayar atau server dan tanpa
  langkah tambahan; data milik pengguna; saran nominal CATAT ikut segar.
- **Negatif:** hanya saham IDX yang tepat; emas hanya perkiraan; bergantung pada perilaku
  GOOGLEFINANCE yang tidak dijamin terdokumentasi untuk API (bisa berubah);
  butuh akun Google dan Plus.

## 6. Pertanyaan yang sudah dijawab (18 Nov 2026)

1. **Emas**: perkiraan dari GLD × USDIDR, ditandai "perkiraan" (§3.1).
   Reksa dana, obligasi, lainnya: baris kosong untuk diisi pengguna.
2. ~~Pratinjau wajib sebelum tersimpan~~: **dijawab pemilik 18 Nov 2026**,
   harga diambil dan disimpan otomatis saat layar investasi dibuka (§3.4).
3. **Pembacaan sesudah Sheet lama tidak dibuka** (sehari) belum diuji di
   spike; diuji di awal implementasi. Bila nilainya basi atau kosong,
   pengambilan menulis ulang rumus sebelum membaca. (Disetujui.)

## 7. Revisi

- 2026-11-18: dibuat (Proposed), §3.4 diubah (tanpa pratinjau), §3.1 emas
  dari GLD × USDIDR, lalu disetujui pemilik (Accepted).
