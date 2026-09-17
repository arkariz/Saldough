# Arsip Saldough 1.0

Direktori ini menyimpan dokumen perencanaan Saldough 1.0 — produk pengganti
spreadsheet yang berporos pada `MonthlyCycle`. Dokumen di sini dibekukan pada
17 September 2026 dan tidak lagi diperbarui. Untuk pekerjaan yang berlaku
sekarang, mulai dari [indeks dokumentasi](../README.md).

Yang diarsipkan hanya dokumen yang isinya **catatan riwayat** — daftar tugas
yang sudah dicentang, catatan pengerjaan bertanggal, dan temuan review. Catatan
semacam itu tetap bernilai sebagai rekaman meski produknya berganti. Dokumen
yang isinya **definisi** (`DOMAIN_MODEL.md`, `PROJECT_GLOSSARY.md`,
`user-stories.md`) tidak diarsipkan melainkan ditulis ulang di tempatnya,
sesuai kebiasaan proyek ini memperlakukannya sebagai dokumen hidup. Versi
lamanya tetap bisa dibaca lewat riwayat git.

| Berkas | Isi |
|---|---|
| [ROADMAP-1.0.md](ROADMAP-1.0.md) | Urutan Fase 0–7 lama dan alasannya |
| [TASK_LIST-1.0.md](TASK_LIST-1.0.md) | 68 tugas MVP lama beserta catatan pengerjaannya |
| [UI_UX_DESIGN_TASKS-1.0.md](UI_UX_DESIGN_TASKS-1.0.md) | Tugas desain D-x.x dan riwayat pergantian gaya visual |
| [UX_REVIEW_FIXES-1.0.md](UX_REVIEW_FIXES-1.0.md) | Temuan review UX 11 September 2026 dan status perbaikannya |

Dua dokumen 1.0 lain sengaja **tidak** dipindahkan ke sini:

- [`prd-saldough-1.0.md`](../01-product/prd-saldough-1.0.md) tetap di tempatnya
  karena namanya sudah berversi — PRD 2.0 hadir sebagai berkas baru di
  sebelahnya, dan seluruh tautan yang menunjuk ke 1.0 tetap hidup.
- [`MANUAL_PROCESS_ANALYSIS.md`](../00-foundation/MANUAL_PROCESS_ANALYSIS.md)
  tidak diarsipkan sama sekali. Isinya rekaman cara pemilik mengelola uangnya
  di spreadsheet, dan fakta itu tidak berubah karena aplikasinya berganti
  bentuk. Dokumen itu masih jadi sumber angka bukti untuk rumus di
  [DOMAIN_MODEL.md](../02-architecture/DOMAIN_MODEL.md).

## Memulihkan kode 1.0

Kode fitur `cycle`, `card`, `investment`, `grocery`, dan `income` dihapus pada
Fase 3 pivot. Pemulihannya lewat tag git, bukan lewat folder mati yang harus
terus lolos `flutter analyze`:

```
git checkout pre-pivot-1.0
```

Alasan memilih tag dicatat di
[ADR-014](../02-architecture/adr/0014-strategi-pivot-saldough-2.md).
