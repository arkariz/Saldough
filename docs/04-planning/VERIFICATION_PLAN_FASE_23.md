# Rencana Verifikasi — Fase 23 (Catat notifikasi multi-dompet, contoh, dan rutin lebih awal)

**Dibuat:** 23 Oktober 2026 · **Branch:** `worktree-notif-multi-wallet-recurring` (dari `origin/main`, belum digabung)
**Rujukan:** [ADR-042](../02-architecture/adr/0042-notifikasi-multi-dompet-sampel-dan-rutin.md),
[ADR-032](../02-architecture/adr/0032-catat-dari-notifikasi.md) (dasar fitur),
[ADR-035](../02-architecture/adr/0035-transaksi-rutin-rencana-dan-perkiraan.md),
[ADR-037](../02-architecture/adr/0037-otomasi-rutin-r3.md), TASK_LIST Fase 23
(T-23.1–T-23.4), [PLAY_DATA_SAFETY](../03-release/PLAY_DATA_SAFETY.md).

Pola sama dengan [VERIFICATION_PLAN_FASE_16](VERIFICATION_PLAN_FASE_16.md).
Android saja (Catat dari notifikasi tidak ada di iOS).

## Status pengujian otomatis (sudah dijalankan)

| Pemeriksaan | Hasil |
|---|---|
| `flutter analyze` (seluruh proyek) | Bersih, tanpa error, peringatan, atau info |
| `flutter test` (seluruh proyek) | 2067 uji lulus |
| Uji baru | `notification_multi_wallet_test` (aturan dompet, ambigu, `{from}`/`{to}`), `occurrence_record_date_test`, `adr042_serialization_test`, `notification_settings_bloc_adr042_test`, grup "rutin terikat ke pola" di `process_captured_notifications_test`, uji "Catat sekarang" di `recurring_pages_test` |
| Kompilasi Kotlin (`CaptureQueue`, `CaptureConfig`, listener, plugin) | **Belum**: tidak ada Gradle di lingkungan pengembangan. QA wajib membangun APK debug dulu. |
| Uji layar (widget) bagian Contoh notifikasi, Aturan dompet, Ikat ke rutin | **Belum ada**; hanya bloc dan domain yang diuji otomatis. Semua alur UI di bawah diuji manual. |

## Risiko utama

| # | Risiko | Kenapa penting |
|---|---|---|
| R1 | Notifikasi Jago tercatat ke dompet yang salah, atau transfer antar Kantong menjadi pengeluaran/pemasukan | Saldo salah; aturan domain 7 (transfer bukan pemasukan/pengeluaran) |
| R2 | Dompet ambigu ditebak, bukan masuk kotak masuk | Prinsip "tidak menebak" (permintaan pemilik 23 Okt 2026) |
| R3 | Pola terikat menautkan notifikasi ke rutin yang salah, atau mencatat tanpa tautan | Rutin terhitung dua kali; perkiraan salah |
| R4 | Contoh notifikasi menyimpan OTP, atau tidak terhapus saat dimatikan | Privasi; Keamanan Data Play |
| R5 | "Catat sekarang" memakai tanggal masa depan di saldo, atau periode keuangan salah | Saldo hari ini salah; ADR-038 `periodDateOf` |
| R6 | Data lama (sumber, rutin, pola) rusak setelah pembaruan | Semua field baru opsional; tanpa migrasi |
| R7 | Kotlin gagal dikompilasi atau layanan native berhenti | Tangkapan notifikasi hilang |

## Prasyarat data uji

- Dompet: **Jago Utama**, **Liburan**, **Tabungan** (ketiganya aktif), plus satu dompet lain (mis. BRI).
- Akses notifikasi sistem sudah diberikan, fitur Catat dari notifikasi nyala, aplikasi **Jago** terdaftar sebagai sumber (dompet utama Jago Utama).
- Tingkat otomatis diatur per skenario (Catat otomatis mati = tingkat 1; nyala = tingkat 2).
- Untuk notifikasi uji tanpa Jago asli: aplikasi pengirim notifikasi uji (mis. `adb shell cmd notification post -S bigtext -t "Jago" Tag "Pembayaran Rp25.000 ke KOPI dari Kantong Liburan berhasil"`) dari paket yang didaftarkan sebagai sumber; atau gunakan sampel asli bila ada. Bila notifikasi uji memakai paket lain, daftarkan paket itu sebagai sumber.
- Rutin uji: **Netflix** Rp65.000 tetap, pengeluaran, dompet Jago Utama, bulanan; **Listrik** kira-kira Rp300.000 (nominal kira-kira).
- Jam perangkat boleh dimajukan lewat `cmd alarm set-time` (`auto_time 0`), lalu dikembalikan.

## Daftar periksa perangkat

### A. Banyak dompet per aplikasi (T-23.1)

| # | Langkah | Harapan | Hasil |
|---|---|---|---|
| A1 | Setelan › Catat dari notifikasi › Jago › bagian "Dompet lain di aplikasi ini" › Tambah dompet | Muncul baris dengan pemilih dompet dan kolom kata pengenal; tombol Hapus | |
| A2 | Tambah dua aturan: Liburan = "Kantong Liburan", Tabungan = "Kantong Tabungan"; Simpan; buka lagi halaman | Kedua aturan tetap ada, kata pengenal utuh (pisahkan koma bekerja) | |
| A3 | Hapus satu aturan di tengah dua aturan yang kolomnya sudah diisi | Kolom aturan yang tersisa tidak tertukar isinya | |
| A4 | Kirim "Pembayaran Rp25.000 ke KOPI dari Kantong Liburan berhasil" | Draf/transaksi memakai dompet **Liburan** | |
| A5 | Kirim "Pembayaran Rp25.000 ke KOPI berhasil" (tanpa pengenal) | Dompet **Jago Utama** (bawaan) | |
| A6 | Kirim teks yang memuat "Kantong Liburan" **dan** "Kantong Tabungan" | Masuk kotak masuk dengan alasan dompet tidak dikenali; **tidak** tercatat otomatis walau tingkat 2; dompet kosong | |
| A7 | Buat pola dari contoh "Pindah Rp100.000 dari Kantong Liburan ke Kantong Tabungan": jenis Transfer, tandai Nominal, "Kantong Liburan" = Dari, "Kantong Tabungan" = Ke | Templat jadi `Pindah {amount} dari {from} ke {to}`; teks bantuan "Dari/Ke" tampil; bagian arah dan dompet lawan diganti keterangan; Simpan aktif | |
| A8 | Kirim notifikasi transfer dari A7 (tingkat 2) | Tercatat sebagai **transfer** Liburan → Tabungan; saldo Liburan turun, Tabungan naik, total tetap; tidak muncul sebagai pemasukan/pengeluaran di Analisis | |
| A9 | Kirim transfer dengan sisi tujuan tak dikenal ("ke Kantong Misteri") | Kotak masuk; dompet asal terisi, tujuan kosong; tidak tercatat | |
| A10 | Kirim transfer dengan kedua sisi sama ("dari Kantong Liburan ke Kantong Liburan") | Kotak masuk; kedua dompet kosong | |
| A11 | Tandai hanya "Dari" tanpa "Ke" di pembuat pola | Templat tidak sah; Simpan nonaktif dengan alasan | |
| A12 | Perbarui dari versi lama dengan sumber Jago yang sudah ada | Sumber lama terbaca, tanpa aturan dompet; perilaku lama tidak berubah | |

### B. Catat rutin lebih awal (T-23.2)

| # | Langkah | Harapan | Hasil |
|---|---|---|---|
| B1 | Rincian rutin Netflix › "Berikutnya" | Tiap kemunculan yang belum dilewati punya tombol **Catat sekarang** di bawah barisnya, di samping Lewati; tidak ada overflow di 360dp | |
| B2 | Ketuk Catat sekarang pada kemunculan berikutnya (bulan depan) | Transaksi tersimpan bertanggal **hari ini** (jam sekarang), nominal Rp65.000, saldo dompet turun hari ini; kemunculan itu berstatus tercatat | |
| B3 | Ketuk Catat sekarang pada kemunculan 3 bulan lagi | Sama seperti B2 (tanpa batas hari) | |
| B4 | Buka transaksi hasil B2 | Tertaut ke rutin dan tanggal kemunculan; tidak muncul lagi sebagai menunggu pada hari jatuh tempo | |
| B5 | Rutin kira-kira (Listrik): Catat sekarang | Membuka CATAT dengan nominal terisi dan tanggal hari ini; simpan menautkan ke kemunculan | |
| B6 | Kemunculan yang sudah dilewati | Tidak ada tombol Catat sekarang | |
| B7 | Cek periode keuangan: catat awal untuk kemunculan awal periode berikutnya | Transaksi dihitung ke periode sesuai `periodDateOf` (selisih ≤ 7 hari ikut tanggal kemunculan; lebih jauh ikut tanggal transaksi); Beranda dan Analisis konsisten | |
| B8 | Hapus transaksi dari B2 | Kemunculan kembali ke status belum tercatat dan saldo pulih | |
| B9 | Pengingat rutin: catat awal lalu tunggu waktu pengingat H−1 | Tidak ada pengingat untuk kemunculan yang sudah tercatat | |

### C. Ikat pola ke rutin (T-23.3)

| # | Langkah | Harapan | Hasil |
|---|---|---|---|
| C1 | Jago › Filter dan pola › bagian "Ikat ke rutin" | Hanya muncul bila ada rutin aktif dan pola (pengguna atau bawaan terverifikasi yang aktif); tiap pola punya pemilih rutin, bawaannya "Tidak terikat" | |
| C2 | Ikat pola "Netflix" ke rutin Netflix | Pemilih menampilkan nama rutin; tetap setelah keluar-masuk halaman | |
| C3 | Ikat pola yang sama ke rutin lain | Ikatan pindah (rutin pertama lepas) | |
| C4 | Ikat rutin Netflix ke pola kedua | Pola kedua menggantikan yang pertama | |
| C5 | Tingkat 2; kirim notifikasi cocok pola, nominal Rp65.000, satu kemunculan terbuka dalam 7 hari | Tercatat otomatis **dan tertaut** ke kemunculan (log tautan otomatis ada, bisa Lepaskan) | |
| C6 | Sama seperti C5 tetapi nominal Rp70.000 | Kotak masuk, badge **Rutin belum pasti**; tidak tercatat; tidak tertaut ke rutin lain | |
| C7 | Pola terikat ke rutin **kira-kira** (Listrik), nominal dalam ±10% | Kotak masuk (tidak dicatat otomatis); saran rutin tampil di item | |
| C8 | Notifikasi cocok pola terikat tetapi **tidak ada** kemunculan terbuka dalam 7 hari (semua tercatat/dilewati) | Kotak masuk, badge Rutin belum pasti | |
| C9 | Dua kemunculan terbuka dalam 7 hari (rutin mingguan) | Kotak masuk (tidak menebak) | |
| C10 | Tingkat 1 (Catat otomatis mati); notifikasi cocok pola terikat, nominal pas | Kotak masuk dengan saran rutin; Catat dari kotak masuk menautkan ke kemunculan itu | |
| C11 | Hapus pola yang terikat | Ikatan rutin terlepas (pemilih tidak lagi menampilkan rutin) | |
| C12 | Jeda rutin terikat lalu kirim notifikasi cocok | Tidak ditautkan ke rutin yang dijeda | |
| C13 | Pola yang belum terverifikasi (bawaan tebakan) | Tidak muncul di daftar ikatan; tidak pernah mengikat | |
| C14 | Notifikasi tanpa ikatan (perilaku lama ADR-037) | Tetap tertaut otomatis bila kecocokan tunggal ±3 hari dan nominal persis | |
| C15 | Cadangkan dan pulihkan (Akun › Data kamu) dengan rutin terikat | Ikatan ikut pulih | |

### D. Contoh notifikasi dan filter cepat (T-23.4)

| # | Langkah | Harapan | Hasil |
|---|---|---|---|
| D1 | Jago › Filter dan pola | Sakelar **Simpan contoh notifikasi** ada dan **mati** secara bawaan | |
| D2 | Nyalakan sakelar | Dialog pengungkapan (apa disimpan, 7 hari, bukan OTP, tidak dikirim ke server); Batal = tetap mati; Nyalakan = menyala | |
| D3 | Kirim beberapa notifikasi Jago (transaksi dan non-transaksi bermuatan angka, mis. promo "Diskon 50%") | Muncul di "Notifikasi terbaru", terbaru di atas, maksimum 10 ditampilkan | |
| D4 | Kirim notifikasi berisi kode OTP ("Kode OTP 123456, jangan bagikan") | **Tidak** muncul di daftar (tidak pernah disimpan) | |
| D5 | Kirim notifikasi tanpa angka | Tidak tersimpan | |
| D6 | Notifikasi dari aplikasi yang **tidak** terdaftar | Tidak tersimpan | |
| D7 | Ketuk **Jadikan filter** pada sebuah contoh | Lembar frasa terbuka; kata berangka tidak ditawarkan; ketuk kata menyusun frasa; bisa diketik; keyboard tidak menutup tombol; Tambah menambahkan ke filter (tampil sebagai chip) | |
| D8 | Tambah frasa yang sudah ada | Tidak ganda | |
| D9 | Ketuk **Buat pola** pada contoh | Pembuat pola terbuka dengan teks contoh terisi; simpan menambah pola | |
| D10 | Matikan sakelar | Semua contoh terhapus segera; nyalakan lagi tidak memunculkan yang lama | |
| D11 | Hapus sumber Jago | Contoh Jago terhapus | |
| D12 | Lewatkan 7 hari (majukan jam) lalu buka daftar | Contoh lebih lama dari 7 hari tidak tampil | |
| D13 | Kirim lebih dari 50 notifikasi dari satu aplikasi | Hanya 50 terbaru yang tersisa | |
| D14 | Notifikasi yang sama diposting ulang | Contoh tidak ganda | |
| D15 | Sakelar mati: apakah ada teks notifikasi non-transaksi yang tersimpan (cek berkas `files`/SharedPreferences `notification_capture_queue`) | Tidak ada kunci `samples` yang terisi | |
| D16 | Teks sampel tidak ikut ke Gemini atau cadangan | Cadangan `.tkbak` tidak memuat teks contoh | |

### E. Regresi

| # | Langkah | Harapan | Hasil |
|---|---|---|---|
| E1 | Catat dari notifikasi dengan satu dompet (sumber lama, tanpa aturan dompet) | Perilaku identik dengan sebelum Fase 23 | |
| E2 | Pola lama (pengguna dan bawaan), dedup, OTP, tingkat otomatis, "mungkin ganda" | Tidak berubah | |
| E3 | Segmen Rutin: Catat satu ketuk, Catat semua, Lewati, Jeda, Belum terjadi | Tidak berubah | |
| E4 | Kotak masuk: badge alasan lama tetap tampil; item lama (tanpa `patternId`) terbaca | Tidak ada crash | |
| E5 | Mode gelap dan bahasa Inggris untuk semua teks baru | Teks `en` lengkap, kontras cukup, tidak terpotong di 360dp | |
| E6 | Ekspor spreadsheet dan cadangan | Tidak terpengaruh | |
| E7 | Pembaruan dari build sebelumnya (`adb install -r`) dengan data lama | Sumber, pola, rutin lama terbaca; tanpa migrasi | |

## Keterbatasan yang diketahui (bukan temuan)

- Ikatan rutin ke notifikasi hanya terlihat di halaman sumber, belum di rincian rutin.
- Pola `{from}`/`{to}` baru diuji dengan teks buatan; format notifikasi Jago asli belum dicocokkan. Bila format berbeda, catat teks aslinya (samarkan nominal dan nomor rekening) sebagai bahan pola bawaan.
- Contoh notifikasi menyimpan semua notifikasi bermuatan angka dari sumber terdaftar (bukan hanya yang gagal filter).
- Pengungkapan jelas, kebijakan privasi situs (`tanukonomy-web`), dan formulir Keamanan Data belum diperbarui untuk contoh notifikasi; wajib sebelum rilis publik.

## Cara melaporkan

Tulis tiap temuan dengan: nomor langkah, build/commit, langkah reproduksi, hasil nyata vs harapan, tangkapan layar, dan keparahan (S1 data/uang salah atau crash; S2 alur utama terganggu; S3 kosmetik/teks). Teks notifikasi asli **wajib disamarkan** (nominal, saldo, nomor rekening) sebelum dilampirkan.

## Hasil

Diuji 23–24 Okt 2026 pada build `c83f3602` (`0.9.0+15`), emulator Android 15 (`Slim_Pixel`, x86_64). Atas permintaan pemilik, pengujian difokuskan ke **alur inti** (R1–R4); baris yang tidak masuk alur inti tidak dikerjakan dan ditandai "tidak diuji". Data uji disuntik lewat cadangan buatan (sumber `com.android.shell` berlabel "Jago (uji)"; dompet Jago Utama, Liburan, Tabungan; pola dan rutin Netflix/Listrik), jadi pembuatan lewat UI pembuat pola tidak dicoba.

### Otomatis dan build

| Pemeriksaan | Hasil |
|---|---|
| `flutter analyze` | 1 info (`avoid_redundant_argument_values`, `notification_settings_bloc_adr042_test.dart:99`); rencana menyebut bersih. S3. |
| `flutter test` | 2067 lulus, 0 gagal |
| Kompilasi Kotlin / APK debug (R7) | Lulus; layanan native menerima konfigurasi sumber, antrean, dan contoh |
| E7 pembaruan `adb install -r` dengan data lama | Lulus. Catatan lingkungan: satu ANR "failed to complete startup" pada peluncuran pertama (emulator terbebani), tidak berulang |

### Daftar periksa perangkat

| # | Hasil |
|---|---|
| A1, A2 | Lulus: baris aturan dompet (pemilih, kata pengenal, Remove); dua aturan tetap utuh setelah halaman dibuka ulang |
| A4 | Lulus: "…dari Kantong Liburan" tercatat otomatis ke Liburan |
| A5 | Lulus: tanpa penanda tercatat ke Jago Utama (bawaan) |
| A6 | Lulus: dua dompet cocok, kotak masuk "Wallet not recognized", tidak tercatat |
| A8 | Lulus: tercatat sebagai transfer Liburan → Tabungan, total tetap, bukan pemasukan/pengeluaran |
| A9, A10 | Lulus: sisi tujuan tak dikenal / dompet sama, kotak masuk, tidak tercatat. Badge "Type unclear" kurang tepat (F23-1) |
| B1 | Lulus: "Record now" di tiap kemunculan akan datang |
| B2 | Lulus: transaksi bertanggal hari ini, Rp65.000, saldo Jago Utama Rp4.870.000; kemunculan 25 Nov masuk Recorded |
| B8 | Lulus: hapus transaksi, kemunculan kembali ke belum tercatat |
| C1 | Lulus: bagian "Bind to a recurring item" tampil dengan pemilih per pola (Netflix, Listrik, Pindah Kantong "Not bound") |
| C2 | Lulus: ikatan Netflix dan Listrik tetap setelah halaman dibuka ulang |
| C5 | Lulus: nominal pas, tercatat otomatis dan tertaut (25 Okt masuk Recorded) |
| C6 | Lulus: nominal beda, kotak masuk "Recurring unclear", tidak tertaut |
| C7 | Lulus: rutin kira-kira, kotak masuk, saran "Matches recurring Listrik · 27 Okt" |
| C8 | Sebagian: kotak masuk dan tidak tertaut, tetapi badge "May already be recorded" (F23-2) |
| D1 | Lulus: sakelar "Save notification samples" mati secara bawaan |
| D2 | Lulus: dialog pengungkapan (apa yang disimpan, 7 hari, OTP tidak pernah, tidak ke server) |
| D3 | Lulus dengan catatan: daftar "Recent notifications" terbaru di atas setelah halaman dibuka ulang (F23-5) |
| D4 | Lulus: notifikasi OTP **tidak** tersimpan (diperiksa langsung di penyimpanan native) |
| D5 | Lulus: notifikasi tanpa angka tidak tersimpan |
| D7 | Lulus: lembar frasa (kata berangka tidak ditawarkan), "diskon" masuk filter dan tersimpan ke konfigurasi native setelah Save |
| D10 | Lulus: sakelar dimatikan, `saveSamples:false` dan kunci `samples` terhapus (dalam hitungan detik; terlihat lag emulator) |
| E1 | Lulus (tercakup A5) |
| E7 | Lulus |
| A3, A7, A11, A12, B3–B7, B9, C3, C4, C9–C15, D6, D8, D9, D11–D16, E2–E6 | **Tidak diuji** (di luar fokus alur inti; sebagian butuh pembuat pola lewat UI, jam perangkat, atau perangkat lain) |

### Ringkasan

| Ringkasan | Jumlah |
|---|---|
| Lulus | 26 baris (A1, A2, A4, A5, A6, A8, A9, A10, B1, B2, B8, C1, C2, C5, C6, C7, D1, D2, D3, D4, D5, D7, D10, E1, E7, plus build/test otomatis) |
| Sebagian | 1 (C8) |
| Gagal S1 / S2 / S3 | **0 / 0 / 5** |
| Tidak diuji | sisanya |

### Temuan

| ID | Langkah | Sev | Ringkas |
|---|---|---|---|
| F23-1 | A9, A10 | S3 | Alasan kotak masuk "Type unclear" untuk transfer yang tujuannya tak dikenal atau sama dengan asal. Harapan: alasan dompet. Hasil transfer (tidak tercatat) sudah benar. |
| F23-2 | C8 | S3 / keputusan pemilik | Notifikasi cocok pola terikat tanpa kemunculan terbuka berbadge "May already be recorded" (duplikat dideteksi lebih dulu), bukan badge rutin belum pasti. |
| F23-3 | analyze | S3 | 1 info di berkas uji baru; rencana menyatakan bersih. |
| F23-4 | Plan › Recurring | S3 / belum pasti | Daftar rutin sempat menampilkan Netflix 25 Okt "Later" saat rincian rutinnya sudah mencatatnya Recorded. Mungkin lag emulator; ulangi di perangkat nyata. |
| F23-5 | D2, D3 | S3 | Tepat setelah sakelar contoh dinyalakan (dan setelah menyetujui dialog), sakelar masih tampil **mati** dan "Recent notifications" tidak muncul walau penyimpanan sudah menyala; baru benar setelah halaman dibuka ulang. Pengguna bisa mengira gagal dan mengulang. |
| F23-6 | C1 | S3 / keputusan pemilik | Pemilih "Bind to a recurring item" untuk pola pengeluaran (Netflix) menawarkan rutin **Gaji (pemasukan)**. Belum ada aturan tertulis bahwa jenis harus sama; usul: saring daftar menurut jenis pola. |

Catatan: teks pola harus berawalan judul notifikasi ("Jago …") karena yang dicocokkan adalah "judul\nisi". Perilakunya benar, namun membingungkan bila pola diketik tangan; pembuat pola di UI membuatnya otomatis. Pengamatan Fase 22 yang masih ada: halaman "Data dipulihkan" tetap meminta izin notifikasi walau sudah aktif.

### Rekomendasi

**Layak digabung dengan catatan.** Alur inti lulus tanpa temuan S1 atau S2: dompet dipilih benar atau tidak ditebak (R1, R2), transfer tidak pernah menjadi pemasukan atau pengeluaran, penautan rutin hanya bila pasti (R3), dan contoh notifikasi tidak menyimpan OTP atau teks tanpa angka serta terhapus saat dimatikan (R4). Sebelum rilis publik: (1) putuskan F23-2 dan F23-6; (2) perbaiki F23-5; (3) perbarui Keamanan Data Play dan kebijakan privasi untuk contoh notifikasi (sudah tercatat sebagai keterbatasan); (4) uji layar otomatis untuk Aturan dompet, Ikat ke rutin, dan Contoh notifikasi masih belum ada; (5) uji baris yang ditandai "tidak diuji" saat verifikasi perangkat nyata.
