///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsId = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.id,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <id>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$id app = Translations$app$id.internal(_root);
	late final Translations$common$id common = Translations$common$id.internal(_root);
	late final Translations$appShell$id appShell = Translations$appShell$id.internal(_root);
	late final Translations$record$id record = Translations$record$id.internal(_root);
	late final Translations$transaction$id transaction = Translations$transaction$id.internal(_root);
	late final Translations$wallet$id wallet = Translations$wallet$id.internal(_root);
}

// Path: app
class Translations$app$id {
	Translations$app$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Saldough'
	String get title => 'Saldough';
}

// Path: common
class Translations$common$id {
	Translations$common$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Simpan'
	String get save => 'Simpan';

	/// id: 'Batal'
	String get cancel => 'Batal';

	/// id: 'Hapus'
	String get delete => 'Hapus';

	/// id: 'Sunting'
	String get edit => 'Sunting';

	/// id: 'Tambah'
	String get add => 'Tambah';

	/// id: 'Coba lagi'
	String get retry => 'Coba lagi';

	/// id: 'Memuat...'
	String get loading => 'Memuat...';

	/// id: 'Ada yang salah. Coba lagi.'
	String get genericErrorMessage => 'Ada yang salah. Coba lagi.';

	/// id: 'Hapus?'
	String get confirmDeleteTitle => 'Hapus?';
}

// Path: appShell
class Translations$appShell$id {
	Translations$appShell$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Beranda'
	String get homeTabLabel => 'Beranda';

	/// id: 'Anggaran'
	String get budgetTabLabel => 'Anggaran';

	/// id: 'Catat'
	String get recordAction => 'Catat';

	/// id: 'Transaksi'
	String get transactionsTabLabel => 'Transaksi';

	/// id: 'Dompet'
	String get walletsTabLabel => 'Dompet';

	/// id: 'Segera hadir.'
	String get comingSoonMessage => 'Segera hadir.';
}

// Path: record
class Translations$record$id {
	Translations$record$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Catat Transaksi'
	String get sheetTitle => 'Catat Transaksi';

	/// id: 'Catat Pemasukan'
	String get incomeAction => 'Catat Pemasukan';

	/// id: 'Catat Pengeluaran'
	String get expenseAction => 'Catat Pengeluaran';

	/// id: 'Catat Transfer'
	String get transferAction => 'Catat Transfer';

	/// id: 'Masuk ke Dompet'
	String get toWalletFieldLabel => 'Masuk ke Dompet';

	/// id: 'Dari Dompet'
	String get fromWalletFieldLabel => 'Dari Dompet';

	/// id: 'Ke Dompet'
	String get destinationWalletFieldLabel => 'Ke Dompet';

	/// id: 'Tanggal'
	String get dateFieldLabel => 'Tanggal';

	/// id: 'Kategori (opsional)'
	String get categoryFieldHint => 'Kategori (opsional)';

	/// id: 'Tulis catatan singkat'
	String get noteFieldHint => 'Tulis catatan singkat';

	/// id: 'Belum ada dompet. Buat dompet dulu di tab Dompet.'
	String get noWalletsMessage => 'Belum ada dompet. Buat dompet dulu di tab Dompet.';

	/// id: 'Dompet asal dan tujuan tidak boleh sama.'
	String get sameWalletWarning => 'Dompet asal dan tujuan tidak boleh sama.';

	/// id: 'Pemasukan tercatat.'
	String get incomeSavedMessage => 'Pemasukan tercatat.';

	/// id: 'Pengeluaran tercatat.'
	String get expenseSavedMessage => 'Pengeluaran tercatat.';

	/// id: 'Transfer tercatat.'
	String get transferSavedMessage => 'Transfer tercatat.';

	/// id: 'Saldough hanya mencatat riwayat manual. Aplikasi ini tidak pernah memindahkan uang secara otomatis.'
	String get disclaimerMessage => 'Saldough hanya mencatat riwayat manual. Aplikasi ini tidak pernah memindahkan uang secara otomatis.';

	/// id: 'Catat uang yang masuk ke salah satu dompet.'
	String get incomeSubtitle => 'Catat uang yang masuk ke salah satu dompet.';

	/// id: 'Catat uang yang keluar dari salah satu dompet.'
	String get expenseSubtitle => 'Catat uang yang keluar dari salah satu dompet.';

	/// id: 'Catat perpindahan uang antar dompet milikmu sendiri.'
	String get transferSubtitle => 'Catat perpindahan uang antar dompet milikmu sendiri.';

	/// id: 'Menambah saldo dompet'
	String get incomeEffectLabel => 'Menambah saldo dompet';

	/// id: 'Mengurangi saldo dompet'
	String get expenseEffectLabel => 'Mengurangi saldo dompet';

	/// id: 'Total saldo tidak berubah'
	String get transferEffectLabel => 'Total saldo tidak berubah';

	/// id: 'Belum dipilih'
	String get walletNotSelectedPrompt => 'Belum dipilih';

	/// id: 'Menyimpan...'
	String get savingMessage => 'Menyimpan...';

	/// id: 'Gaji'
	String get categorySuggestionSalary => 'Gaji';

	/// id: 'Bonus'
	String get categorySuggestionBonus => 'Bonus';

	/// id: 'Penjualan'
	String get categorySuggestionSales => 'Penjualan';

	/// id: 'Hadiah'
	String get categorySuggestionGift => 'Hadiah';

	/// id: 'Makan'
	String get categorySuggestionFood => 'Makan';

	/// id: 'Belanja'
	String get categorySuggestionShopping => 'Belanja';

	/// id: 'Transport'
	String get categorySuggestionTransport => 'Transport';

	/// id: 'Tagihan'
	String get categorySuggestionBills => 'Tagihan';

	/// id: 'Pilih jenis peristiwa finansial yang ingin dicatat.'
	String get sheetSubtitle => 'Pilih jenis peristiwa finansial yang ingin dicatat.';

	/// id: 'Info Pencatatan'
	String get noticeTitle => 'Info Pencatatan';

	/// id: 'Contoh:'
	String get examplesLabel => 'Contoh:';

	/// id: 'Uang Masuk'
	String get incomeBadge => 'Uang Masuk';

	/// id: 'Uang Keluar'
	String get expenseBadge => 'Uang Keluar';

	/// id: 'Mutasi Internal'
	String get transferBadge => 'Mutasi Internal';

	/// id: 'Pilih Pemasukan'
	String get pickIncomeAction => 'Pilih Pemasukan';

	/// id: 'Pilih Pengeluaran'
	String get pickExpenseAction => 'Pilih Pengeluaran';

	/// id: 'Pilih Transfer'
	String get pickTransferAction => 'Pilih Transfer';

	/// id: 'Tarik Tunai'
	String get transferExampleCash => 'Tarik Tunai';

	/// id: 'Top-up e-Wallet'
	String get transferExampleTopUp => 'Top-up e-Wallet';

	/// id: 'Pindah Rekening'
	String get transferExampleMove => 'Pindah Rekening';

	/// id: 'Langkah 2 // Transaksi'
	String get stepLabel => 'Langkah 2 // Transaksi';

	/// id: 'Sunting // Transaksi'
	String get editStepLabel => 'Sunting // Transaksi';

	/// id: 'Aturan Kas: Saldo Terpotong'
	String get expenseRuleTitle => 'Aturan Kas: Saldo Terpotong';

	/// id: 'Pengeluaran langsung memotong saldo dompet yang kamu pilih di bawah ini.'
	String get expenseRuleBody => 'Pengeluaran langsung memotong saldo dompet yang kamu pilih di bawah ini.';

	/// id: 'Penting'
	String get transferNoticeTitle => 'Penting';

	/// id: 'Ini catatan perpindahan uang manual yang sudah kamu lakukan di dunia nyata. Bukan transfer bank otomatis.'
	String get transferNoticeBody => 'Ini catatan perpindahan uang manual yang sudah kamu lakukan di dunia nyata. Bukan transfer bank otomatis.';

	/// id: 'Nominal Masuk'
	String get amountLabelIncome => 'Nominal Masuk';

	/// id: 'Nominal Pengeluaran'
	String get amountLabelExpense => 'Nominal Pengeluaran';

	/// id: 'Nominal Transfer'
	String get amountLabelTransfer => 'Nominal Transfer';

	/// id: 'Bersihkan'
	String get clearAmountAction => 'Bersihkan';

	/// id: 'Kategori'
	String get categorySectionLabel => 'Kategori';

	/// id: 'Opsional'
	String get optionalHint => 'Opsional';

	/// id: 'Lainnya'
	String get categoryOtherLabel => 'Lainnya';

	/// id: 'Ketik kategori sendiri'
	String get categoryCustomHint => 'Ketik kategori sendiri';

	/// id: 'Hiburan'
	String get categorySuggestionEntertainment => 'Hiburan';

	/// id: 'Investasi'
	String get categorySuggestionInvestment => 'Investasi';

	/// id: 'Dompet Sumber Dana'
	String get expenseWalletSectionLabel => 'Dompet Sumber Dana';

	/// id: 'Keterangan / Catatan'
	String get noteSectionLabel => 'Keterangan / Catatan';

	/// id: 'Saldo berkurang'
	String get balanceDecreasesCaption => 'Saldo berkurang';

	/// id: 'Saldo bertambah'
	String get balanceIncreasesCaption => 'Saldo bertambah';

	/// id: 'Saldo $wallet akan bertambah $amount saat dicatat.'
	String incomeSummary({required Object wallet, required Object amount}) => 'Saldo ${wallet} akan bertambah ${amount} saat dicatat.';

	/// id: 'Saldo $wallet akan berkurang $amount saat dicatat.'
	String expenseSummary({required Object wallet, required Object amount}) => 'Saldo ${wallet} akan berkurang ${amount} saat dicatat.';

	/// id: 'Ringkasan Catatan Mutasi'
	String get transferSummaryTitle => 'Ringkasan Catatan Mutasi';

	/// id: 'Dompet $wallet berkurang $amount'
	String transferSummaryFrom({required Object wallet, required Object amount}) => 'Dompet ${wallet} berkurang ${amount}';

	/// id: 'Dompet $wallet bertambah $amount'
	String transferSummaryTo({required Object wallet, required Object amount}) => 'Dompet ${wallet} bertambah ${amount}';

	/// id: '*Catatan internal Saldough. Tidak mendebit atau mengirim uang di rekening bank sungguhan.'
	String get footnote => '*Catatan internal Saldough. Tidak mendebit atau mengirim uang di rekening bank sungguhan.';

	/// id: 'Saldo'
	String get balanceLabel => 'Saldo';

	/// id: 'Pilih kategori'
	String get categoryPlaceholder => 'Pilih kategori';

	/// id: 'Tanpa kategori'
	String get categoryNoneLabel => 'Tanpa kategori';

	/// id: 'Tahap 1 // Pilih Jenis'
	String get choiceStepLabel => 'Tahap 1 // Pilih Jenis';

	/// id: 'Luar'
	String get flowOutside => 'Luar';

	/// id: 'Dompet'
	String get flowWallet => 'Dompet';

	/// id: 'Dompet asal'
	String get flowSourceWallet => 'Dompet asal';

	/// id: 'Dompet tujuan'
	String get flowTargetWallet => 'Dompet tujuan';
}

// Path: transaction
class Translations$transaction$id {
	Translations$transaction$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Transaksi'
	String get pageTitle => 'Transaksi';

	/// id: 'Cari catatan / kategori...'
	String get searchHint => 'Cari catatan / kategori...';

	/// id: 'Status log bulan ini'
	String get monthStatusLabel => 'Status log bulan ini';

	/// id: '$count log aktif'
	String logCountBadge({required Object count}) => '${count} log aktif';

	/// id: 'Arus Bersih (Netto)'
	String get netFlowLabel => 'Arus Bersih (Netto)';

	/// id: 'Semua $count'
	String allFilterLabel({required Object count}) => 'Semua ${count}';

	/// id: 'Masuk $count'
	String incomeFilterLabel({required Object count}) => 'Masuk ${count}';

	/// id: 'Keluar $count'
	String expenseFilterLabel({required Object count}) => 'Keluar ${count}';

	/// id: 'Mutasi $count'
	String transferFilterLabel({required Object count}) => 'Mutasi ${count}';

	/// id: 'Semua Dompet'
	String get walletFilterAllLabel => 'Semua Dompet';

	/// id: 'Dompet'
	String get walletFilterLabel => 'Dompet';

	/// id: 'Semua Kategori'
	String get categoryFilterAllLabel => 'Semua Kategori';

	/// id: 'Kategori'
	String get categoryFilterLabel => 'Kategori';

	/// id: 'Hari Ini'
	String get todayLabel => 'Hari Ini';

	/// id: 'Kemarin'
	String get yesterdayLabel => 'Kemarin';

	/// id: '+MASUK'
	String get incomeBadge => '+MASUK';

	/// id: '-KELUAR'
	String get expenseBadge => '-KELUAR';

	/// id: '# MUTASI'
	String get transferBadge => '# MUTASI';

	/// id: 'Tanpa judul'
	String get untitledTransaction => 'Tanpa judul';

	/// id: 'Inventaris Kosong'
	String get emptyMonthBadge => 'Inventaris Kosong';

	/// id: 'Belum ada transaksi'
	String get emptyMonthTitle => 'Belum ada transaksi';

	/// id: 'Catat pemasukan, pengeluaran, atau transfer untuk mulai melihat riwayat buku kas harianmu.'
	String get emptyMonthSubtitle => 'Catat pemasukan, pengeluaran, atau transfer untuk mulai melihat riwayat buku kas harianmu.';

	/// id: 'Catat Transaksi Sekarang'
	String get emptyMonthCta => 'Catat Transaksi Sekarang';

	/// id: 'Panduan Catatan Kas'
	String get emptyGuideTitle => 'Panduan Catatan Kas';

	/// id: 'Pemasukan'
	String get emptyGuideIncomeTitle => 'Pemasukan';

	/// id: 'Menambah saldo dompet pilihan secara riil dan tercatat di kas.'
	String get emptyGuideIncomeDescription => 'Menambah saldo dompet pilihan secara riil dan tercatat di kas.';

	/// id: 'Pengeluaran'
	String get emptyGuideExpenseTitle => 'Pengeluaran';

	/// id: 'Memotong saldo dompet dan menghitung kuota batas anggaran bulanan.'
	String get emptyGuideExpenseDescription => 'Memotong saldo dompet dan menghitung kuota batas anggaran bulanan.';

	/// id: 'Transfer Antar Dompet'
	String get emptyGuideTransferTitle => 'Transfer Antar Dompet';

	/// id: 'Memindahkan catatan saldo antar dompet tanpa mengubah total kekayaan.'
	String get emptyGuideTransferDescription => 'Memindahkan catatan saldo antar dompet tanpa mengubah total kekayaan.';

	/// id: 'Semua transaksi dicatat manual • Privasi 100% aman di perangkatmu'
	String get trustFooterMessage => 'Semua transaksi dicatat manual • Privasi 100% aman di perangkatmu';

	/// id: 'Tidak ada transaksi yang cocok dengan filter'
	String get emptyFilterTitle => 'Tidak ada transaksi yang cocok dengan filter';

	/// id: 'Coba ganti atau hapus filter yang sedang aktif.'
	String get emptyFilterSubtitle => 'Coba ganti atau hapus filter yang sedang aktif.';

	/// id: 'Hapus filter'
	String get clearFiltersButton => 'Hapus filter';

	/// id: 'Transaksi gagal dimuat'
	String get loadErrorTitle => 'Transaksi gagal dimuat';

	/// id: 'Periksa lagi lalu coba muat ulang.'
	String get loadErrorSubtitle => 'Periksa lagi lalu coba muat ulang.';

	/// id: 'Kembali'
	String get detailBackLabel => 'Kembali';

	/// id: 'Pemasukan tercatat'
	String get detailIncomeTitle => 'Pemasukan tercatat';

	/// id: 'Pengeluaran tercatat'
	String get detailExpenseTitle => 'Pengeluaran tercatat';

	/// id: 'Transfer tercatat'
	String get detailTransferTitle => 'Transfer tercatat';

	/// id: 'Jenis Entri'
	String get detailTypeLabel => 'Jenis Entri';

	/// id: 'Pemasukan'
	String get detailIncomeType => 'Pemasukan';

	/// id: 'Pengeluaran'
	String get detailExpenseType => 'Pengeluaran';

	/// id: 'Transfer antar dompet'
	String get detailTransferType => 'Transfer antar dompet';

	/// id: 'Kategori'
	String get detailCategoryLabel => 'Kategori';

	/// id: 'Dompet Tujuan'
	String get detailIncomeWalletLabel => 'Dompet Tujuan';

	/// id: 'Dompet Sumber'
	String get detailExpenseWalletLabel => 'Dompet Sumber';

	/// id: 'Saldo saat ini'
	String get detailCurrentBalance => 'Saldo saat ini';

	/// id: 'Catatan Manual'
	String get detailNoteLabel => 'Catatan Manual';

	/// id: 'Dari'
	String get detailFromLabel => 'Dari';

	/// id: 'Ke'
	String get detailToLabel => 'Ke';

	/// id: 'Jumlah'
	String get detailAmountLabel => 'Jumlah';

	/// id: 'Catatan ini adalah rekaman manual di Saldough. Saldo dompet dihitung dari data yang kamu masukkan, tanpa terhubung ke rekening bank.'
	String get detailManualNote => 'Catatan ini adalah rekaman manual di Saldough. Saldo dompet dihitung dari data yang kamu masukkan, tanpa terhubung ke rekening bank.';

	/// id: 'Ubah Catatan Ini'
	String get editAction => 'Ubah Catatan Ini';

	/// id: 'Hapus Catatan dari Riwayat'
	String get deleteAction => 'Hapus Catatan dari Riwayat';

	/// id: 'Ubah Catatan'
	String get editSheetTitle => 'Ubah Catatan';

	/// id: 'Simpan Perubahan'
	String get saveChangesAction => 'Simpan Perubahan';

	/// id: 'Hapus catatan ini?'
	String get deleteConfirmTitle => 'Hapus catatan ini?';

	/// id: 'Catatan dihapus dari riwayat, dan saldo dompet dihitung ulang tanpa catatan ini.'
	String get deleteConfirmMessage => 'Catatan dihapus dari riwayat, dan saldo dompet dihitung ulang tanpa catatan ini.';

	/// id: 'Perubahan tersimpan.'
	String get updatedMessage => 'Perubahan tersimpan.';

	/// id: 'Catatan dihapus.'
	String get deletedMessage => 'Catatan dihapus.';
}

// Path: wallet
class Translations$wallet$id {
	Translations$wallet$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Dompet Saya'
	String get heading => 'Dompet Saya';

	/// id: 'Posisi saldo kas saat ini'
	String get subtitle => 'Posisi saldo kas saat ini';

	/// id: '$count kantong aktif'
	String activeBadge({required Object count}) => '${count} kantong aktif';

	/// id: 'Total saldo semua dompet'
	String get totalLabel => 'Total saldo semua dompet';

	/// id: 'Catatan Manual'
	String get manualNoteTitle => 'Catatan Manual';

	/// id: 'Saldo dihitung dari catatan yang kamu buat sendiri, bukan sinkronisasi otomatis dari bank.'
	String get manualNoteBody => 'Saldo dihitung dari catatan yang kamu buat sendiri, bukan sinkronisasi otomatis dari bank.';

	/// id: 'Daftar Dompet'
	String get listHeading => 'Daftar Dompet';

	/// id: 'Saldo Aktif'
	String get balanceLabel => 'Saldo Aktif';

	/// id: 'Tambah Dompet Baru'
	String get addAction => 'Tambah Dompet Baru';

	/// id: 'Dompet Nonaktif'
	String get inactiveHeading => 'Dompet Nonaktif';

	/// id: 'Nonaktif'
	String get inactiveBadge => 'Nonaktif';

	/// id: 'Bank / Rekening'
	String get typeBank => 'Bank / Rekening';

	/// id: 'Uang Tunai'
	String get typeCash => 'Uang Tunai';

	/// id: 'Dompet Digital'
	String get typeEwallet => 'Dompet Digital';

	/// id: 'Tabungan'
	String get typeSavings => 'Tabungan';

	/// id: 'Kartu'
	String get typeCard => 'Kartu';

	/// id: 'Belum ada dompet'
	String get emptyBadge => 'Belum ada dompet';

	/// id: 'Belum ada dompet tercatat'
	String get emptyTitle => 'Belum ada dompet tercatat';

	/// id: 'Tambahkan dompet pertama untuk mulai mencatat posisi uangmu. Bisa berupa rekening bank, e-wallet, atau uang tunai di saku.'
	String get emptyBody => 'Tambahkan dompet pertama untuk mulai mencatat posisi uangmu. Bisa berupa rekening bank, e-wallet, atau uang tunai di saku.';

	/// id: 'Dompet gagal dimuat'
	String get loadErrorTitle => 'Dompet gagal dimuat';

	/// id: 'Data dompet tidak terbaca. Coba lagi.'
	String get loadErrorSubtitle => 'Data dompet tidak terbaca. Coba lagi.';

	/// id: 'Tambah Dompet Baru'
	String get addTitle => 'Tambah Dompet Baru';

	/// id: 'Ubah Dompet'
	String get editTitle => 'Ubah Dompet';

	/// id: 'Dompet // Baru'
	String get addStepLabel => 'Dompet // Baru';

	/// id: 'Dompet // Ubah'
	String get editStepLabel => 'Dompet // Ubah';

	/// id: 'Nama Dompet'
	String get nameLabel => 'Nama Dompet';

	/// id: 'Contoh: Tabungan Mandiri, OVO, Brankas Tunai'
	String get nameHint => 'Contoh: Tabungan Mandiri, OVO, Brankas Tunai';

	/// id: 'Wajib'
	String get nameRequiredHint => 'Wajib';

	/// id: 'Maks. 24 karakter'
	String get nameMaxHint => 'Maks. 24 karakter';

	/// id: 'Pilih Ikon'
	String get iconLabel => 'Pilih Ikon';

	/// id: 'Saldo Awal Saat Ini'
	String get initialBalanceLabel => 'Saldo Awal Saat Ini';

	/// id: 'Saldo awal adalah uang yang ada saat ini, sebelum pencatatan transaksi dimulai. Ia pernyataan keadaan, bukan setoran, jadi tidak muncul di riwayat.'
	String get initialBalanceHelp => 'Saldo awal adalah uang yang ada saat ini, sebelum pencatatan transaksi dimulai. Ia pernyataan keadaan, bukan setoran, jadi tidak muncul di riwayat.';

	/// id: 'Saldo Tercatat Saat Ini'
	String get currentBalanceLabel => 'Saldo Tercatat Saat Ini';

	/// id: 'Mengubah saldo awal menghitung ulang saldo tercatat. Untuk selisih dengan uang nyata, catat pemasukan atau pengeluaran lewat CATAT.'
	String get editBalanceNote => 'Mengubah saldo awal menghitung ulang saldo tercatat. Untuk selisih dengan uang nyata, catat pemasukan atau pengeluaran lewat CATAT.';

	/// id: 'Dompet aktif'
	String get activeSwitchLabel => 'Dompet aktif';

	/// id: 'Dompet nonaktif tidak muncul di pemilih dompet. Transaksinya tetap tersimpan dan dihitung.'
	String get activeSwitchHelp => 'Dompet nonaktif tidak muncul di pemilih dompet. Transaksinya tetap tersimpan dan dihitung.';

	/// id: 'Simpan Dompet'
	String get saveAddAction => 'Simpan Dompet';

	/// id: 'Hapus Dompet'
	String get deleteAction => 'Hapus Dompet';

	/// id: 'Hanya bisa dihapus kalau belum punya transaksi sama sekali. Kalau sudah, nonaktifkan saja.'
	String get deleteHelp => 'Hanya bisa dihapus kalau belum punya transaksi sama sekali. Kalau sudah, nonaktifkan saja.';

	/// id: 'Hapus dompet?'
	String get deleteConfirmTitle => 'Hapus dompet?';

	/// id: 'Dompet $name akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.'
	String deleteConfirmMessage({required Object name}) => 'Dompet ${name} akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.';

	/// id: 'Dompet tersimpan.'
	String get savedMessage => 'Dompet tersimpan.';

	/// id: 'Dompet diperbarui.'
	String get updatedMessage => 'Dompet diperbarui.';

	/// id: 'Dompet dihapus.'
	String get deletedMessage => 'Dompet dihapus.';

	/// id: 'Dompet ini sudah punya transaksi, jadi tidak bisa dihapus. Nonaktifkan saja.'
	String get deleteBlockedMessage => 'Dompet ini sudah punya transaksi, jadi tidak bisa dihapus. Nonaktifkan saja.';

	/// id: 'Data tersimpan lokal dan privat di perangkatmu.'
	String get privacyNote => 'Data tersimpan lokal dan privat di perangkatmu.';

	/// id: 'Kembali'
	String get detailBackLabel => 'Kembali';

	/// id: 'Sunting'
	String get detailEditAction => 'Sunting';

	/// id: 'Transaksi Bulan Ini'
	String get detailRecentHeading => 'Transaksi Bulan Ini';

	/// id: 'Masuk'
	String get detailIncomeLabel => 'Masuk';

	/// id: 'Keluar'
	String get detailExpenseLabel => 'Keluar';

	/// id: 'Neto'
	String get detailNetLabel => 'Neto';

	/// id: 'Belum ada transaksi'
	String get detailRecentEmptyTitle => 'Belum ada transaksi';

	/// id: 'Belum ada transaksi bulan ini untuk dompet ini.'
	String get detailRecentEmpty => 'Belum ada transaksi bulan ini untuk dompet ini.';

	/// id: 'Lihat Semua Transaksi'
	String get detailViewAllAction => 'Lihat Semua Transaksi';

	/// id: 'Catat Transaksi Dompet Ini'
	String get detailRecordAction => 'Catat Transaksi Dompet Ini';
}

/// The flat map containing all translations for locale <id>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Saldough',
			'common.save' => 'Simpan',
			'common.cancel' => 'Batal',
			'common.delete' => 'Hapus',
			'common.edit' => 'Sunting',
			'common.add' => 'Tambah',
			'common.retry' => 'Coba lagi',
			'common.loading' => 'Memuat...',
			'common.genericErrorMessage' => 'Ada yang salah. Coba lagi.',
			'common.confirmDeleteTitle' => 'Hapus?',
			'appShell.homeTabLabel' => 'Beranda',
			'appShell.budgetTabLabel' => 'Anggaran',
			'appShell.recordAction' => 'Catat',
			'appShell.transactionsTabLabel' => 'Transaksi',
			'appShell.walletsTabLabel' => 'Dompet',
			'appShell.comingSoonMessage' => 'Segera hadir.',
			'record.sheetTitle' => 'Catat Transaksi',
			'record.incomeAction' => 'Catat Pemasukan',
			'record.expenseAction' => 'Catat Pengeluaran',
			'record.transferAction' => 'Catat Transfer',
			'record.toWalletFieldLabel' => 'Masuk ke Dompet',
			'record.fromWalletFieldLabel' => 'Dari Dompet',
			'record.destinationWalletFieldLabel' => 'Ke Dompet',
			'record.dateFieldLabel' => 'Tanggal',
			'record.categoryFieldHint' => 'Kategori (opsional)',
			'record.noteFieldHint' => 'Tulis catatan singkat',
			'record.noWalletsMessage' => 'Belum ada dompet. Buat dompet dulu di tab Dompet.',
			'record.sameWalletWarning' => 'Dompet asal dan tujuan tidak boleh sama.',
			'record.incomeSavedMessage' => 'Pemasukan tercatat.',
			'record.expenseSavedMessage' => 'Pengeluaran tercatat.',
			'record.transferSavedMessage' => 'Transfer tercatat.',
			'record.disclaimerMessage' => 'Saldough hanya mencatat riwayat manual. Aplikasi ini tidak pernah memindahkan uang secara otomatis.',
			'record.incomeSubtitle' => 'Catat uang yang masuk ke salah satu dompet.',
			'record.expenseSubtitle' => 'Catat uang yang keluar dari salah satu dompet.',
			'record.transferSubtitle' => 'Catat perpindahan uang antar dompet milikmu sendiri.',
			'record.incomeEffectLabel' => 'Menambah saldo dompet',
			'record.expenseEffectLabel' => 'Mengurangi saldo dompet',
			'record.transferEffectLabel' => 'Total saldo tidak berubah',
			'record.walletNotSelectedPrompt' => 'Belum dipilih',
			'record.savingMessage' => 'Menyimpan...',
			'record.categorySuggestionSalary' => 'Gaji',
			'record.categorySuggestionBonus' => 'Bonus',
			'record.categorySuggestionSales' => 'Penjualan',
			'record.categorySuggestionGift' => 'Hadiah',
			'record.categorySuggestionFood' => 'Makan',
			'record.categorySuggestionShopping' => 'Belanja',
			'record.categorySuggestionTransport' => 'Transport',
			'record.categorySuggestionBills' => 'Tagihan',
			'record.sheetSubtitle' => 'Pilih jenis peristiwa finansial yang ingin dicatat.',
			'record.noticeTitle' => 'Info Pencatatan',
			'record.examplesLabel' => 'Contoh:',
			'record.incomeBadge' => 'Uang Masuk',
			'record.expenseBadge' => 'Uang Keluar',
			'record.transferBadge' => 'Mutasi Internal',
			'record.pickIncomeAction' => 'Pilih Pemasukan',
			'record.pickExpenseAction' => 'Pilih Pengeluaran',
			'record.pickTransferAction' => 'Pilih Transfer',
			'record.transferExampleCash' => 'Tarik Tunai',
			'record.transferExampleTopUp' => 'Top-up e-Wallet',
			'record.transferExampleMove' => 'Pindah Rekening',
			'record.stepLabel' => 'Langkah 2 // Transaksi',
			'record.editStepLabel' => 'Sunting // Transaksi',
			'record.expenseRuleTitle' => 'Aturan Kas: Saldo Terpotong',
			'record.expenseRuleBody' => 'Pengeluaran langsung memotong saldo dompet yang kamu pilih di bawah ini.',
			'record.transferNoticeTitle' => 'Penting',
			'record.transferNoticeBody' => 'Ini catatan perpindahan uang manual yang sudah kamu lakukan di dunia nyata. Bukan transfer bank otomatis.',
			'record.amountLabelIncome' => 'Nominal Masuk',
			'record.amountLabelExpense' => 'Nominal Pengeluaran',
			'record.amountLabelTransfer' => 'Nominal Transfer',
			'record.clearAmountAction' => 'Bersihkan',
			'record.categorySectionLabel' => 'Kategori',
			'record.optionalHint' => 'Opsional',
			'record.categoryOtherLabel' => 'Lainnya',
			'record.categoryCustomHint' => 'Ketik kategori sendiri',
			'record.categorySuggestionEntertainment' => 'Hiburan',
			'record.categorySuggestionInvestment' => 'Investasi',
			'record.expenseWalletSectionLabel' => 'Dompet Sumber Dana',
			'record.noteSectionLabel' => 'Keterangan / Catatan',
			'record.balanceDecreasesCaption' => 'Saldo berkurang',
			'record.balanceIncreasesCaption' => 'Saldo bertambah',
			'record.incomeSummary' => ({required Object wallet, required Object amount}) => 'Saldo ${wallet} akan bertambah ${amount} saat dicatat.',
			'record.expenseSummary' => ({required Object wallet, required Object amount}) => 'Saldo ${wallet} akan berkurang ${amount} saat dicatat.',
			'record.transferSummaryTitle' => 'Ringkasan Catatan Mutasi',
			'record.transferSummaryFrom' => ({required Object wallet, required Object amount}) => 'Dompet ${wallet} berkurang ${amount}',
			'record.transferSummaryTo' => ({required Object wallet, required Object amount}) => 'Dompet ${wallet} bertambah ${amount}',
			'record.footnote' => '*Catatan internal Saldough. Tidak mendebit atau mengirim uang di rekening bank sungguhan.',
			'record.balanceLabel' => 'Saldo',
			'record.categoryPlaceholder' => 'Pilih kategori',
			'record.categoryNoneLabel' => 'Tanpa kategori',
			'record.choiceStepLabel' => 'Tahap 1 // Pilih Jenis',
			'record.flowOutside' => 'Luar',
			'record.flowWallet' => 'Dompet',
			'record.flowSourceWallet' => 'Dompet asal',
			'record.flowTargetWallet' => 'Dompet tujuan',
			'transaction.pageTitle' => 'Transaksi',
			'transaction.searchHint' => 'Cari catatan / kategori...',
			'transaction.monthStatusLabel' => 'Status log bulan ini',
			'transaction.logCountBadge' => ({required Object count}) => '${count} log aktif',
			'transaction.netFlowLabel' => 'Arus Bersih (Netto)',
			'transaction.allFilterLabel' => ({required Object count}) => 'Semua ${count}',
			'transaction.incomeFilterLabel' => ({required Object count}) => 'Masuk ${count}',
			'transaction.expenseFilterLabel' => ({required Object count}) => 'Keluar ${count}',
			'transaction.transferFilterLabel' => ({required Object count}) => 'Mutasi ${count}',
			'transaction.walletFilterAllLabel' => 'Semua Dompet',
			'transaction.walletFilterLabel' => 'Dompet',
			'transaction.categoryFilterAllLabel' => 'Semua Kategori',
			'transaction.categoryFilterLabel' => 'Kategori',
			'transaction.todayLabel' => 'Hari Ini',
			'transaction.yesterdayLabel' => 'Kemarin',
			'transaction.incomeBadge' => '+MASUK',
			'transaction.expenseBadge' => '-KELUAR',
			'transaction.transferBadge' => '# MUTASI',
			'transaction.untitledTransaction' => 'Tanpa judul',
			'transaction.emptyMonthBadge' => 'Inventaris Kosong',
			'transaction.emptyMonthTitle' => 'Belum ada transaksi',
			'transaction.emptyMonthSubtitle' => 'Catat pemasukan, pengeluaran, atau transfer untuk mulai melihat riwayat buku kas harianmu.',
			'transaction.emptyMonthCta' => 'Catat Transaksi Sekarang',
			'transaction.emptyGuideTitle' => 'Panduan Catatan Kas',
			'transaction.emptyGuideIncomeTitle' => 'Pemasukan',
			'transaction.emptyGuideIncomeDescription' => 'Menambah saldo dompet pilihan secara riil dan tercatat di kas.',
			'transaction.emptyGuideExpenseTitle' => 'Pengeluaran',
			'transaction.emptyGuideExpenseDescription' => 'Memotong saldo dompet dan menghitung kuota batas anggaran bulanan.',
			'transaction.emptyGuideTransferTitle' => 'Transfer Antar Dompet',
			'transaction.emptyGuideTransferDescription' => 'Memindahkan catatan saldo antar dompet tanpa mengubah total kekayaan.',
			'transaction.trustFooterMessage' => 'Semua transaksi dicatat manual • Privasi 100% aman di perangkatmu',
			'transaction.emptyFilterTitle' => 'Tidak ada transaksi yang cocok dengan filter',
			'transaction.emptyFilterSubtitle' => 'Coba ganti atau hapus filter yang sedang aktif.',
			'transaction.clearFiltersButton' => 'Hapus filter',
			'transaction.loadErrorTitle' => 'Transaksi gagal dimuat',
			'transaction.loadErrorSubtitle' => 'Periksa lagi lalu coba muat ulang.',
			'transaction.detailBackLabel' => 'Kembali',
			'transaction.detailIncomeTitle' => 'Pemasukan tercatat',
			'transaction.detailExpenseTitle' => 'Pengeluaran tercatat',
			'transaction.detailTransferTitle' => 'Transfer tercatat',
			'transaction.detailTypeLabel' => 'Jenis Entri',
			'transaction.detailIncomeType' => 'Pemasukan',
			'transaction.detailExpenseType' => 'Pengeluaran',
			'transaction.detailTransferType' => 'Transfer antar dompet',
			'transaction.detailCategoryLabel' => 'Kategori',
			'transaction.detailIncomeWalletLabel' => 'Dompet Tujuan',
			'transaction.detailExpenseWalletLabel' => 'Dompet Sumber',
			'transaction.detailCurrentBalance' => 'Saldo saat ini',
			'transaction.detailNoteLabel' => 'Catatan Manual',
			'transaction.detailFromLabel' => 'Dari',
			'transaction.detailToLabel' => 'Ke',
			'transaction.detailAmountLabel' => 'Jumlah',
			'transaction.detailManualNote' => 'Catatan ini adalah rekaman manual di Saldough. Saldo dompet dihitung dari data yang kamu masukkan, tanpa terhubung ke rekening bank.',
			'transaction.editAction' => 'Ubah Catatan Ini',
			'transaction.deleteAction' => 'Hapus Catatan dari Riwayat',
			'transaction.editSheetTitle' => 'Ubah Catatan',
			'transaction.saveChangesAction' => 'Simpan Perubahan',
			'transaction.deleteConfirmTitle' => 'Hapus catatan ini?',
			'transaction.deleteConfirmMessage' => 'Catatan dihapus dari riwayat, dan saldo dompet dihitung ulang tanpa catatan ini.',
			'transaction.updatedMessage' => 'Perubahan tersimpan.',
			'transaction.deletedMessage' => 'Catatan dihapus.',
			'wallet.heading' => 'Dompet Saya',
			'wallet.subtitle' => 'Posisi saldo kas saat ini',
			'wallet.activeBadge' => ({required Object count}) => '${count} kantong aktif',
			'wallet.totalLabel' => 'Total saldo semua dompet',
			'wallet.manualNoteTitle' => 'Catatan Manual',
			'wallet.manualNoteBody' => 'Saldo dihitung dari catatan yang kamu buat sendiri, bukan sinkronisasi otomatis dari bank.',
			'wallet.listHeading' => 'Daftar Dompet',
			'wallet.balanceLabel' => 'Saldo Aktif',
			'wallet.addAction' => 'Tambah Dompet Baru',
			'wallet.inactiveHeading' => 'Dompet Nonaktif',
			'wallet.inactiveBadge' => 'Nonaktif',
			'wallet.typeBank' => 'Bank / Rekening',
			'wallet.typeCash' => 'Uang Tunai',
			'wallet.typeEwallet' => 'Dompet Digital',
			'wallet.typeSavings' => 'Tabungan',
			'wallet.typeCard' => 'Kartu',
			'wallet.emptyBadge' => 'Belum ada dompet',
			'wallet.emptyTitle' => 'Belum ada dompet tercatat',
			'wallet.emptyBody' => 'Tambahkan dompet pertama untuk mulai mencatat posisi uangmu. Bisa berupa rekening bank, e-wallet, atau uang tunai di saku.',
			'wallet.loadErrorTitle' => 'Dompet gagal dimuat',
			'wallet.loadErrorSubtitle' => 'Data dompet tidak terbaca. Coba lagi.',
			'wallet.addTitle' => 'Tambah Dompet Baru',
			'wallet.editTitle' => 'Ubah Dompet',
			'wallet.addStepLabel' => 'Dompet // Baru',
			'wallet.editStepLabel' => 'Dompet // Ubah',
			'wallet.nameLabel' => 'Nama Dompet',
			'wallet.nameHint' => 'Contoh: Tabungan Mandiri, OVO, Brankas Tunai',
			'wallet.nameRequiredHint' => 'Wajib',
			'wallet.nameMaxHint' => 'Maks. 24 karakter',
			'wallet.iconLabel' => 'Pilih Ikon',
			'wallet.initialBalanceLabel' => 'Saldo Awal Saat Ini',
			'wallet.initialBalanceHelp' => 'Saldo awal adalah uang yang ada saat ini, sebelum pencatatan transaksi dimulai. Ia pernyataan keadaan, bukan setoran, jadi tidak muncul di riwayat.',
			'wallet.currentBalanceLabel' => 'Saldo Tercatat Saat Ini',
			'wallet.editBalanceNote' => 'Mengubah saldo awal menghitung ulang saldo tercatat. Untuk selisih dengan uang nyata, catat pemasukan atau pengeluaran lewat CATAT.',
			'wallet.activeSwitchLabel' => 'Dompet aktif',
			'wallet.activeSwitchHelp' => 'Dompet nonaktif tidak muncul di pemilih dompet. Transaksinya tetap tersimpan dan dihitung.',
			'wallet.saveAddAction' => 'Simpan Dompet',
			'wallet.deleteAction' => 'Hapus Dompet',
			'wallet.deleteHelp' => 'Hanya bisa dihapus kalau belum punya transaksi sama sekali. Kalau sudah, nonaktifkan saja.',
			'wallet.deleteConfirmTitle' => 'Hapus dompet?',
			'wallet.deleteConfirmMessage' => ({required Object name}) => 'Dompet ${name} akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.',
			'wallet.savedMessage' => 'Dompet tersimpan.',
			'wallet.updatedMessage' => 'Dompet diperbarui.',
			'wallet.deletedMessage' => 'Dompet dihapus.',
			'wallet.deleteBlockedMessage' => 'Dompet ini sudah punya transaksi, jadi tidak bisa dihapus. Nonaktifkan saja.',
			'wallet.privacyNote' => 'Data tersimpan lokal dan privat di perangkatmu.',
			'wallet.detailBackLabel' => 'Kembali',
			'wallet.detailEditAction' => 'Sunting',
			'wallet.detailRecentHeading' => 'Transaksi Bulan Ini',
			'wallet.detailIncomeLabel' => 'Masuk',
			'wallet.detailExpenseLabel' => 'Keluar',
			'wallet.detailNetLabel' => 'Neto',
			'wallet.detailRecentEmptyTitle' => 'Belum ada transaksi',
			'wallet.detailRecentEmpty' => 'Belum ada transaksi bulan ini untuk dompet ini.',
			'wallet.detailViewAllAction' => 'Lihat Semua Transaksi',
			'wallet.detailRecordAction' => 'Catat Transaksi Dompet Ini',
			_ => null,
		};
	}
}
