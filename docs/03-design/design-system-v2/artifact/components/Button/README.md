# Button

Tombol untuk satu tindakan yang jelas. Tombol `primary` (hijau matcha) paling banyak satu per layar. Kelas `ds-btn`.

**Varian**
- `primary`: tujuan layar ("Simpan", "Catat").
- `secondary`: putih dengan garis rambut, tindakan pendamping.
- `ghost`: teks saja, tindakan ringan ("Batal", "Lewati").
- `on-hero` (putih) dan `on-hero-tonal` (hijau gelap): hanya di dalam kartu saldo hero, sudut 12px.
- `compact`: tombol kecil di banner, huruf piksel kapital ("KLAIM").
- `ds-iconbtn`: ikon saja, 36px dengan area sentuh 44px; wajib `aria-label`.

**Aturan**
- Teks 14/20 w600, kata kerja + benda, huruf kapital hanya di awal. Ikon depan 17px.
- Ditekan: skala 0,98 selama 150ms atau warna `*-pressed`. Tidak ada hover di ponsel.
- Target sentuh minimal 44px.
- Nonaktif: opasitas 45% dan alasannya ditulis di dekat tombol.

**Flutter:** `DsButton`, `DsIconButton`.
