---
name: ux-review
description: Review Saldough (aplikasi Flutter pencatatan keuangan pribadi) dari sudut pandang product/UX designer — information architecture, alur, copy, state (loading/kosong/error/konfirmasi), dan konsistensi token desain (ADR-0006). Metode utama membaca kode (screen, bloc, i18n) terhadap PRD/DOMAIN_MODEL/ADR; TIDAK menjalankan aplikasi kecuali ada pertanyaan yang memang butuh dilihat render-nya (kontras warna sungguhan, wrapping teks di lebar sempit). Gunakan saat diminta "review sebagai UX/product designer", "nilai desain/UX aplikasi ini", "cek alur [fitur]", atau evaluasi usability — BUKAN untuk audit bug/korektnes kode (itu skill `code-review`).
---

# Review UX/produk Saldough

## Cakupan dan batasan

Review ini menilai **pengalaman pemakai**, bukan korektnes kode. Kalau saat
membaca kode ketemu sesuatu yang terlihat seperti bug fungsional (logika
salah, edge case tidak ditangani), catat terpisah sebagai "di luar cakupan
review ini, kemungkinan bug — cek dengan `code-review`" — jangan diam-diam
dianggap temuan UX, dan jangan diperbaiki di sini. Review ini juga tidak
pernah mengubah kode: laporkan, lalu tunggu pemilik setuju sebelum
mengimplementasikan apa pun.

## Alur kerja

1. **Baca konteks dulu** — lihat `references/context-map.md` untuk daftar
   dokumen dan berkas kode yang wajib dibaca, dengan alasannya. Jangan
   lompat ke kode tanpa ini — tanpa PRD/DOMAIN_MODEL/ADR-0006/glosarium,
   temuan gampang salah pijak (menilai sesuatu "aneh" yang sebenarnya
   keputusan sadar pemilik, atau memakai istilah yang bukan istilah
   proyek).
2. **Cocokkan dengan perbaikan yang sudah berjalan** — `docs/04-planning/
   TASK_LIST.md` punya catatan "Catatan pengerjaan" untuk tiap fase,
   termasuk 9 perbaikan UI/UX yang sudah dikerjakan dari laporan pemilik
   sebelumnya (format tanggal, navigasi siklus, hapus siklus, penautan
   roll-up, dst). Jangan laporkan ulang hal yang sudah tercatat selesai di
   sana sebagai temuan baru — kalau kode ternyata meregresi salah satu dari
   itu, sebut eksplisit sebagai regresi, bukan temuan generik.
3. **Jalankan checklist** — `references/checklist.md`, kategori demi
   kategori. Tiap temuan HARUS menyebut berkas:baris dan konsekuensi nyata
   ke pemakai (bukan "kurang rapi" tanpa alasan). Sebagian besar poin di
   checklist itu bisa dijawab dari kode saja (pola token, copy, state
   handling, gating) — ini metode utama, selesaikan dulu sebelum
   menimbang langkah 4.
4. **Putuskan apakah perlu melihat render sungguhan.** Baca
   `references/web-run-method.md` HANYA kalau langkah 3 menyisakan
   pertanyaan yang kode saja tidak bisa jawab — misalnya kontras warna
   aksen di atas dasar terang/gelap, teks yang mungkin overflow/wrap di
   lebar sempit, atau pemilik eksplisit minta "lihat tampilannya". Untuk
   hal yang sudah dikodekan deklaratif (dipakai `AppSpacing`/`AppRadius`/
   `context.appColors` atau tidak — lihat checklist kategori E), cukup
   baca kode; jangan build+screenshot hanya untuk mengonfirmasi hal yang
   sudah bisa dipastikan dari teks kode.
5. **Laporkan** dengan format di bawah.

## Format laporan

Kelompokkan temuan per kategori checklist, urutkan per kategori dari yang
paling mengganggu task completion ke yang paling kosmetik:

- **Blocker** — menghalangi pemilik menyelesaikan tugas intinya (siklus
  bulanan, pencatatan jam kerja, dst).
- **Friksi** — bisa diselesaikan tapi berputar-putar, membingungkan, atau
  butuh tebakan.
- **Polish** — kosmetik/konsistensi, tidak menghalangi siapa pun.

Tiap temuan: `[Kategori checklist] Judul singkat` — berkas:baris —
konsekuensi ke pemakai — rekomendasi konkret (bukan "perbaiki UX-nya").
Tutup dengan 3 rekomendasi prioritas teratas kalau totalnya panjang.

Tulis laporan dalam bahasa Indonesia (preferensi pemilik, lihat
`.claude/CLAUDE.md`).
