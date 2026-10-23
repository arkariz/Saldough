# QA Fase 22 (Ekspor dan cadangan manual): progres

Diperbarui 23 Okt 2026, pengujian emulator selesai (dilanjutkan dari jeda 22 Okt). Berkas ini tidak di-commit.

## Cakupan dan lingkungan

- Acuan: artefak "Serah Terima Fase 22" (rencana uji T-22.7, skenario 1–20), `docs/01-product/features/EXPORT_BACKUP.md`, ADR-040.
- Branch `claude/adr-ekspor-cadangan` sudah di-merge ke `main` (PR #60, branch remote dihapus). Yang diuji: `origin/main` commit `0152d09d` (T-22.1–T-22.6). Worktree ini berada di commit itu (detached).
- Perangkat: **emulator Android 15** (`emulator-5554`, 1080x2340). Prasyarat "dua ponsel Android + satu iOS" tidak terpenuhi: ponsel B disimulasikan dengan data aplikasi kosong, iOS tidak bisa diuji.
- Build: Flutter 3.47.5 (`.fvmrc`), `flutter build apk --debug --target-platform android-x64`. Perubahan `minSdk` oleh tooling sudah dikembalikan.
- Otomatis: `flutter analyze` **bersih**; `flutter test` **2028 lulus, 1 gagal** (lihat Temuan T1).

## Hasil per skenario

| # | Prio | Status | Catatan |
|---|---|---|---|
| 1 | P0 | **Belum** | Pulihkan lewat onboarding di data kosong. Tautan "Sudah punya cadangan? Pulihkan" tampil di slide 1. Bulat-balik identik sudah terbukti lewat Akun (lihat #2, #3). |
| 2 | P0 | **Lulus** | Pratinjau, peringatan penggantian, data diganti seluruhnya (6 → 5 transaksi). Semua layar identik dengan keadaan saat cadangan dibuat (Dompet, Riwayat, Rencana, Anggaran, Rutin, Beranda). |
| 3 | P0 | **Lulus** | Kembalikan data sebelum pemulihan: keadaan 6 transaksi kembali persis (total Rp13.696.938). |
| 4 | P0 | **Lulus (sampel kecil)** | Henti-paksa (`am force-stop`) setelah menekan "Ganti data": jeda 0 dtk → data lama utuh; 0,5 dtk → data baru utuh; 1,2 dtk → data baru utuh. Tidak ada data campuran. Satu percobaan gagal di navigasi skrip, tidak dihitung. Emulator tidak bisa memilih jendela waktu persis. |
| 5 | P0 | **Lulus** | 8 varian ditolak, data tidak berubah: bukan cadangan, byte terbalik, checksum salah, terpotong, kosong, JSON lain, versi lebih baru (pesan khusus "Cadangan dari versi yang lebih baru"), dompet tidak ada (R-3). Pesan sesuai §9. |
| 6 | P0 | **Belum** | Ruang penyimpanan hampir penuh. |
| 7 | P0 | **Lulus** | xlsx: jumlah Arus per Awal periode = Selisih di Beranda (Rp7.696.938). Transfer Arus 0. Nominal dan tanggal bertipe angka/tanggal. Sheet Dompet cocok (saldo awal/sekarang). |
| 8 | P0 | **Sebagian** | Periode peralihan (awal bulan 1 → 25, periode "1 – 24 Okt, 24 hari") **lulus**; CSV 2 periode: Sep −Rp100.000 dan Okt Rp8.696.938 cocok dengan Riwayat (Sep −Rp100.000 terkonfirmasi). **Gajian maju belum teruji di perangkat**: tidak ada cara memicu kemunculan rutin terhubung dari UI, dan tanggal masa depan tidak bisa dipilih. Hanya terverifikasi oleh uji unit engineer. |
| 9 | P0 | **Lulus** | Isi cadangan: 12 kunci, checksum cocok, tanpa kunci notifikasi/kotak masuk/akun/bahasa/tur. Berkas dengan saldo BCA palsu (999.999.999,99) → sesudah pulih saldo dihitung ulang Rp11.746.938. |
| 10 | P1 | **Sebagian** | Struktur CSV benar (BOM UTF-8, koma, kutip). Excel lokal Indonesia dan Google Sheets tidak tersedia di emulator. |
| 11 | P1 | **Sebagian** | Catatan berisi persen dan kutip diketik via adb (`%22`) utuh. Koma, kutip asli, baris baru, dan emoji tidak bisa diketik lewat `adb input`; hanya diverifikasi uji unit engineer. |
| 12 | P1 | **Lulus** | Batal di lembar sistem: status "Belum pernah dicadangkan" tidak berubah, muncul pesan "Belum tersimpan…". Setelah disimpan: "Cadangan terakhir: 22 Okt 2026". |
| 13 | P1 | **Lulus** | Pratinjau menyebut cadangan lebih lama (lihat Temuan Q3). |
| 14 | P1 | **Lulus** | "Mata uang akan menjadi USD" di pratinjau. |
| 15 | P1 | **Belum** | Cadangan dengan sumber Catat dari notifikasi + pengingat menyala. Pengingat menyala tercakup (kunci `settings_recurring_reminders` ikut), sumber notifikasi belum. |
| 16 | P1 | **Sebagian** | Lembar ekspor tanpa pilihan rentang (lulus). Belum dicek ke semua layar bahwa tidak ada pintu ekspor lain (Riwayat sudah dilihat: tidak ada). |
| 17 | P1 | **Belum** | Belum ada transaksi (tombol nonaktif) dan data besar (≥ 5.000). |
| 18 | P1 | **Belum** | Mode pesawat. |
| 19 | P1 | **Tidak bisa** | iOS tidak tersedia. |
| 20 | P1 | **Belum** | 360dp, terang/gelap, id/en, peristiwa analitik. |

## Temuan sementara (belum dilaporkan ke Engineer)

Tidak ada S1/S2 sejauh ini.

- **T1 (di luar Fase 22):** `test/features/notification_capture/presentation/widgets/notification_inbox_card_test.dart` gagal ("aktif tanpa yang menunggu: jumlah aplikasi, Kelola…", tidak menemukan kunci `inbox-card-manage`). Penyebab: commit Fase 21 `51f972c1` mengubah layout kartu, tes belum disesuaikan. Engineer Fase 22 sudah mencatatnya sebagai gagal sebelumnya.
- **Q1 (S3):** `Atur lebih lanjut` di lembar Ulangi hanya merespons ketukan tepat di teksnya. Ketukan di tengah baris (area yang dilaporkan aksesibilitas sebagai satu-satunya target) tidak berefek.
- **Q2 (S3):** halaman "Data dipulihkan" selalu menulis "Izin notifikasi perlu diberikan lagi di ponsel ini" walau izin notifikasi sudah aktif (di emulator izin sudah diberikan).
- **Q3 (S3):** peringatan cadangan lebih lama berbunyi "catatan sesudah 22 Okt 2026 akan hilang" padahal transaksi yang hilang juga bertanggal 22 Okt (hari yang sama). Menyesatkan; gunakan jam, atau "yang kamu catat setelah cadangan ini".
- **Q4 (S4, catatan):** pada pemulihan dan Kembalikan, posisi tombol "Ganti data" bergeser tergantung baris peringatan; tidak masalah fungsional.
- **Dipastikan sudah diperbaiki sejak PR #43:** judul "Transfer"/"Pengeluaran" menggantikan "Tanpa judul", "Terpakai Rp0" (bukan −Rp0), sheet Catat muat tanpa gulir dengan keypad hitung, "Ulangi" jadi baris + pemilih, sheet Buat anggaran ringkas dengan footer sticky, baris "Perkiraan saldo 24 Okt ≈…" di Beranda, Riwayat punya segmen Daftar/Analisis dan label "Periode peralihan".

## Keadaan emulator saat dijeda

- Aplikasi terpasang (build `main@0152d09d`), data: dompet BCA dan Tunai, 8 transaksi (termasuk 15 Sep), rutin Gaji (tanggal 25), anggaran "Bulanan" dengan pos Makan, awal bulan keuangan 25 (peralihan 1 – 24 Okt), pengingat rutin menyala, bahasa id, IDR. Aplikasi berada di Riwayat › periode September.
- `/sdcard/Download/` berisi `tanukonomy-ekspor-2026-10-22.csv`.

## Berkas kerja (scratchpad sesi, bisa hilang)

`/private/tmp/claude-423743263/-Users-202604033-dev-personal-Saldough--claude-worktrees-list-agents-e23ddc/996db89d-9de5-40c9-82c5-b1b114a6c9cb/scratchpad/`: `bk/a.tkbak`, `bk/b.tkbak` (cadangan nyata A=5 dan B=6 transaksi), `bk2/q_*.tkbak` (varian uji), `exp/` (hasil ekspor), skrip `ui.sh`, `shot.sh`, `tapt.sh`, `skip.sh`, `snap.sh`, `tryfile.sh`, `crash2.sh`, `make_variants.py`, `analyze_bk.py`, `read_xlsx.py`, `check_export.py`, dan `shots2/` (tangkapan layar).

## Langkah berikutnya

1. #1: pulihkan lewat onboarding. Hapus data aplikasi (`adb shell pm clear com.arkarizdev.tanukonomy`), pilih bahasa, tautan di slide 1, pilih `a.tkbak`; bandingkan semua layar dengan `before.txt`.
2. #6 (isi ruang penuh), #17 (kosong dan besar), #18 (mode pesawat), #15, #20.
3. Tulis laporan T-22.7 (dan laporan temuan untuk Engineer) sebagai artefak, lalu pulihkan setelan emulator (mode gelap/ukuran layar bila diubah).


## Pembaruan 23 Okt 2026 (lanjutan)

| # | Status | Catatan |
|---|---|---|
| 1 | **Lulus** | Cadangan 8 transaksi, `pm clear` (ponsel B), onboarding → tautan → pulihkan: semua layar identik (Beranda, Riwayat Daftar/Analisis, Rencana Bulan ini/Anggaran/Rutin, Dompet). Mata uang dan periode dilewati, tidak ada periode peralihan baru. |
| 6 | **Tidak terpicu** | Penyimpanan diisi sampai 0 byte tersedia (`dd`), pulihkan tetap berhasil: Android masih mengizinkan penulisan kecil. `errorSpace` hanya terverifikasi lewat sapuan galat engineer. |
| 17 | **Lulus** | Kosong: tombol Export nonaktif + "No transactions to export yet.", tidak ada berkas. Besar: cadangan 5.008 transaksi dipulihkan (saldo cocok hitungan), ekspor xlsx 5.008 baris, ID unik, Arus per periode cocok (Sep −100.000, Okt 8.569.438), berkas 273 KB selesai dalam hitungan detik. |
| 18 | **Lulus** | Mode pesawat: ekspor, cadangkan, dan pulihkan berjalan. |
| 20 | **Sebagian** | 360dp (990x2200) + mode gelap, id dan en: Akun Data kamu, lembar ekspor, lembar cadangkan, pratinjau dan dialog pulihkan semuanya rapi, tanpa teks terpotong. Analitik tidak dilihat di DebugView. |
| 15 | **Belum** | Sumber Catat dari notifikasi di cadangan. |
| 19 | **Tidak bisa** | iOS. |

Temuan tambahan: Q5 (S4) "5008 transaksi" tanpa pemisah ribuan di lembar ekspor, cadangkan, dan pratinjau (id seharusnya "5.008", en "5,008"). Pemulihan dari Akun di ponsel kosong tetap menampilkan dialog "Ganti semua data" (sesuai spek, hanya onboarding yang dilewati).

Setelan emulator (ukuran layar, mode gelap) sudah dikembalikan; data uji dipulihkan dari cadangan A (8 transaksi); bahasa aplikasi sekarang English.
