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

*(diisi QA)*

| Ringkasan | Jumlah |
|---|---|
| Lulus | |
| Gagal S1 / S2 / S3 | |
| Diblokir | |
