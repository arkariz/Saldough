# Motion

Aturan gerak (rincian: `docs/03-design/design-system-v2/motion.md`).

1. **Gerak dikurangi:** bila sistem meminta, animasi berulang berhenti, partikel latar tidak digambar, hitung naik dan balik langsung ke nilai akhir.
2. Satu ticker per komponen; berhenti saat rute tidak tampil.
3. Animasi berulang hanya skala, keburaman, dan geser (bukan bayangan).
4. Tidak ada teks di dalam komponen gerak.

| Gerak | Waktu |
|---|---|
| Transisi standar, tekan skala 0,98 (tile 0,95) | 150ms ease-out |
| Hitung naik angka | 1,1–1,4 dtk |
| Balik 3D / kabur ganti angka | 200+250ms / 280ms |
| Titik berdenyut | 1 dtk |
| Meter bernapas | 2,2 dtk |
| Carousel | 300ms |

Pratinjau: tombol di bawah memakai transisi standar.
