# TextField

Kolom isian (spek): isi `surface-card`, garis rambut `outline-subtle` 1px, sudut 8, placeholder `text-tertiary`. Fokus: cincin 1px `outline-focus`, tanpa cahaya.

**Keputusan pemilik KT-DS1:** bingkai ikut spek walau 1,2:1 (di bawah 3:1 untuk batas kontrol). Jangan "memperbaiki" ke garis lebih gelap tanpa keputusan baru. Label tetap terlihat di atas kolom sehingga kolom tetap dikenali.

**Kolom nominal cepat** (`ds-field--amount`): tanpa bingkai, 36/44 tabular, simbol mata uang `text-tertiary`. Input di aplikasi lewat `money_input.dart`.

Galat: pesan satu kalimat di bawah kolom dengan warna `error`; jangan hanya mengganti warna bingkai.

**Flutter:** `TextField` Material yang digayakan `DsTheme` (`inputDecorationTheme`).
