# HeroCard

Kartu saldo hero di Beranda dan Dompet. Latar gradasi dari `hero-surface` (sama di terang dan gelap), sudut 24, padding 20, bingkai `hero-border`. Isi berurutan: kepala (token daun + label kapital + tombol mata), saldo ("Rp" 18 + angka 44 tabular), kotak statistik (maks. tiga: Masuk, Keluar), baris perkiraan (`footer`), pita bawah dengan titik berdenyut.

Gerak (aplikasi): angka menghitung naik 1,1 dtk; sembunyikan angka dengan kabur 6px; aura bernapas; daun dan kilau melayang; kartu miring ±9° mengikuti jari. Semuanya berhenti saat gerak dikurangi, dan pembaca layar mendapat angka akhir. Mata memakai `AmountVisibility`.

Kosakata: "saldo" hanya untuk isi dompet. Tombol di hero ditulis "Catat ...", bukan "Isi saldo" atau "Kirim" (mencatat, bukan melakukan).

**Flutter:** `DsHeroBalanceCard`, `DsHeroStatTile`, `DsCountUp`.
