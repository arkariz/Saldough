---
name: ux-review
description: Review Saldough 2.0 (aplikasi Flutter pencatatan keuangan pribadi — Dompet, Transaksi, Anggaran, Freelance) dari sudut pandang product/UX designer — information architecture, alur CATAT, copy (kosakata "mencatat, bukan melakukan"), state (memuat/kosong/gagal/konfirmasi), dan konsistensi bahasa visual pixel (ADR-015/016). Metode utama membaca kode (page, bloc, widget, i18n) terhadap PRD 2.0/DOMAIN_MODEL/glosarium/ADR; TIDAK menjalankan aplikasi kecuali ada pertanyaan yang memang butuh dilihat render-nya (kontras sungguhan, teks terpotong di lebar sempit, kecocokan dengan rujukan visual pemilik). Gunakan saat diminta "review sebagai UX/product designer", "nilai desain/UX aplikasi ini", "cek alur [fitur]", atau evaluasi usability — BUKAN untuk audit bug/korektnes kode (itu skill `code-review`).
---

# Review UX/produk Saldough 2.0

## Cakupan dan batasan

Review ini menilai **pengalaman pemakai**, bukan korektnes kode. Kalau saat
membaca kode ketemu sesuatu yang terlihat seperti bug fungsional (saldo salah,
edge case tidak ditangani), catat terpisah sebagai "di luar cakupan review ini,
kemungkinan bug — cek dengan `code-review`". Jangan diam-diam menjadikannya
temuan UX, dan jangan diperbaiki di sini. Review ini tidak pernah mengubah
kode: laporkan, lalu tunggu pemilik setuju sebelum mengimplementasikan apa pun.

Yang direview hanya layar yang **sudah ada kodenya**. Layar yang baru
direncanakan (Anggaran Fase 4, Freelance Fase 5, Beranda Fase 6 — cek
`docs/04-planning/TASK_LIST.md` untuk status terkini) bukan temuan "hilang";
tab yang masih `_ComingSoonTab` di `AppShellPage` memang disengaja.

## Alur kerja

1. **Orientasi lewat graph dulu.** Kalau `graphify-out/graph.json` ada,
   jalankan `graphify query "<layar atau alur yang direview>"` untuk
   memetakan berkas yang terlibat sebelum membuka kode. Kalau graph belum
   ada atau basi (bandingkan `Built from commit` di
   `graphify-out/GRAPH_REPORT.md` dengan `git rev-parse HEAD`), jalankan
   `graphify update .` — AST saja, tanpa biaya API.
2. **Baca konteks** — `references/context-map.md` berisi dokumen dan berkas
   kode yang wajib dibaca, beserta alasannya. Tanpa PRD 2.0/glosarium/
   ADR-015/016, temuan gampang salah pijak: menilai "aneh" sesuatu yang
   sebenarnya keputusan sadar pemilik, atau memakai istilah yang bukan
   istilah proyek.
3. **Cocokkan dengan keputusan yang sudah tercatat.** Catatan `⚠` di tiap
   tugas Fase 2 `TASK_LIST.md` (T-2.4 sampai T-2.12) merekam penyesuaian UI
   yang sudah dikerjakan atas permintaan pemilik — tata letak kartu Dari/Ke
   transfer, `WalletPickerField`, dropdown penyaring Transaksi, bidang
   pencarian, dst. Jangan laporkan ulang sebagai temuan baru. Kalau kode
   ternyata meregresi salah satunya, sebut eksplisit sebagai **regresi atas
   T-x.y**.
4. **Jalankan checklist** — `references/checklist.md`, kategori demi
   kategori. Tiap temuan HARUS menyebut berkas:baris dan konsekuensi nyata ke
   pemakai (bukan "kurang rapi" tanpa alasan). Sebagian besar poin bisa
   dijawab dari kode saja — ini metode utama, selesaikan dulu sebelum
   menimbang langkah 5.
5. **Putuskan apakah perlu melihat render sungguhan.** Baca
   `references/render-method.md` HANYA kalau langkah 4 menyisakan
   pertanyaan yang kode tidak bisa jawab — teks yang mungkin terpotong di
   lebar sempit, perbandingan dengan layar rujukan pemilik di
   `docs/stitch_pixel_finance_tracker/`, atau pemilik eksplisit minta
   "lihat tampilannya". Kontras warna TIDAK termasuk: sudah diuji otomatis
   di `test/core/theme/app_colors_extension_test.dart`.
6. **Laporkan** dengan format di bawah.

## Format laporan

Kelompokkan temuan per kategori checklist, urutkan dari yang paling
mengganggu penyelesaian tugas ke yang paling kosmetik:

- **Blocker** — menghalangi pemilik menyelesaikan tugas intinya (mencatat
  transaksi, melihat saldo yang benar, mengelola dompet).
- **Friksi** — bisa diselesaikan tapi berputar-putar, membingungkan, atau
  butuh tebakan.
- **Polish** — kosmetik/konsistensi, tidak menghalangi siapa pun.

Tiap temuan: `[Kategori checklist] Judul singkat` — berkas:baris —
konsekuensi ke pemakai — rekomendasi konkret (bukan "perbaiki UX-nya").
Tutup dengan 3 rekomendasi prioritas teratas kalau totalnya panjang.

Tulis laporan dalam bahasa Indonesia (preferensi pemilik, lihat
`.claude/CLAUDE.md`).
