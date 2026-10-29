# Catatan sementara: review UX alur utama (29 Okt 2026)

**Berkas sementara.** Hapus berkas ini begitu semua butir selesai, dipindah
ke TASK_LIST (sebagai `T-n.n` atau `B-n`), atau dinyatakan tidak dikerjakan.
Ini bukan daftar tugas resmi; jadwal dan progres tetap di
[TASK_LIST.md](TASK_LIST.md).

Metode: membaca kode (page, bloc, widget, i18n) terhadap glosarium, PRD, dan
ADR, memakai skill `ux-review`. Belum dirender di perangkat. Identitas butir
`UXR-n` supaya tidak bentrok dengan `UX-1`–`UX-22` di
[done/UX_REVIEW_FIXES.md](done/UX_REVIEW_FIXES.md).

Kesimpulan: tidak ada blocker. Mencatat sudah cepat; yang membingungkan
sekarang adalah satu konsep bernama banyak, dua cara untuk hal yang sama,
layar terlalu padat, dan isian yang bisa hilang tanpa peringatan.

## Friksi

- [ ] **UXR-1** [B] **Isian Catat bisa hilang tanpa peringatan.**
      `lib/core/presentation/widgets/full_screen_sheet.dart:12` memakai
      `showModalBottomSheet` dengan bawaan geser-tutup, ketuk area atas, dan
      tombol kembali; tidak ada formulir yang punya konfirmasi buang perubahan
      (`PopScope` hanya di onboarding dan pemulihan). Draf suara/notifikasi,
      rutin yang sudah diatur, atau pola notifikasi tiga langkah
      (`notification_pattern_page.dart`, `notification_source_page.dart`
      dengan tombol Simpan) hilang dengan satu geseran.
      Usul: matikan geser-tutup untuk formulir; tanya "Buang isian?" bila ada
      perubahan.
- [ ] **UXR-2** [D] **"Rutin" punya tiga nama.** Glosarium
      (`PROJECT_GLOSSARY.md` "Transaksi rutin, rutin") dan segmen
      (`plan.recurringSegmentLabel` = "Rutin") memakai "rutin"; isi segmen,
      rincian, dan aksi memakai "transaksi berulang" / "Jadikan berulang"
      (`transaction.makeRecurringAction`, `recurring.*`); anggaran "Berulang"
      (`budget.recurringBadge`, `plan.financialMonthBudgetsTitle`); pengingat
      "tagihan rutin"; sumber notifikasi "Ikat ke rutin". Commit poles teks
      `f812c3b` mengganti istilah tanpa memperbarui glosarium.
      Usul: pemilik memilih satu istilah, lalu glosarium, `writing.md`, dan
      i18n id/en disamakan.
- [x] **UXR-3** [D] **"Uang nganggur" punya tiga nama.** Selain "Uang
      nganggur" (glosarium) ada "dana yang benar-benar bebas"
      (`plan.emptyBody`, `recurring.emptyBody`), "ruang bebas"
      (`plan.installmentFree`, `installmentFreeLine`), dan "dialokasikan"
      (`plan.committedShare`). Terbaca seperti tiga angka berbeda.
      Usul: satu istilah "Uang nganggur" di semua teks.
      **Selesai 29 Okt 2026:** teks id dan en diganti ("uang nganggurmu
      bertambah", "terpakai rencana"); "dialokasikan" dan "ruang bebas" hilang.
- [ ] **UXR-4** [A] **Rencana › Bulan ini terlalu padat konsep.**
      `lib/features/plan/presentation/pages/plan_month_page.dart:170–271`:
      tinjauan bulan, siapkan dana, Uang nganggur, % dialokasikan, ruang
      bebas cicilan, perkiraan saldo, menunggu, berikutnya, dan tawaran
      gajian dalam satu layar.
      Usul: Uang nganggur satu-satunya angka utama; "dialokasikan" dan "ruang
      bebas" pindah ke rincian atau lapis info. Butuh rupa dari designer.
- [ ] **UXR-5** [A] **Banner menumpuk di Beranda.**
      `lib/features/home/presentation/pages/home_page.dart:163`: banner
      pembaruan, kotak masuk notifikasi, rutin menunggu, dan dorongan fitur
      bisa tampil bersamaan antara kartu saldo dan Arus.
      Usul: paling banyak satu banner tindakan, dengan urutan prioritas.
- [x] **UXR-6** [B] **Mengubah rutin berjudul "Catat".**
      `expense_form_sheet.dart:244`, `income_form_sheet.dart:179`,
      `transfer_form_sheet.dart:228`: judul hanya membedakan sunting
      transaksi; Ubah rutin dan Jadikan berulang tetap berjudul "Catat"
      padahal tidak ada transaksi baru (peringatan "saldo tidak berubah" baru
      di bawah, `expense_form_sheet.dart:329`).
      Usul: judul "Ubah jadwal" / "Jadikan berulang".
      **Selesai 29 Okt 2026:** `recordFormTitle` di `record_repeat_field.dart`
      dipakai tiga formulir; kunci `record.repeat.editScheduleTitle` dan
      `makeRecurringTitle`.
- [ ] **UXR-7** [B] **Template anggaran dan "Ulangi tiap periode" tumpang
      tindih.** Dua cara memakai anggaran lagi. `budget.templateRuleBody`
      ("Dompet dan periodenya dipilih saat template dipakai") dan
      `budget.templatesInfoBody` tidak berlaku untuk anggaran berulang, yang
      ikut tampil di halaman template dengan dompet dan periode tetap
      (`budget_template_page.dart:216`).
      Usul: pisahkan dua kelompok di halaman itu dan perbarui teksnya.
- [ ] **UXR-8** [B] **Kolom saldo kosong saat mengubah dompet bersaldo
      negatif atau bersen.** `wallet_form_sheet.dart:97`; kartu Saldo saat ini
      hanya-baca dihapus di `dd18320`, jadi angka asli tidak terlihat.
      Bergantung pada keputusan KT-W1 di TASK_LIST.
- [ ] **UXR-9** [B] **Catat tanpa dompet buntu.**
      `lib/shared/wallet/presentation/wallet_select_field.dart:66`: "Buat
      dompet dulu di tab Dompet" tanpa tombol.
      Usul: tombol Tambah dompet langsung di situ.
- [x] **UXR-10** [D] **Onboarding menyebut "dompet di akunmu".**
      `onboarding.page2Body` (`id.i18n.json:741`); akun opsional dan data
      milik perangkat (ADR-024). Usul: hapus "di akunmu" (id dan en).
      **Selesai 29 Okt 2026** (hanya teks id; teks en memang tidak menyebut akun).

## Polish

- [x] **UXR-11** Pencarian Riwayat "Cari di periode ini" (`transaction.searchHint`)
      tetapi tombolnya "Cari di bulan lain" (`crossMonthSearchButton`).
      **Selesai 29 Okt 2026:** tombol jadi "Cari di periode lain" / "Search other periods".
- [x] **UXR-12** Bagian Freelance di Beranda tanpa "Lihat semua"
      (`home_page.dart:206`); header Anggaran memakai kunci
      `appShell.budgetTabLabel` walau tab bernama Rencana (`home_page.dart:197`).
      **Selesai 29 Okt 2026 sebagian:** tautan "Lihat semua" Freelance
      ditambahkan. Bagian header Anggaran **keliru**: label "Anggaran" cocok
      dengan segmen Anggaran di Rencana yang dituju, tidak diubah.
- [x] **UXR-13** Halaman sumber notifikasi: "Ikat ke rutin" tampil sebelum
      daftar pola yang diikatnya (`notification_source_page.dart:343` vs `:447`).
      **Keliru, tidak diubah (29 Okt 2026):** angka baris itu definisi fungsi;
      urutan render sebenarnya pola dulu, lalu contoh, lalu "Ikat ke rutin"
      (`:482`).

## Keputusan sadar pemilik (bukan temuan, hanya catatan risiko)

- Onboarding sampai 9 layar; langkah periode dan pengingat wajib dijawab
  (KT-D1). Izin pengingat diminta sebelum pengguna punya rutin.
- Freelance hanya dibuka dari Catat → Pemasukan.
- Nominal kembali kosong saat jenis diganti (KT-4).
- Temuan QA Fase 23 sudah di B-83.

## Prioritas

1. UXR-1 (isian hilang).
2. UXR-2 dan UXR-3 (istilah; butuh keputusan pemilik).
3. UXR-4 dan UXR-5 (kepadatan Bulan ini dan Beranda; butuh rupa).

## Belum tercakup

Analisis, Freelance, Akun, layar data, halaman pola notifikasi secara rinci,
dan teks terpotong di lebar 360dp (butuh render).
