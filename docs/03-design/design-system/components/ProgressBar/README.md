# ProgressBar

Bar anggaran: seberapa banyak yang sudah terpakai dibanding rencana, dengan penanda seberapa jauh periode sudah berjalan.

**Status**
- Aman (di bawah 85%): isi `ink`, badge `positive` "Aman".
- Hampir habis (85–100%): isi `warning-fill`, badge `warning` "Hampir habis".
- Lewat (di atas 100%): isi penuh `danger`, badge `danger` yang menyebut selisihnya ("Lewat Rp36.000").
- Selesai (pos sudah dipakai tepat sesuai rencana): isi `ink`, badge netral "Selesai".

**Aturan**
- Tersusun dari kotak 6px berjarak 2px, tinggi 10px di kartu dan 6px (`--thin`) di baris pos. Kotaknya kecil supaya tetap presisi; bukan 10 blok besar seperti desain lama.
- Penanda waktu (`tk-bar__pace`) hanya untuk anggaran berperiode yang sedang berjalan.
- Di bawah bar selalu ada angka: "Rp3.420.000 dari Rp5.350.000" dan "Sisa Rp1.930.000". Bar tidak pernah berdiri sendiri.
- Peran `progressbar` dengan nilai persen.

**Disediakan pemakai:** terpakai, rencana, persen periode berjalan.
