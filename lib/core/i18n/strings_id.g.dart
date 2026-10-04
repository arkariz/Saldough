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
	late final Translations$budget$id budget = Translations$budget$id.internal(_root);
	late final Translations$freelance$id freelance = Translations$freelance$id.internal(_root);
	late final Translations$home$id home = Translations$home$id.internal(_root);
	late final Translations$onboarding$id onboarding = Translations$onboarding$id.internal(_root);
	late final Translations$tour$id tour = Translations$tour$id.internal(_root);
	late final Translations$info$id info = Translations$info$id.internal(_root);
	late final Translations$account$id account = Translations$account$id.internal(_root);
	late final Translations$currency$id currency = Translations$currency$id.internal(_root);
	late final Translations$category$id category = Translations$category$id.internal(_root);
	late final Translations$language$id language = Translations$language$id.internal(_root);
	late final Translations$notificationCapture$id notificationCapture = Translations$notificationCapture$id.internal(_root);
	late final Translations$recurring$id recurring = Translations$recurring$id.internal(_root);
	late final Translations$plan$id plan = Translations$plan$id.internal(_root);
}

// Path: app
class Translations$app$id {
	Translations$app$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Tanukonomy'
	String get title => 'Tanukonomy';
}

// Path: common
class Translations$common$id {
	Translations$common$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: '+${amount}rb'
	String quickAmountThousands({required Object amount}) => '+${amount}rb';

	/// id: '+${amount}jt'
	String quickAmountMillions({required Object amount}) => '+${amount}jt';

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

	/// id: 'Riwayat'
	String get transactionsTabLabel => 'Riwayat';

	/// id: 'Dompet'
	String get walletsTabLabel => 'Dompet';

	/// id: 'Rencana'
	String get planTabLabel => 'Rencana';
}

// Path: record
class Translations$record$id {
	Translations$record$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

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

	/// id: 'Belum dipilih'
	String get walletNotSelectedPrompt => 'Belum dipilih';

	/// id: 'Menyimpan...'
	String get savingMessage => 'Menyimpan...';

	/// id: 'Uang Masuk'
	String get incomeBadge => 'Uang Masuk';

	/// id: 'Uang Keluar'
	String get expenseBadge => 'Uang Keluar';

	/// id: 'Mutasi Internal'
	String get transferBadge => 'Mutasi Internal';

	/// id: 'Catat // Transaksi'
	String get stepLabel => 'Catat // Transaksi';

	/// id: 'Sunting // Transaksi'
	String get editStepLabel => 'Sunting // Transaksi';

	/// id: 'Aturan Kas: Saldo Terpotong'
	String get expenseRuleTitle => 'Aturan Kas: Saldo Terpotong';

	/// id: 'Pengeluaran langsung memotong saldo dompet yang kamu pilih di bawah ini.'
	String get expenseRuleBody => 'Pengeluaran langsung memotong saldo dompet yang kamu pilih di bawah ini.';

	/// id: 'Pindah antar dompet'
	String get transferNoticeTitle => 'Pindah antar dompet';

	/// id: 'Catat uang yang berpindah di antara dompetmu, misalnya tarik tunai atau isi e-wallet. Total saldomu tetap sama.'
	String get transferNoticeBody => 'Catat uang yang berpindah di antara dompetmu, misalnya tarik tunai atau isi e-wallet. Total saldomu tetap sama.';

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

	/// id: 'Saldo'
	String get balanceLabel => 'Saldo';

	/// id: 'Pilih kategori'
	String get categoryPlaceholder => 'Pilih kategori';

	/// id: 'Tanpa kategori'
	String get categoryNoneLabel => 'Tanpa kategori';

	/// id: 'Pos anggaran'
	String get budgetItemLabel => 'Pos anggaran';

	/// id: 'Tanpa anggaran'
	String get budgetItemNone => 'Tanpa anggaran';

	/// id: 'Opsional. Hanya pos anggaran yang cocok dengan dompet di atas dan periodenya mencakup tanggal transaksi yang ditawarkan.'
	String get budgetItemHelp => 'Opsional. Hanya pos anggaran yang cocok dengan dompet di atas dan periodenya mencakup tanggal transaksi yang ditawarkan.';

	/// id: 'Tanggal ini di luar periode anggaran "$name", jadi transaksi ini tidak lagi masuk anggaran itu.'
	String budgetItemOutOfPeriod({required Object name}) => 'Tanggal ini di luar periode anggaran "${name}", jadi transaksi ini tidak lagi masuk anggaran itu.';

	/// id: 'Honor freelance?'
	String get freelanceCalloutTitle => 'Honor freelance?';

	/// id: 'Catat lewat Freelance'
	String get freelanceCalloutAction => 'Catat lewat Freelance';

	/// id: 'Jenis transaksi'
	String get kindSwitcherLabel => 'Jenis transaksi';

	/// id: 'Keluar'
	String get kindExpense => 'Keluar';

	/// id: 'Masuk'
	String get kindIncome => 'Masuk';

	/// id: 'Transfer'
	String get kindTransfer => 'Transfer';

	/// id: 'Tambah kategori'
	String get categoryAddLabel => 'Tambah kategori';

	/// id: 'Tertangkap'
	String get draftHeardLabel => 'Tertangkap';

	/// id: 'Periksa sebelum mencatat'
	String get draftCheckTitle => 'Periksa sebelum mencatat';

	late final Translations$record$draftIssue$id draftIssue = Translations$record$draftIssue$id.internal(_root);
	late final Translations$record$voice$id voice = Translations$record$voice$id.internal(_root);
	late final Translations$record$repeat$id repeat = Translations$record$repeat$id.internal(_root);
}

// Path: transaction
class Translations$transaction$id {
	Translations$transaction$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Riwayat'
	String get pageTitle => 'Riwayat';

	/// id: 'Cari di bulan ini: catatan / kategori...'
	String get searchHint => 'Cari di bulan ini: catatan / kategori...';

	/// id: 'Status log bulan ini'
	String get monthStatusLabel => 'Status log bulan ini';

	/// id: '$count log aktif'
	String logCountBadge({required Object count}) => '${count} log aktif';

	/// id: 'Arus Bersih (Netto)'
	String get netFlowLabel => 'Arus Bersih (Netto)';

	/// id: 'Masuk'
	String get flowIncomeLabel => 'Masuk';

	/// id: 'Keluar'
	String get flowExpenseLabel => 'Keluar';

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

	/// id: 'Filter'
	String get filterButtonLabel => 'Filter';

	/// id: 'Filter Transaksi'
	String get filterSheetTitle => 'Filter Transaksi';

	/// id: 'Selesai'
	String get filterSheetDoneAction => 'Selesai';

	/// id: 'Hari Ini'
	String get todayLabel => 'Hari Ini';

	/// id: 'Kemarin'
	String get yesterdayLabel => 'Kemarin';

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

	/// id: 'Riwayat lengkapmu, tersimpan aman di perangkatmu'
	String get trustFooterMessage => 'Riwayat lengkapmu, tersimpan aman di perangkatmu';

	/// id: 'Tidak ada transaksi bulan ini yang cocok dengan filter'
	String get emptyFilterTitle => 'Tidak ada transaksi bulan ini yang cocok dengan filter';

	/// id: 'Pencarian dan filter hanya mencakup bulan yang sedang dibuka. Ganti bulan, atau ganti dan hapus filter.'
	String get emptyFilterSubtitle => 'Pencarian dan filter hanya mencakup bulan yang sedang dibuka. Ganti bulan, atau ganti dan hapus filter.';

	/// id: 'Hapus filter'
	String get clearFiltersButton => 'Hapus filter';

	/// id: 'Cari di bulan lain'
	String get crossMonthSearchButton => 'Cari di bulan lain';

	/// id: 'Mencari di bulan sebelumnya...'
	String get crossMonthSearchingLabel => 'Mencari di bulan sebelumnya...';

	/// id: 'Ditemukan di bulan lain'
	String get crossMonthResultsHeader => 'Ditemukan di bulan lain';

	/// id: 'Cari lebih jauh'
	String get crossMonthLoadMoreButton => 'Cari lebih jauh';

	/// id: 'Tidak ditemukan di bulan-bulan sebelumnya.'
	String get crossMonthNoMoreResults => 'Tidak ditemukan di bulan-bulan sebelumnya.';

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

	/// id: 'Catatan'
	String get detailNoteLabel => 'Catatan';

	/// id: 'Dari'
	String get detailFromLabel => 'Dari';

	/// id: 'Ke'
	String get detailToLabel => 'Ke';

	/// id: 'Jumlah'
	String get detailAmountLabel => 'Jumlah';

	/// id: 'Tersimpan aman di perangkatmu. Saldo dompet mengikuti setiap catatan, jadi saat kamu menyunting atau menghapusnya, saldonya ikut menyesuaikan.'
	String get detailManualNote => 'Tersimpan aman di perangkatmu. Saldo dompet mengikuti setiap catatan, jadi saat kamu menyunting atau menghapusnya, saldonya ikut menyesuaikan.';

	/// id: 'Ubah Catatan Ini'
	String get editAction => 'Ubah Catatan Ini';

	/// id: 'Catat Lagi'
	String get recordAgainAction => 'Catat Lagi';

	/// id: 'Hapus Catatan dari Riwayat'
	String get deleteAction => 'Hapus Catatan dari Riwayat';

	/// id: 'Ubah Catatan'
	String get editSheetTitle => 'Ubah Catatan';

	/// id: 'Simpan Perubahan'
	String get saveChangesAction => 'Simpan Perubahan';

	/// id: 'Perubahan tersimpan.'
	String get updatedMessage => 'Perubahan tersimpan.';

	/// id: 'Catatan dihapus.'
	String get deletedMessage => 'Catatan dihapus.';

	/// id: 'Urungkan'
	String get undoDeleteAction => 'Urungkan';

	/// id: 'Catatan dikembalikan.'
	String get restoredMessage => 'Catatan dikembalikan.';

	/// id: 'Anggaran'
	String get budgetLabel => 'Anggaran';

	/// id: 'Lihat anggaran'
	String get openBudgetAction => 'Lihat anggaran';

	/// id: 'Pemasukan ini dicatat dari pembayaran freelance. Untuk mengubahnya, batalkan penerimaannya di Freelance.'
	String get detailFreelanceNote => 'Pemasukan ini dicatat dari pembayaran freelance. Untuk mengubahnya, batalkan penerimaannya di Freelance.';

	/// id: 'Jadikan Rutin'
	String get makeRecurringAction => 'Jadikan Rutin';
}

// Path: wallet
class Translations$wallet$id {
	Translations$wallet$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Posisi saldo kas saat ini'
	String get subtitle => 'Posisi saldo kas saat ini';

	/// id: '$count kantong aktif'
	String activeBadge({required Object count}) => '${count} kantong aktif';

	/// id: 'Total saldo semua dompet'
	String get totalLabel => 'Total saldo semua dompet';

	/// id: 'Daftar Dompet'
	String get listHeading => 'Daftar Dompet';

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

	/// id: 'Saldo awal adalah uang di dompet ini sekarang, titik mulai pencatatanmu. Setiap transaksi berikutnya dihitung dari sini.'
	String get initialBalanceHelp => 'Saldo awal adalah uang di dompet ini sekarang, titik mulai pencatatanmu. Setiap transaksi berikutnya dihitung dari sini.';

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

	/// id: 'Pemasukan'
	String get detailIncomeLabel => 'Pemasukan';

	/// id: 'Pengeluaran'
	String get detailExpenseLabel => 'Pengeluaran';

	/// id: 'Belum ada transaksi'
	String get detailRecentEmptyTitle => 'Belum ada transaksi';

	/// id: 'Belum ada transaksi bulan ini untuk dompet ini.'
	String get detailRecentEmpty => 'Belum ada transaksi bulan ini untuk dompet ini.';

	/// id: 'Lihat Semua Transaksi'
	String get detailViewAllAction => 'Lihat Semua Transaksi';

	/// id: 'Catat Transaksi Dompet Ini'
	String get detailRecordAction => 'Catat Transaksi Dompet Ini';

	/// id: 'Transfer masuk'
	String get detailTransferInLabel => 'Transfer masuk';

	/// id: 'Transfer keluar'
	String get detailTransferOutLabel => 'Transfer keluar';

	/// id: 'Perubahan saldo'
	String get detailBalanceChangeLabel => 'Perubahan saldo';
}

// Path: budget
class Translations$budget$id {
	Translations$budget$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: '$count aktif'
	String activeBadge({required Object count}) => '${count} aktif';

	/// id: 'Total rencana anggaran aktif'
	String get summaryTitle => 'Total rencana anggaran aktif';

	/// id: '$percent% terpakai'
	String summaryPercent({required Object percent}) => '${percent}% terpakai';

	/// id: 'Rencana'
	String get plannedLabel => 'Rencana';

	/// id: 'Terpakai'
	String get spentLabel => 'Terpakai';

	/// id: 'Sisa'
	String get remainingLabel => 'Sisa';

	/// id: 'Terpakai ($percent%)'
	String spentPercentLabel({required Object percent}) => 'Terpakai (${percent}%)';

	/// id: 'Periode berjalan ($percent%)'
	String paceLabel({required Object percent}) => 'Periode berjalan (${percent}%)';

	/// id: 'Anggaran adalah rencana belanjamu. Angka terpakai naik setiap kali pengeluaran atau transfer yang ditautkan dicatat.'
	String get summaryNote => 'Anggaran adalah rencana belanjamu. Angka terpakai naik setiap kali pengeluaran atau transfer yang ditautkan dicatat.';

	/// id: 'Semua'
	String get filterAll => 'Semua';

	/// id: 'Aktif'
	String get filterActive => 'Aktif';

	/// id: 'Selesai'
	String get filterFinished => 'Selesai';

	/// id: 'Nonaktif'
	String get filterArchived => 'Nonaktif';

	/// id: 'Dompet'
	String get filterWalletLabel => 'Dompet';

	/// id: 'Semua dompet'
	String get filterWalletAll => 'Semua dompet';

	/// id: 'Buat Anggaran Baru'
	String get addAction => 'Buat Anggaran Baru';

	/// id: 'Mingguan'
	String get periodWeekly => 'Mingguan';

	/// id: 'Bulanan'
	String get periodMonthly => 'Bulanan';

	/// id: 'Belum terpakai'
	String get itemStatusPlanned => 'Belum terpakai';

	/// id: 'Terpakai sebagian'
	String get itemStatusPartiallySpent => 'Terpakai sebagian';

	/// id: 'Selesai'
	String get itemStatusCompleted => 'Selesai';

	/// id: 'Lewat anggaran'
	String get itemStatusOverspent => 'Lewat anggaran';

	/// id: '$count pos'
	String itemCount({required Object count}) => '${count} pos';

	/// id: 'Slot rencana kosong'
	String get emptyBadge => 'Slot rencana kosong';

	/// id: 'Belum ada anggaran'
	String get emptyTitle => 'Belum ada anggaran';

	/// id: 'Rencanakan batas belanja mingguan atau bulanan untuk satu dompet, lalu pantau berapa yang sudah terpakai.'
	String get emptyBody => 'Rencanakan batas belanja mingguan atau bulanan untuk satu dompet, lalu pantau berapa yang sudah terpakai.';

	/// id: 'Tidak ada anggaran yang cocok'
	String get emptyFilteredTitle => 'Tidak ada anggaran yang cocok';

	/// id: 'Tidak ada anggaran dengan status dan dompet yang dipilih.'
	String get emptyFilteredBody => 'Tidak ada anggaran dengan status dan dompet yang dipilih.';

	/// id: 'Tampilkan semua anggaran'
	String get resetFilterAction => 'Tampilkan semua anggaran';

	/// id: 'Buat dompet dulu'
	String get noWalletTitle => 'Buat dompet dulu';

	/// id: 'Setiap anggaran terikat ke satu dompet. Tambahkan dompet di tab Dompet, lalu kembali ke sini.'
	String get noWalletBody => 'Setiap anggaran terikat ke satu dompet. Tambahkan dompet di tab Dompet, lalu kembali ke sini.';

	/// id: 'Anggaran gagal dimuat'
	String get loadErrorTitle => 'Anggaran gagal dimuat';

	/// id: 'Data anggaran tidak bisa dibaca. Coba lagi.'
	String get loadErrorSubtitle => 'Data anggaran tidak bisa dibaca. Coba lagi.';

	/// id: 'Anggaran tersimpan.'
	String get savedMessage => 'Anggaran tersimpan.';

	/// id: 'Perubahan anggaran tersimpan.'
	String get updatedMessage => 'Perubahan anggaran tersimpan.';

	/// id: 'Anggaran dihapus.'
	String get deletedMessage => 'Anggaran dihapus.';

	/// id: 'Anggaran diarsipkan.'
	String get archivedMessage => 'Anggaran diarsipkan.';

	/// id: 'Anggaran diaktifkan kembali.'
	String get unarchivedMessage => 'Anggaran diaktifkan kembali.';

	/// id: 'Anggaran baru'
	String get addStepLabel => 'Anggaran baru';

	/// id: 'Sunting anggaran'
	String get editStepLabel => 'Sunting anggaran';

	/// id: 'Buat Anggaran'
	String get addTitle => 'Buat Anggaran';

	/// id: 'Ubah Anggaran'
	String get editTitle => 'Ubah Anggaran';

	/// id: 'Aturan Anggaran'
	String get ruleTitle => 'Aturan Anggaran';

	/// id: 'Rencana ini jadi patokan belanjamu. Saldo dompet bergerak dari transaksi yang kamu catat.'
	String get ruleBody => 'Rencana ini jadi patokan belanjamu. Saldo dompet bergerak dari transaksi yang kamu catat.';

	/// id: 'Nama anggaran'
	String get nameLabel => 'Nama anggaran';

	/// id: 'Contoh: Kebutuhan Rumah Tangga'
	String get nameHint => 'Contoh: Kebutuhan Rumah Tangga';

	/// id: 'Wajib'
	String get requiredHint => 'Wajib';

	/// id: 'Dompet terkait'
	String get walletLabel => 'Dompet terkait';

	/// id: 'Hanya pengeluaran dan transfer keluar dari dompet ini yang terhitung ke anggaran.'
	String get walletHelp => 'Hanya pengeluaran dan transfer keluar dari dompet ini yang terhitung ke anggaran.';

	/// id: 'Saldo: $amount'
	String walletBalance({required Object amount}) => 'Saldo: ${amount}';

	/// id: 'Periode'
	String get periodLabel => 'Periode';

	/// id: 'Mulai'
	String get startDateLabel => 'Mulai';

	/// id: '$start – $end'
	String periodRange({required Object start, required Object end}) => '${start} – ${end}';

	/// id: 'Pos anggaran'
	String get itemsLabel => 'Pos anggaran';

	/// id: 'Rincian rencana belanja atau rencana transfer. Total rencana anggaran adalah jumlah seluruh pos.'
	String get itemsHelp => 'Rincian rencana belanja atau rencana transfer. Total rencana anggaran adalah jumlah seluruh pos.';

	/// id: 'Tambah Pos'
	String get addItemAction => 'Tambah Pos';

	/// id: 'Simpan Anggaran'
	String get saveAddAction => 'Simpan Anggaran';

	/// id: 'Arsipkan Anggaran'
	String get archiveAction => 'Arsipkan Anggaran';

	/// id: 'Aktifkan Kembali'
	String get unarchiveAction => 'Aktifkan Kembali';

	/// id: 'Anggaran nonaktif disembunyikan dari daftar aktif. Transaksi yang tertaut tetap tercatat.'
	String get archiveHelp => 'Anggaran nonaktif disembunyikan dari daftar aktif. Transaksi yang tertaut tetap tercatat.';

	/// id: 'Hapus Anggaran'
	String get deleteAction => 'Hapus Anggaran';

	/// id: 'Hapus anggaran?'
	String get deleteConfirmTitle => 'Hapus anggaran?';

	/// id: 'Anggaran "$name" beserta posnya akan dihapus. Transaksi yang tertaut tetap tercatat dan saldo dompet tidak berubah.'
	String deleteConfirmMessage({required Object name}) => 'Anggaran "${name}" beserta posnya akan dihapus. Transaksi yang tertaut tetap tercatat dan saldo dompet tidak berubah.';

	/// id: 'Tambah Pos'
	String get itemAddTitle => 'Tambah Pos';

	/// id: 'Ubah Pos'
	String get itemEditTitle => 'Ubah Pos';

	/// id: 'Nama pos'
	String get itemNameLabel => 'Nama pos';

	/// id: 'Contoh: Beras'
	String get itemNameHint => 'Contoh: Beras';

	/// id: 'Nominal'
	String get itemModeAmount => 'Nominal';

	/// id: 'Jumlah × harga'
	String get itemModeItemized => 'Jumlah × harga';

	/// id: 'Nominal rencana'
	String get itemAmountLabel => 'Nominal rencana';

	/// id: 'Jumlah'
	String get itemQuantityLabel => 'Jumlah';

	/// id: 'Harga satuan'
	String get itemUnitPriceLabel => 'Harga satuan';

	/// id: 'Total pos'
	String get itemTotalLabel => 'Total pos';

	/// id: '$quantity × $price'
	String itemItemizedDetail({required Object quantity, required Object price}) => '${quantity} × ${price}';

	/// id: 'Simpan Pos'
	String get itemSaveAction => 'Simpan Pos';

	/// id: 'Hapus Pos'
	String get itemDeleteAction => 'Hapus Pos';

	/// id: 'Daftar Anggaran'
	String get detailBackLabel => 'Daftar Anggaran';

	/// id: 'Sunting anggaran'
	String get detailEditAction => 'Sunting anggaran';

	/// id: 'Catat Pengeluaran'
	String get detailRecordExpenseAction => 'Catat Pengeluaran';

	/// id: 'Catat Transfer'
	String get detailRecordTransferAction => 'Catat Transfer';

	/// id: 'Pos Anggaran'
	String get detailItemsHeading => 'Pos Anggaran';

	/// id: 'Anggaran ini belum punya pos. Tambahkan pos lewat Sunting supaya pengeluaran bisa ditautkan.'
	String get detailNoItems => 'Anggaran ini belum punya pos. Tambahkan pos lewat Sunting supaya pengeluaran bisa ditautkan.';

	/// id: 'Transaksi Tertaut'
	String get detailLinkedHeading => 'Transaksi Tertaut';

	/// id: 'Belum ada transaksi yang tertaut ke anggaran ini.'
	String get detailLinkedEmpty => 'Belum ada transaksi yang tertaut ke anggaran ini.';

	/// id: 'Cara kerja pos anggaran'
	String get detailHowTitle => 'Cara kerja pos anggaran';

	/// id: 'Catat lewat tombol di tiap pos. Pos pengeluaran menghitung pengeluaran dari $wallet; pos transfer menghitung transfer dari $wallet ke dompet tujuannya.'
	String detailHowBody({required Object wallet}) => 'Catat lewat tombol di tiap pos. Pos pengeluaran menghitung pengeluaran dari ${wallet}; pos transfer menghitung transfer dari ${wallet} ke dompet tujuannya.';

	/// id: 'Dompet tidak ditemukan'
	String get unknownWallet => 'Dompet tidak ditemukan';

	/// id: 'Total rencana anggaran'
	String get totalPlannedLabel => 'Total rencana anggaran';

	/// id: 'Tambahkan minimal satu pos. Transaksi dicatat ke pos, jadi anggaran tanpa pos tidak bisa melacak pengeluaran.'
	String get itemsRequiredHint => 'Tambahkan minimal satu pos. Transaksi dicatat ke pos, jadi anggaran tanpa pos tidak bisa melacak pengeluaran.';

	/// id: 'Saldo $wallet tetap'
	String walletUnchangedNote({required Object wallet}) => 'Saldo ${wallet} tetap';

	/// id: 'Jenis pos'
	String get itemKindLabel => 'Jenis pos';

	/// id: 'Pengeluaran'
	String get itemKindExpense => 'Pengeluaran';

	/// id: 'Transfer'
	String get itemKindTransfer => 'Transfer';

	/// id: 'Jenis tidak bisa diganti karena pos ini sudah punya transaksi tertaut.'
	String get itemKindLockedHint => 'Jenis tidak bisa diganti karena pos ini sudah punya transaksi tertaut.';

	/// id: 'Dompet tujuan'
	String get itemTargetWalletLabel => 'Dompet tujuan';

	/// id: 'Hanya transfer dari dompet anggaran ke dompet ini yang terhitung ke pos.'
	String get itemTargetWalletHelp => 'Hanya transfer dari dompet anggaran ke dompet ini yang terhitung ke pos.';

	/// id: 'Butuh dompet aktif lain sebagai tujuan transfer.'
	String get itemNoTargetWallet => 'Butuh dompet aktif lain sebagai tujuan transfer.';

	/// id: 'Ke $wallet'
	String itemTransferTo({required Object wallet}) => 'Ke ${wallet}';

	/// id: 'Pos transfer "$name" menuju dompet anggaran itu sendiri. Ganti dompet tujuan posnya atau dompet anggarannya.'
	String itemTargetConflict({required Object name}) => 'Pos transfer "${name}" menuju dompet anggaran itu sendiri. Ganti dompet tujuan posnya atau dompet anggarannya.';

	/// id: 'Template Anggaran'
	String get templatesAction => 'Template Anggaran';

	/// id: 'Template Anggaran'
	String get templatesTitle => 'Template Anggaran';

	/// id: '$count tersimpan'
	String templatesSavedBadge({required Object count}) => '${count} tersimpan';

	/// id: 'Apa itu template anggaran?'
	String get templatesInfoTitle => 'Apa itu template anggaran?';

	/// id: 'Susunan pos rencana yang bisa dipakai ulang tanpa mengetik dari nol. Setiap pemakaian membuat anggaran baru yang berdiri sendiri.'
	String get templatesInfoBody => 'Susunan pos rencana yang bisa dipakai ulang tanpa mengetik dari nol. Setiap pemakaian membuat anggaran baru yang berdiri sendiri.';

	/// id: '$count pos'
	String templateItemCount({required Object count}) => '${count} pos';

	/// id: 'Daftar pos rencana'
	String get templateItemsLabel => 'Daftar pos rencana';

	/// id: 'Total rencana'
	String get templateTotalLabel => 'Total rencana';

	/// id: 'Gunakan Template Ini'
	String get templateUseAction => 'Gunakan Template Ini';

	/// id: 'Ubah'
	String get templateEditAction => 'Ubah';

	/// id: 'Duplikat'
	String get templateDuplicateAction => 'Duplikat';

	/// id: 'Nonaktif'
	String get templateInactiveBadge => 'Nonaktif';

	/// id: 'Buat Template Baru'
	String get templateAddAction => 'Buat Template Baru';

	/// id: 'Template bisa disunting kapan saja tanpa mengubah anggaran yang sudah dibuat darinya.'
	String get templatesFooter => 'Template bisa disunting kapan saja tanpa mengubah anggaran yang sudah dibuat darinya.';

	/// id: 'Belum ada template'
	String get templatesEmptyBadge => 'Belum ada template';

	/// id: 'Belum ada template'
	String get templatesEmptyTitle => 'Belum ada template';

	/// id: 'Simpan susunan pos yang sering dipakai, misalnya belanja bulanan, supaya anggaran berikutnya tinggal dipakai.'
	String get templatesEmptyBody => 'Simpan susunan pos yang sering dipakai, misalnya belanja bulanan, supaya anggaran berikutnya tinggal dipakai.';

	/// id: 'Buat dompet aktif dulu untuk memakai template.'
	String get templateNeedsWallet => 'Buat dompet aktif dulu untuk memakai template.';

	/// id: 'Template gagal dimuat'
	String get templatesLoadError => 'Template gagal dimuat';

	/// id: 'Template anggaran'
	String get templateStepLabel => 'Template anggaran';

	/// id: 'Buat Template'
	String get templateAddTitle => 'Buat Template';

	/// id: 'Ubah Template'
	String get templateEditTitle => 'Ubah Template';

	/// id: 'Template menyimpan susunan pos rencanamu. Dompet dan periodenya dipilih saat template dipakai.'
	String get templateRuleBody => 'Template menyimpan susunan pos rencanamu. Dompet dan periodenya dipilih saat template dipakai.';

	/// id: 'Contoh: Belanja bulanan'
	String get templateNameHint => 'Contoh: Belanja bulanan';

	/// id: 'Tawarkan template ini'
	String get templateEnabledLabel => 'Tawarkan template ini';

	/// id: 'Template nonaktif tetap tersimpan, tapi tidak bisa dipakai membuat anggaran.'
	String get templateEnabledHelp => 'Template nonaktif tetap tersimpan, tapi tidak bisa dipakai membuat anggaran.';

	/// id: 'Simpan Template'
	String get templateSaveAction => 'Simpan Template';

	/// id: 'Hapus Template'
	String get templateDeleteAction => 'Hapus Template';

	/// id: 'Hapus template?'
	String get templateDeleteConfirmTitle => 'Hapus template?';

	/// id: 'Template "$name" akan dihapus. Anggaran yang pernah dibuat darinya tidak ikut terhapus.'
	String templateDeleteConfirmMessage({required Object name}) => 'Template "${name}" akan dihapus. Anggaran yang pernah dibuat darinya tidak ikut terhapus.';

	/// id: 'Template tersimpan.'
	String get templateSavedMessage => 'Template tersimpan.';

	/// id: 'Perubahan template tersimpan.'
	String get templateUpdatedMessage => 'Perubahan template tersimpan.';

	/// id: 'Template dihapus.'
	String get templateDeletedMessage => 'Template dihapus.';

	/// id: 'Template digandakan.'
	String get templateDuplicatedMessage => 'Template digandakan.';

	/// id: '$name (salinan)'
	String templateCopyName({required Object name}) => '${name} (salinan)';

	/// id: 'Dari template $name'
	String fromTemplateStepLabel({required Object name}) => 'Dari template ${name}';

	/// id: 'Nama template'
	String get templateNameLabel => 'Nama template';

	/// id: 'Ulangi tiap periode'
	String get repeatLabel => 'Ulangi tiap periode';

	/// id: 'Lahir lagi tiap bulan mulai $date dengan pos yang sama.'
	String repeatHelpMonthly({required Object date}) => 'Lahir lagi tiap bulan mulai ${date} dengan pos yang sama.';

	/// id: 'Lahir lagi tiap minggu mulai $date dengan pos yang sama.'
	String repeatHelpWeekly({required Object date}) => 'Lahir lagi tiap minggu mulai ${date} dengan pos yang sama.';

	/// id: 'Anggaran bulanan bisa diulang bila mulai tanggal 1–28.'
	String get repeatUnavailable => 'Anggaran bulanan bisa diulang bila mulai tanggal 1–28.';

	/// id: 'Periode ini sudah lewat. Perubahannya tidak memengaruhi periode berikutnya.'
	String get repeatPastNote => 'Periode ini sudah lewat. Perubahannya tidak memengaruhi periode berikutnya.';

	/// id: 'Berlaku untuk'
	String get scopeTitle => 'Berlaku untuk';

	/// id: 'Hanya periode ini'
	String get scopeThisPeriod => 'Hanya periode ini';

	/// id: 'Periode ini dan berikutnya'
	String get scopeThisAndNext => 'Periode ini dan berikutnya';

	/// id: 'Rutin'
	String get recurringBadge => 'Rutin';

	/// id: 'Ulangi tiap bulan · $wallet'
	String templateScheduledMonthly({required Object wallet}) => 'Ulangi tiap bulan · ${wallet}';

	/// id: 'Ulangi tiap minggu · $wallet'
	String templateScheduledWeekly({required Object wallet}) => 'Ulangi tiap minggu · ${wallet}';
}

// Path: freelance
class Translations$freelance$id {
	Translations$freelance$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Freelance'
	String get title => 'Freelance';

	/// id: 'Worklog ($count)'
	String worklogTab({required Object count}) => 'Worklog (${count})';

	/// id: 'Pembayaran ($count)'
	String paymentsTab({required Object count}) => 'Pembayaran (${count})';

	/// id: 'Data freelance gagal dimuat'
	String get loadErrorTitle => 'Data freelance gagal dimuat';

	/// id: 'Aturan kas freelance'
	String get ruleTitle => 'Aturan kas freelance';

	/// id: 'Jam kerja terkumpul jadi tagihan, dan saldo dompet bertambah saat pembayarannya dicatat diterima.'
	String get ruleBody => 'Jam kerja terkumpul jadi tagihan, dan saldo dompet bertambah saat pembayarannya dicatat diterima.';

	/// id: 'Ringkasan upah & jam'
	String get summaryTitle => 'Ringkasan upah & jam';

	/// id: 'Waktu kerja'
	String get totalHoursLabel => 'Waktu kerja';

	/// id: '$hours jam'
	String hoursValue({required Object hours}) => '${hours} jam';

	/// id: 'jam'
	String get hourShort => 'jam';

	/// id: '$count proyek'
	String projectCount({required Object count}) => '${count} proyek';

	/// id: 'Total diperoleh'
	String get earnedLabel => 'Total diperoleh';

	/// id: 'Jam × tarif, sebelum potongan'
	String get earnedCaption => 'Jam × tarif, sebelum potongan';

	/// id: 'Sudah diterima'
	String get paidLabel => 'Sudah diterima';

	/// id: 'Gaji kotor · pembayarannya sudah dicatat'
	String get paidCaption => 'Gaji kotor · pembayarannya sudah dicatat';

	/// id: 'Belum diterima'
	String get unpaidLabel => 'Belum diterima';

	/// id: 'Gaji kotor · belum ditagih atau tertunda'
	String get unpaidCaption => 'Gaji kotor · belum ditagih atau tertunda';

	/// id: '$percent% sudah diterima'
	String paidRatio({required Object percent}) => '${percent}% sudah diterima';

	/// id: 'Proyek'
	String get projectsLabel => 'Proyek';

	/// id: 'Belum ada proyek. Tambahkan klien atau proyek beserta tarif per jamnya dulu.'
	String get projectsEmpty => 'Belum ada proyek. Tambahkan klien atau proyek beserta tarif per jamnya dulu.';

	/// id: 'Proyek freelance'
	String get projectStepLabel => 'Proyek freelance';

	/// id: 'Tambah Proyek'
	String get projectAddTitle => 'Tambah Proyek';

	/// id: 'Ubah Proyek'
	String get projectEditTitle => 'Ubah Proyek';

	/// id: 'Nama klien atau proyek'
	String get projectNameLabel => 'Nama klien atau proyek';

	/// id: 'Contoh: Studio Koding'
	String get projectNameHint => 'Contoh: Studio Koding';

	/// id: 'Wajib'
	String get requiredHint => 'Wajib';

	/// id: 'Tarif per jam'
	String get hourlyRateLabel => 'Tarif per jam';

	/// id: 'Tarif bawaan untuk entri baru. Mengubahnya tidak mengubah entri yang sudah dicatat.'
	String get hourlyRateHelp => 'Tarif bawaan untuk entri baru. Mengubahnya tidak mengubah entri yang sudah dicatat.';

	/// id: 'Potongan'
	String get deductionsLabel => 'Potongan';

	/// id: 'Dipotong dari gaji kotor setiap pembayaran, misalnya pajak. Mengubahnya tidak mengubah pembayaran yang sudah dibuat.'
	String get deductionsHelp => 'Dipotong dari gaji kotor setiap pembayaran, misalnya pajak. Mengubahnya tidak mengubah pembayaran yang sudah dibuat.';

	/// id: 'Tambah potongan'
	String get deductionAddAction => 'Tambah potongan';

	/// id: 'Potongan'
	String get deductionTitle => 'Potongan';

	/// id: 'Nama potongan'
	String get deductionLabelLabel => 'Nama potongan';

	/// id: 'Contoh: Pajak'
	String get deductionLabelHint => 'Contoh: Pajak';

	/// id: 'Persen'
	String get deductionKindPercentage => 'Persen';

	/// id: 'Nominal tetap'
	String get deductionKindFixed => 'Nominal tetap';

	/// id: 'Persen dari gaji kotor'
	String get deductionPercentLabel => 'Persen dari gaji kotor';

	/// id: 'Paling banyak satu angka di belakang koma, misalnya 2,5.'
	String get deductionPercentHelp => 'Paling banyak satu angka di belakang koma, misalnya 2,5.';

	/// id: 'Nominal per pembayaran'
	String get deductionAmountLabel => 'Nominal per pembayaran';

	/// id: 'Simpan potongan'
	String get deductionSaveAction => 'Simpan potongan';

	/// id: 'Hapus potongan'
	String get deductionRemoveAction => 'Hapus potongan';

	/// id: 'Simpan proyek'
	String get projectSaveAction => 'Simpan proyek';

	/// id: 'Hapus proyek'
	String get projectDeleteAction => 'Hapus proyek';

	/// id: 'Proyek yang sudah punya entri worklog tidak bisa dihapus.'
	String get projectDeleteLockedHint => 'Proyek yang sudah punya entri worklog tidak bisa dihapus.';

	/// id: 'Hapus proyek?'
	String get projectDeleteConfirmTitle => 'Hapus proyek?';

	/// id: 'Proyek "$name" akan dihapus.'
	String projectDeleteConfirmMessage({required Object name}) => 'Proyek "${name}" akan dihapus.';

	/// id: 'Proyek ini sudah punya entri worklog, jadi tidak bisa dihapus.'
	String get projectDeleteRefused => 'Proyek ini sudah punya entri worklog, jadi tidak bisa dihapus.';

	/// id: 'Proyek tersimpan.'
	String get projectSavedMessage => 'Proyek tersimpan.';

	/// id: 'Perubahan proyek tersimpan.'
	String get projectUpdatedMessage => 'Perubahan proyek tersimpan.';

	/// id: 'Proyek dihapus.'
	String get projectDeletedMessage => 'Proyek dihapus.';

	/// id: 'Proyek'
	String get projectLabel => 'Proyek';

	/// id: 'Pilih proyek'
	String get projectPick => 'Pilih proyek';

	/// id: 'Log pekerjaan'
	String get entryStepLabel => 'Log pekerjaan';

	/// id: 'Tambah Worklog'
	String get entryAddTitle => 'Tambah Worklog';

	/// id: 'Ubah Worklog'
	String get entryEditTitle => 'Ubah Worklog';

	/// id: 'Jam kerja terkumpul jadi tagihan. Uangnya masuk ke saldo saat pembayarannya dicatat diterima.'
	String get entryRuleBody => 'Jam kerja terkumpul jadi tagihan. Uangnya masuk ke saldo saat pembayarannya dicatat diterima.';

	/// id: 'Tanggal kerja'
	String get workDateLabel => 'Tanggal kerja';

	/// id: 'Durasi pengerjaan'
	String get hoursLabel => 'Durasi pengerjaan';

	/// id: 'Terisi dari tarif proyek. Ubah kalau tarif entri ini berbeda.'
	String get entryRateHelp => 'Terisi dari tarif proyek. Ubah kalau tarif entri ini berbeda.';

	/// id: 'Catatan'
	String get noteLabel => 'Catatan';

	/// id: 'Apa yang dikerjakan (opsional)'
	String get noteHint => 'Apa yang dikerjakan (opsional)';

	/// id: 'Simpan Worklog'
	String get entrySaveAction => 'Simpan Worklog';

	/// id: 'Nominal ini tercatat sebagai diperoleh, belum diterima.'
	String get entrySaveHint => 'Nominal ini tercatat sebagai diperoleh, belum diterima.';

	/// id: 'Hapus entri'
	String get entryDeleteAction => 'Hapus entri';

	/// id: 'Hapus entri worklog?'
	String get entryDeleteConfirmTitle => 'Hapus entri worklog?';

	/// id: 'Entri ini akan dihapus. Saldo dompet tidak berubah.'
	String get entryDeleteConfirmMessage => 'Entri ini akan dihapus. Saldo dompet tidak berubah.';

	/// id: 'Entri yang sudah masuk pembayaran tidak bisa diubah atau dihapus.'
	String get entryLockedMessage => 'Entri yang sudah masuk pembayaran tidak bisa diubah atau dihapus.';

	/// id: 'Worklog tersimpan.'
	String get entrySavedMessage => 'Worklog tersimpan.';

	/// id: 'Perubahan worklog tersimpan.'
	String get entryUpdatedMessage => 'Perubahan worklog tersimpan.';

	/// id: 'Worklog dihapus.'
	String get entryDeletedMessage => 'Worklog dihapus.';

	/// id: '$hours jam × $rate'
	String hoursTimesRate({required Object hours, required Object rate}) => '${hours} jam × ${rate}';

	/// id: 'Belum ditagih'
	String get statusUnbilled => 'Belum ditagih';

	/// id: 'Tertunda'
	String get statusPending => 'Tertunda';

	/// id: 'Diterima'
	String get statusPaid => 'Diterima';

	/// id: 'Perkiraan diterima $date'
	String expectedOn({required Object date}) => 'Perkiraan diterima ${date}';

	/// id: 'Diterima $date di $wallet'
	String receivedOn({required Object date, required Object wallet}) => 'Diterima ${date} di ${wallet}';

	/// id: 'Proyek terhapus'
	String get unknownProject => 'Proyek terhapus';

	/// id: 'dompet terhapus'
	String get unknownWallet => 'dompet terhapus';

	/// id: 'Tertunda (bersih)'
	String get pendingTotalLabel => 'Tertunda (bersih)';

	/// id: 'Diterima (bersih)'
	String get paidTotalLabel => 'Diterima (bersih)';

	/// id: '$count pembayaran'
	String paymentCount({required Object count}) => '${count} pembayaran';

	/// id: 'Pembayaran freelance'
	String get paymentStepLabel => 'Pembayaran freelance';

	/// id: 'Buat Pembayaran'
	String get paymentAddTitle => 'Buat Pembayaran';

	/// id: 'Pembayaran mengelompokkan jam kerja jadi satu tagihan. Saat dicatat diterima, saldo dompet bertambah.'
	String get paymentCreateRuleBody => 'Pembayaran mengelompokkan jam kerja jadi satu tagihan. Saat dicatat diterima, saldo dompet bertambah.';

	/// id: 'Entri ditagih: $count ($hours jam)'
	String paymentEntriesLabel({required Object count, required Object hours}) => 'Entri ditagih: ${count} (${hours} jam)';

	/// id: '$count entri · $hours jam'
	String paymentEntriesSummary({required Object count, required Object hours}) => '${count} entri · ${hours} jam';

	/// id: 'Perkiraan tanggal diterima'
	String get expectedDateLabel => 'Perkiraan tanggal diterima';

	/// id: 'Gaji kotor'
	String get grossPayLabel => 'Gaji kotor';

	/// id: 'Gaji bersih'
	String get netPayLabel => 'Gaji bersih';

	/// id: 'Potongan tidak boleh sama dengan atau melebihi gaji kotor.'
	String get netPayNotPositive => 'Potongan tidak boleh sama dengan atau melebihi gaji kotor.';

	/// id: 'Buat Pembayaran'
	String get paymentCreateAction => 'Buat Pembayaran';

	/// id: 'Ubah tanggal'
	String get paymentChangeDateAction => 'Ubah tanggal';

	/// id: 'Hapus'
	String get paymentDeleteAction => 'Hapus';

	/// id: 'Hapus pembayaran?'
	String get paymentDeleteConfirmTitle => 'Hapus pembayaran?';

	/// id: 'Pembayaran tertunda ini dihapus dan entrinya kembali belum ditagih. Saldo dompet tidak berubah.'
	String get paymentDeleteConfirmMessage => 'Pembayaran tertunda ini dihapus dan entrinya kembali belum ditagih. Saldo dompet tidak berubah.';

	/// id: 'Entri yang dipilih sudah ditagih atau bukan milik proyek ini.'
	String get paymentEntriesInvalid => 'Entri yang dipilih sudah ditagih atau bukan milik proyek ini.';

	/// id: 'Pembayaran yang sudah diterima tidak bisa dihapus. Batalkan penerimaannya dulu.'
	String get paymentPaidLocked => 'Pembayaran yang sudah diterima tidak bisa dihapus. Batalkan penerimaannya dulu.';

	/// id: 'Pembayaran ini sudah dicatat diterima.'
	String get paymentAlreadyPaid => 'Pembayaran ini sudah dicatat diterima.';

	/// id: 'Pembayaran dibuat.'
	String get paymentCreatedMessage => 'Pembayaran dibuat.';

	/// id: 'Tanggal pembayaran diperbarui.'
	String get paymentUpdatedMessage => 'Tanggal pembayaran diperbarui.';

	/// id: 'Pembayaran dihapus.'
	String get paymentDeletedMessage => 'Pembayaran dihapus.';

	/// id: 'Catat Pembayaran Diterima'
	String get receiveTitle => 'Catat Pembayaran Diterima';

	/// id: 'Honor sudah masuk'
	String get receiveRuleTitle => 'Honor sudah masuk';

	/// id: 'Catat saat uangnya sudah kamu terima. Saldo dompet pilihan bertambah sebesar gaji bersih, dan tagihan ini tercatat lunas.'
	String get receiveRuleBody => 'Catat saat uangnya sudah kamu terima. Saldo dompet pilihan bertambah sebesar gaji bersih, dan tagihan ini tercatat lunas.';

	/// id: 'Nominal diterima'
	String get receiveAmountLabel => 'Nominal diterima';

	/// id: 'Dompet penerima'
	String get receiveWalletLabel => 'Dompet penerima';

	/// id: 'Tanggal diterima'
	String get receiveDateLabel => 'Tanggal diterima';

	/// id: 'Pembayaran freelance $project'
	String receiveNoteDefault({required Object project}) => 'Pembayaran freelance ${project}';

	/// id: 'Catat Diterima'
	String get receiveAction => 'Catat Diterima';

	/// id: 'Pembayaran dicatat diterima. Saldo dompet bertambah.'
	String get paymentReceivedMessage => 'Pembayaran dicatat diterima. Saldo dompet bertambah.';

	/// id: 'Batalkan penerimaan'
	String get receiptCancelAction => 'Batalkan penerimaan';

	/// id: 'Batalkan penerimaan?'
	String get receiptCancelConfirmTitle => 'Batalkan penerimaan?';

	/// id: 'Catatan pemasukannya dihapus dan saldo dompet berkurang kembali. Pembayaran kembali tertunda.'
	String get receiptCancelConfirmMessage => 'Catatan pemasukannya dihapus dan saldo dompet berkurang kembali. Pembayaran kembali tertunda.';

	/// id: 'Penerimaan dibatalkan. Pembayaran kembali tertunda.'
	String get receiptCancelledMessage => 'Penerimaan dibatalkan. Pembayaran kembali tertunda.';

	/// id: 'Ubah'
	String get changeAction => 'Ubah';

	/// id: 'Hapus pemasukan'
	String get receiptCancelConfirmAction => 'Hapus pemasukan';

	/// id: 'Tagih ($count)'
	String billAction({required Object count}) => 'Tagih (${count})';

	/// id: 'Belum ada jam kerja'
	String get entriesEmptyBadge => 'Belum ada jam kerja';

	/// id: 'Belum ada worklog'
	String get entriesEmptyTitle => 'Belum ada worklog';

	/// id: 'Catat jam kerja proyek ini lewat tombol + Worklog di bawah.'
	String get entriesEmptyBody => 'Catat jam kerja proyek ini lewat tombol + Worklog di bawah.';

	/// id: 'Tidak ada entri dengan status ini.'
	String get entriesFilteredEmpty => 'Tidak ada entri dengan status ini.';

	/// id: '+ Worklog'
	String get entryAddShortAction => '+ Worklog';

	/// id: '$count entri'
	String entryCountLabel({required Object count}) => '${count} entri';

	/// id: 'Semua'
	String get filterAll => 'Semua';

	/// id: 'Terakhir $date'
	String lastEntryOn({required Object date}) => 'Terakhir ${date}';

	/// id: 'Tanpa potongan'
	String get noDeductions => 'Tanpa potongan';

	/// id: 'Belum ada entri'
	String get noEntriesYet => 'Belum ada entri';

	/// id: 'Total $hours jam · $amount'
	String projectTotals({required Object hours, required Object amount}) => 'Total ${hours} jam · ${amount}';

	/// id: 'Slot proyek kosong'
	String get projectsEmptyBadge => 'Slot proyek kosong';

	/// id: 'Belum ada proyek'
	String get projectsEmptyTitle => 'Belum ada proyek';

	/// id: 'Belum ditagih'
	String get unbilledLabel => 'Belum ditagih';

	/// id: 'Semua sudah ditagih'
	String get unbilledNone => 'Semua sudah ditagih';

	/// id: 'Belum ada tagihan'
	String get paymentsEmptyBadge => 'Belum ada tagihan';

	/// id: 'Belum ada pembayaran'
	String get paymentsEmptyTitle => 'Belum ada pembayaran';

	/// id: 'Tekan Tagih di bawah untuk mengelompokkan jam kerja yang belum ditagih jadi satu pembayaran.'
	String get paymentsEmptyBody => 'Tekan Tagih di bawah untuk mengelompokkan jam kerja yang belum ditagih jadi satu pembayaran.';

	/// id: 'Tidak ada pembayaran dengan status ini.'
	String get paymentsFilteredEmpty => 'Tidak ada pembayaran dengan status ini.';

	/// id: '$count tagihan · terdekat $date'
	String nextExpected({required Object count, required Object date}) => '${count} tagihan · terdekat ${date}';

	/// id: 'Kerja $range'
	String paymentWorkRange({required Object range}) => 'Kerja ${range}';
}

// Path: home
class Translations$home$id {
	Translations$home$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Beranda gagal dimuat'
	String get loadErrorTitle => 'Beranda gagal dimuat';

	/// id: 'Total kas aktif'
	String get balanceLabel => 'Total kas aktif';

	/// id: '$count dompet aktif'
	String walletCount({required Object count}) => '${count} dompet aktif';

	/// id: '+$count lainnya'
	String moreWallets({required Object count}) => '+${count} lainnya';

	/// id: 'Mulai catat'
	String get startBadge => 'Mulai catat';

	/// id: 'Belum ada saldo dompet yang tercatat.'
	String get noWalletsBody => 'Belum ada saldo dompet yang tercatat.';

	/// id: 'Pemasukan $month'
	String incomeLabel({required Object month}) => 'Pemasukan ${month}';

	/// id: 'Pengeluaran $month'
	String expenseLabel({required Object month}) => 'Pengeluaran ${month}';

	/// id: 'Anggaran aktif'
	String get budgetTitle => 'Anggaran aktif';

	/// id: 'Sisa'
	String get budgetRemaining => 'Sisa';

	/// id: 'Lewat rencana'
	String get budgetOver => 'Lewat rencana';

	/// id: 'Lihat Anggaran'
	String get budgetAction => 'Lihat Anggaran';

	/// id: 'Freelance'
	String get freelanceTitle => 'Freelance';

	/// id: 'Diterima: $amount'
	String freelancePaid({required Object amount}) => 'Diterima: ${amount}';

	/// id: 'Lihat Freelance'
	String get freelanceAction => 'Lihat Freelance';

	/// id: 'Transaksi terbaru'
	String get recentTitle => 'Transaksi terbaru';

	/// id: 'Lihat semua'
	String get seeAll => 'Lihat semua';

	/// id: 'Inventaris kosong'
	String get emptyBadge => 'Inventaris kosong';

	/// id: 'Belum ada transaksi'
	String get emptyTitle => 'Belum ada transaksi';

	/// id: 'Mulai dengan mencatat pemasukan, pengeluaran, atau transfer pertamamu.'
	String get emptyBody => 'Mulai dengan mencatat pemasukan, pengeluaran, atau transfer pertamamu.';

	/// id: 'Buat dompet pertamamu beserta saldo awalnya dulu, lalu catat transaksi pertama.'
	String get emptyNoWalletBody => 'Buat dompet pertamamu beserta saldo awalnya dulu, lalu catat transaksi pertama.';

	/// id: 'Catat Transaksi'
	String get recordAction => 'Catat Transaksi';

	/// id: 'Buat Dompet Pertama'
	String get createWalletAction => 'Buat Dompet Pertama';

	/// id: 'Atau buat anggaran pengeluaran'
	String get budgetLink => 'Atau buat anggaran pengeluaran';

	/// id: 'Panduan singkat'
	String get guideTitle => 'Panduan singkat';

	/// id: '3 aturan utama'
	String get guideCount => '3 aturan utama';

	/// id: 'Dompet'
	String get guideWalletTitle => 'Dompet';

	/// id: 'Aset nyata'
	String get guideWalletTag => 'Aset nyata';

	/// id: 'Catat rekening bank, dompet digital, atau uang tunai beserta saldonya saat ini.'
	String get guideWalletBody => 'Catat rekening bank, dompet digital, atau uang tunai beserta saldonya saat ini.';

	/// id: 'Anggaran'
	String get guideBudgetTitle => 'Anggaran';

	/// id: 'Rencana'
	String get guideBudgetTag => 'Rencana';

	/// id: 'Rencanakan batas belanja dan pantau berapa yang sudah terpakai.'
	String get guideBudgetBody => 'Rencanakan batas belanja dan pantau berapa yang sudah terpakai.';

	/// id: 'Freelance'
	String get guideFreelanceTitle => 'Freelance';

	/// id: 'Piutang'
	String get guideFreelanceTag => 'Piutang';

	/// id: 'Pantau jam kerja dan tagihan. Uang baru masuk ke dompet saat pembayarannya dicatat diterima.'
	String get guideFreelanceBody => 'Pantau jam kerja dan tagihan. Uang baru masuk ke dompet saat pembayarannya dicatat diterima.';

	/// id: '$spent terpakai dari $planned'
	String budgetSpentOf({required Object spent, required Object planned}) => '${spent} terpakai dari ${planned}';

	/// id: 'Belum diterima (kotor)'
	String get freelanceUnpaidTitle => 'Belum diterima (kotor)';

	/// id: 'Jatuh tempo'
	String get freelanceDueLabel => 'Jatuh tempo';

	/// id: '$count tagihan tertunda'
	String freelancePendingInvoices({required Object count}) => '${count} tagihan tertunda';

	/// id: '$hours · diperoleh $earned'
	String freelanceSummaryLine({required Object hours, required Object earned}) => '${hours} · diperoleh ${earned}';

	/// id: 'Buka $name'
	String openCard({required Object name}) => 'Buka ${name}';

	/// id: '$percent% terpakai'
	String budgetUsedBadge({required Object percent}) => '${percent}% terpakai';
}

// Path: onboarding
class Translations$onboarding$id {
	Translations$onboarding$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Lewati'
	String get skipAction => 'Lewati';

	/// id: 'Lanjut'
	String get nextAction => 'Lanjut';

	/// id: 'Tutup'
	String get closeAction => 'Tutup';

	/// id: 'Halaman $current dari $total'
	String pageIndicatorLabel({required Object current, required Object total}) => 'Halaman ${current} dari ${total}';

	/// id: 'Semua uangmu, satu buku'
	String get page1Title => 'Semua uangmu, satu buku';

	/// id: 'Lihat di mana uangmu berada, apa saja yang terjadi padanya, dan ke mana kamu merencanakannya — semuanya di buku kas pribadimu.'
	String get page1Body => 'Lihat di mana uangmu berada, apa saja yang terjadi padanya, dan ke mana kamu merencanakannya — semuanya di buku kas pribadimu.';

	/// id: 'Tahu di mana uangmu'
	String get page2Title => 'Tahu di mana uangmu';

	/// id: 'Rekening bank, e-wallet, dan uang tunai jadi dompet. Saldo tiap dompet dan totalnya selalu terlihat.'
	String get page2Body => 'Rekening bank, e-wallet, dan uang tunai jadi dompet. Saldo tiap dompet dan totalnya selalu terlihat.';

	/// id: 'Catat dalam hitungan detik'
	String get page3Title => 'Catat dalam hitungan detik';

	/// id: 'Uang masuk, keluar, atau pindah dompet — ketuk CATAT. Dompet yang biasa kamu pakai dan kategori favoritmu sudah menunggu.'
	String get page3Body => 'Uang masuk, keluar, atau pindah dompet — ketuk CATAT. Dompet yang biasa kamu pakai dan kategori favoritmu sudah menunggu.';

	/// id: 'Rencanakan, lalu pantau'
	String get page4Title => 'Rencanakan, lalu pantau';

	/// id: 'Susun anggaran per minggu atau bulan dengan pos-pos belanjamu. Saldo tetap utuh, dan kamu melihat berapa yang sudah terpakai dari rencana.'
	String get page4Body => 'Susun anggaran per minggu atau bulan dengan pos-pos belanjamu. Saldo tetap utuh, dan kamu melihat berapa yang sudah terpakai dari rencana.';

	/// id: 'Mulai dari dompet pertamamu'
	String get finalTitle => 'Mulai dari dompet pertamamu';

	/// id: 'Tambahkan satu dompet, lalu catat transaksi pertamamu. Di tiap layar, tanuki akan menunjukkan jalannya.'
	String get finalBody => 'Tambahkan satu dompet, lalu catat transaksi pertamamu. Di tiap layar, tanuki akan menunjukkan jalannya.';

	/// id: 'Buat Dompet Pertama'
	String get createWalletAction => 'Buat Dompet Pertama';

	/// id: 'Nanti saja'
	String get laterAction => 'Nanti saja';

	/// id: 'Sudah punya akun? Masuk'
	String get signInAction => 'Sudah punya akun? Masuk';

	/// id: 'Kembali'
	String get backAction => 'Kembali';

	/// id: 'Pilih mata uangmu'
	String get currencyTitle => 'Pilih mata uangmu';

	/// id: 'Semua nominal di Tanukonomy memakai mata uang ini. Nanti bisa diganti di layar Akun, tapi angka yang sudah dicatat tidak dikonversi.'
	String get currencyBody => 'Semua nominal di Tanukonomy memakai mata uang ini. Nanti bisa diganti di layar Akun, tapi angka yang sudah dicatat tidak dikonversi.';

	/// id: 'Sesuai wilayah perangkatmu'
	String get currencySuggested => 'Sesuai wilayah perangkatmu';

	/// id: 'Pilih mata uang dulu'
	String get currencyChooseFirst => 'Pilih mata uang dulu';

	/// id: 'Pakai $code'
	String currencyConfirm({required Object code}) => 'Pakai ${code}';

	/// id: 'Pilih bahasa'
	String get languageTitle => 'Pilih bahasa';

	/// id: 'Dipakai untuk tampilan aplikasi dan saat mencatat dengan suara. Bisa diubah lagi di layar Akun.'
	String get languageBody => 'Dipakai untuk tampilan aplikasi dan saat mencatat dengan suara. Bisa diubah lagi di layar Akun.';

	/// id: 'Lanjut'
	String get languageConfirm => 'Lanjut';
}

// Path: tour
class Translations$tour$id {
	Translations$tour$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Lanjut'
	String get nextAction => 'Lanjut';

	/// id: 'Selesai'
	String get doneAction => 'Selesai';

	/// id: 'Lewati tur'
	String get skipAction => 'Lewati tur';

	/// id: '$current/$total'
	String stepCounter({required Object current, required Object total}) => '${current}/${total}';

	/// id: 'Langkah $current dari $total: $title. $body'
	String stepSemantics({required Object current, required Object total, required Object title, required Object body}) => 'Langkah ${current} dari ${total}: ${title}. ${body}';

	/// id: 'Total saldo tercatat'
	String get homeBalanceTitle => 'Total saldo tercatat';

	/// id: 'Jumlah saldo semua dompet aktif — posisi uangmu dalam sekali lihat.'
	String get homeBalanceBody => 'Jumlah saldo semua dompet aktif — posisi uangmu dalam sekali lihat.';

	/// id: 'Satu pintu mencatat'
	String get homeRecordTitle => 'Satu pintu mencatat';

	/// id: 'Semua uang masuk, keluar, dan pindah dompet dicatat dari sini.'
	String get homeRecordBody => 'Semua uang masuk, keluar, dan pindah dompet dicatat dari sini.';

	/// id: 'Arus bulan ini'
	String get homeCashFlowTitle => 'Arus bulan ini';

	/// id: 'Uang yang benar-benar masuk dan keluar bulan ini.'
	String get homeCashFlowBody => 'Uang yang benar-benar masuk dan keluar bulan ini.';

	/// id: 'Sisa anggaran aktif'
	String get homeBudgetTitle => 'Sisa anggaran aktif';

	/// id: 'Sisa rencana dari anggaran yang sedang berjalan. Ketuk untuk rinciannya.'
	String get homeBudgetBody => 'Sisa rencana dari anggaran yang sedang berjalan. Ketuk untuk rinciannya.';

	/// id: 'Ringkasan freelance'
	String get homeFreelanceTitle => 'Ringkasan freelance';

	/// id: 'Penghasilan yang sudah dikerjakan dan yang masih tertunda. Saldo dompet baru bertambah saat pembayaran dicatat diterima.'
	String get homeFreelanceBody => 'Penghasilan yang sudah dikerjakan dan yang masih tertunda. Saldo dompet baru bertambah saat pembayaran dicatat diterima.';

	/// id: 'Transaksi terbaru'
	String get homeRecentTitle => 'Transaksi terbaru';

	/// id: 'Catatan terakhirmu. Ketuk salah satunya untuk rincian, atau Lihat semua untuk riwayat per bulan.'
	String get homeRecentBody => 'Catatan terakhirmu. Ketuk salah satunya untuk rincian, atau Lihat semua untuk riwayat per bulan.';

	/// id: 'Pilih jenisnya'
	String get recordKindTitle => 'Pilih jenisnya';

	/// id: 'Keluar mengurangi saldo, Masuk menambah, dan Transfer hanya memindahkan antar dompetmu — totalmu tetap.'
	String get recordKindBody => 'Keluar mengurangi saldo, Masuk menambah, dan Transfer hanya memindahkan antar dompetmu — totalmu tetap.';

	/// id: 'Honor freelance lewat jalur sendiri'
	String get recordFreelanceTitle => 'Honor freelance lewat jalur sendiri';

	/// id: 'Honor proyek dicatat sebagai pembayaran diterima di Freelance, jadi jam kerja dan tagihannya ikut lunas.'
	String get recordFreelanceBody => 'Honor proyek dicatat sebagai pembayaran diterima di Freelance, jadi jam kerja dan tagihannya ikut lunas.';

	/// id: 'Nominal'
	String get recordAmountTitle => 'Nominal';

	/// id: 'Ketik nominalnya, atau pakai tombol cepat.'
	String get recordAmountBody => 'Ketik nominalnya, atau pakai tombol cepat.';

	/// id: 'Dompet terisi otomatis'
	String get recordWalletTitle => 'Dompet terisi otomatis';

	/// id: 'Dompet terakhir yang kamu pakai sudah terpilih. Ganti kalau perlu.'
	String get recordWalletBody => 'Dompet terakhir yang kamu pakai sudah terpilih. Ganti kalau perlu.';

	/// id: 'Tautkan ke anggaran'
	String get recordBudgetItemTitle => 'Tautkan ke anggaran';

	/// id: 'Opsional. Pengeluaran yang ditautkan menambah angka terpakai pos itu, selama tanggalnya di dalam periode anggaran.'
	String get recordBudgetItemBody => 'Opsional. Pengeluaran yang ditautkan menambah angka terpakai pos itu, selama tanggalnya di dalam periode anggaran.';

	/// id: 'Total semua dompet'
	String get walletSummaryTitle => 'Total semua dompet';

	/// id: 'Jumlah saldo tercatat dompet aktif.'
	String get walletSummaryBody => 'Jumlah saldo tercatat dompet aktif.';

	/// id: 'Rincian dompet'
	String get walletCardTitle => 'Rincian dompet';

	/// id: 'Ketuk untuk melihat riwayat dompet ini dan mencatat langsung dari sana.'
	String get walletCardBody => 'Ketuk untuk melihat riwayat dompet ini dan mencatat langsung dari sana.';

	/// id: 'Tambah dompet'
	String get walletAddTitle => 'Tambah dompet';

	/// id: 'Rekening, e-wallet, atau tunai. Saldo awalnya bisa diubah kapan saja, dan saldo tercatat ikut menyesuaikan.'
	String get walletAddBody => 'Rekening, e-wallet, atau tunai. Saldo awalnya bisa diubah kapan saja, dan saldo tercatat ikut menyesuaikan.';

	/// id: 'Satu bulan per tampilan'
	String get txnMonthTitle => 'Satu bulan per tampilan';

	/// id: 'Geser bulan untuk melihat riwayat lain. Arus masuk dan keluar di sini hanya untuk bulan yang tampil.'
	String get txnMonthBody => 'Geser bulan untuk melihat riwayat lain. Arus masuk dan keluar di sini hanya untuk bulan yang tampil.';

	/// id: 'Cari dan saring'
	String get txnFilterTitle => 'Cari dan saring';

	/// id: 'Cari catatan atau kategori, lalu saring per dompet dan kategori lewat Filter. Kalau bulan ini kosong, pencarian bisa dilanjutkan ke bulan lain.'
	String get txnFilterBody => 'Cari catatan atau kategori, lalu saring per dompet dan kategori lewat Filter. Kalau bulan ini kosong, pencarian bisa dilanjutkan ke bulan lain.';

	/// id: 'Sunting atau hapus'
	String get txnRowTitle => 'Sunting atau hapus';

	/// id: 'Ketuk transaksi untuk rinciannya; dari sana bisa disunting, dicatat lagi, atau dihapus, dan saldo dihitung ulang.'
	String get txnRowBody => 'Ketuk transaksi untuk rinciannya; dari sana bisa disunting, dicatat lagi, atau dihapus, dan saldo dihitung ulang.';

	/// id: 'Sisa semua anggaran aktif'
	String get budgetSummaryTitle => 'Sisa semua anggaran aktif';

	/// id: 'Rencana dikurangi terpakai — sisa ruang belanjamu di semua anggaran aktif.'
	String get budgetSummaryBody => 'Rencana dikurangi terpakai — sisa ruang belanjamu di semua anggaran aktif.';

	/// id: 'Aktif lebih dulu'
	String get budgetFilterTitle => 'Aktif lebih dulu';

	/// id: 'Daftar menampilkan anggaran aktif. Pilih Selesai atau Nonaktif untuk melihat yang lama.'
	String get budgetFilterBody => 'Daftar menampilkan anggaran aktif. Pilih Selesai atau Nonaktif untuk melihat yang lama.';

	/// id: 'Pakai template'
	String get budgetTemplatesTitle => 'Pakai template';

	/// id: 'Simpan susunan pos yang berulang, lalu buat anggaran baru darinya.'
	String get budgetTemplatesBody => 'Simpan susunan pos yang berulang, lalu buat anggaran baru darinya.';

	/// id: 'Pos anggaran'
	String get budgetDetailItemTitle => 'Pos anggaran';

	/// id: 'Terpakai naik dari transaksi yang ditautkan ke pos ini dalam periode anggaran.'
	String get budgetDetailItemBody => 'Terpakai naik dari transaksi yang ditautkan ke pos ini dalam periode anggaran.';

	/// id: 'Catat dari pos'
	String get budgetDetailRecordTitle => 'Catat dari pos';

	/// id: 'Membuka CATAT dengan pos ini sudah terpilih.'
	String get budgetDetailRecordBody => 'Membuka CATAT dengan pos ini sudah terpilih.';

	/// id: 'Proyek dan tarif'
	String get freelanceProjectTitle => 'Proyek dan tarif';

	/// id: 'Setiap proyek punya tarif per jam dan potongan. Ketuk proyek untuk mencatat jam kerja dan pembayarannya.'
	String get freelanceProjectBody => 'Setiap proyek punya tarif per jam dan potongan. Ketuk proyek untuk mencatat jam kerja dan pembayarannya.';

	/// id: 'Jam kerja'
	String get freelanceWorklogTitle => 'Jam kerja';

	/// id: 'Jam kerja adalah penghasilan yang sudah kamu peroleh. Kumpulkan jadi tagihan, lalu catat saat dibayar.'
	String get freelanceWorklogBody => 'Jam kerja adalah penghasilan yang sudah kamu peroleh. Kumpulkan jadi tagihan, lalu catat saat dibayar.';

	/// id: 'Uang benar-benar masuk'
	String get freelanceReceiveTitle => 'Uang benar-benar masuk';

	/// id: 'Catat saat honornya masuk: saldo dompet bertambah dan tagihannya lunas.'
	String get freelanceReceiveBody => 'Catat saat honornya masuk: saldo dompet bertambah dan tagihannya lunas.';

	/// id: 'Catat pakai suara'
	String get homeVoiceTitle => 'Catat pakai suara';

	/// id: 'Ketuk, ucapkan satu transaksi, lalu periksa formulirnya sebelum dicatat.'
	String get homeVoiceBody => 'Ketuk, ucapkan satu transaksi, lalu periksa formulirnya sebelum dicatat.';

	/// id: 'Rencana'
	String get planTabsTitle => 'Rencana';

	/// id: 'Bulan ini, anggaran, dan transaksi rutin ada di sini. Ketuk untuk berpindah.'
	String get planTabsBody => 'Bulan ini, anggaran, dan transaksi rutin ada di sini. Ketuk untuk berpindah.';

	/// id: 'Uang nganggur'
	String get planUnplannedTitle => 'Uang nganggur';

	/// id: 'Pemasukan bulan ini dikurangi semua yang sudah terikat.'
	String get planUnplannedBody => 'Pemasukan bulan ini dikurangi semua yang sudah terikat.';

	/// id: 'Saldo dompet ≈'
	String get planForecastTitle => 'Saldo dompet ≈';

	/// id: 'Perkiraan saldo sampai akhir bulan, termasuk titik paling tipisnya.'
	String get planForecastBody => 'Perkiraan saldo sampai akhir bulan, termasuk titik paling tipisnya.';

	/// id: 'Perkiraan saldo'
	String get homeForecastTitle => 'Perkiraan saldo';

	/// id: 'Saldo dompet perkiraan di akhir bulan dan titik paling tipisnya. Ketuk untuk rinciannya di Rencana.'
	String get homeForecastBody => 'Saldo dompet perkiraan di akhir bulan dan titik paling tipisnya. Ketuk untuk rinciannya di Rencana.';

	/// id: 'Menunggu dicatat'
	String get homePendingTitle => 'Menunggu dicatat';

	/// id: 'Tagihan dan pemasukan rutin yang sudah tiba. Catat satu ketuk, ubah dulu, atau Lewati.'
	String get homePendingBody => 'Tagihan dan pemasukan rutin yang sudah tiba. Catat satu ketuk, ubah dulu, atau Lewati.';

	/// id: 'Ulangi'
	String get recordRepeatTitle => 'Ulangi';

	/// id: 'Untuk tagihan, gaji, atau langganan. Kemunculan berikutnya akan menunggu kamu catat; tidak pernah dicatat diam-diam.'
	String get recordRepeatBody => 'Untuk tagihan, gaji, atau langganan. Kemunculan berikutnya akan menunggu kamu catat; tidak pernah dicatat diam-diam.';

	/// id: 'Mulai cepat'
	String get recurringStartersTitle => 'Mulai cepat';

	/// id: 'Pilih yang paling sering, mis. gaji atau listrik. Formulirnya terisi, tinggal sesuaikan.'
	String get recurringStartersBody => 'Pilih yang paling sering, mis. gaji atau listrik. Formulirnya terisi, tinggal sesuaikan.';

	/// id: 'Sisa rutin keluar'
	String get recurringSummaryTitle => 'Sisa rutin keluar';

	/// id: 'Tagihan rutin yang belum tercatat bulan ini — uang yang sudah ada tujuannya.'
	String get recurringSummaryBody => 'Tagihan rutin yang belum tercatat bulan ini — uang yang sudah ada tujuannya.';

	/// id: 'Menunggu dicatat'
	String get recurringPendingTitle => 'Menunggu dicatat';

	/// id: 'Kemunculan yang sudah tiba. Catat satu ketuk, ubah dulu, atau Lewati yang ini.'
	String get recurringPendingBody => 'Kemunculan yang sudah tiba. Catat satu ketuk, ubah dulu, atau Lewati yang ini.';

	/// id: 'Tambah rutin'
	String get recurringAddTitle => 'Tambah rutin';

	/// id: 'Bisa juga dari CATAT lewat Ulangi, atau Jadikan Rutin di rincian transaksi.'
	String get recurringAddBody => 'Bisa juga dari CATAT lewat Ulangi, atau Jadikan Rutin di rincian transaksi.';

	/// id: 'Ulangi tiap periode'
	String get budgetRepeatTitle => 'Ulangi tiap periode';

	/// id: 'Nyalakan supaya anggaran ini lahir lagi tiap bulan dengan pos yang sama. Tidak ada uang yang dipindahkan.'
	String get budgetRepeatBody => 'Nyalakan supaya anggaran ini lahir lagi tiap bulan dengan pos yang sama. Tidak ada uang yang dipindahkan.';

	/// id: 'Bulan depan'
	String get planMonthPickerTitle => 'Bulan depan';

	/// id: 'Lihat perkiraan dua bulan ke depan. Angka di tiap bulan adalah perkiraan akhir bulannya.'
	String get planMonthPickerBody => 'Lihat perkiraan dua bulan ke depan. Angka di tiap bulan adalah perkiraan akhir bulannya.';
}

// Path: info
class Translations$info$id {
	Translations$info$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Info dan tur'
	String get menuTooltip => 'Info dan tur';

	/// id: 'Tur layar ini'
	String get replayTourAction => 'Tur layar ini';

	/// id: 'Pengenalan Tanukonomy'
	String get showIntroAction => 'Pengenalan Tanukonomy';

	/// id: 'Setel ulang semua tutorial'
	String get resetAllAction => 'Setel ulang semua tutorial';

	/// id: 'Setel ulang tutorial?'
	String get resetConfirmTitle => 'Setel ulang tutorial?';

	/// id: 'Pengenalan dan semua tur akan tampil lagi seperti pertama kali. Data keuanganmu tidak tersentuh.'
	String get resetConfirmMessage => 'Pengenalan dan semua tur akan tampil lagi seperti pertama kali. Data keuanganmu tidak tersentuh.';

	/// id: 'Setel Ulang'
	String get resetConfirmAction => 'Setel Ulang';

	/// id: 'Tutorial disetel ulang.'
	String get resetDoneMessage => 'Tutorial disetel ulang.';
}

// Path: account
class Translations$account$id {
	Translations$account$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Akun'
	String get title => 'Akun';

	/// id: 'Siapkan akunmu'
	String get signedOutTitle => 'Siapkan akunmu';

	/// id: 'Semua pencatatan berjalan penuh tanpa akun. Akun menyiapkan cadangan dan sinkronisasi antarperangkat yang sedang kami bangun.'
	String get signedOutBody => 'Semua pencatatan berjalan penuh tanpa akun. Akun menyiapkan cadangan dan sinkronisasi antarperangkat yang sedang kami bangun.';

	/// id: 'Masuk dengan Google'
	String get googleSignInAction => 'Masuk dengan Google';

	/// id: 'Masuk dengan email'
	String get emailSignInToggle => 'Masuk dengan email';

	/// id: 'Untuk akun yang sudah dibuatkan khusus untukmu.'
	String get emailFormHint => 'Untuk akun yang sudah dibuatkan khusus untukmu.';

	/// id: 'Email'
	String get emailLabel => 'Email';

	/// id: 'Kata sandi'
	String get passwordLabel => 'Kata sandi';

	/// id: 'Masuk'
	String get emailSignInAction => 'Masuk';

	/// id: 'Isi email dan kata sandi dulu.'
	String get emailRequired => 'Isi email dan kata sandi dulu.';

	/// id: 'Kamu sudah masuk.'
	String get signedInMessage => 'Kamu sudah masuk.';

	/// id: 'Kamu sudah keluar.'
	String get signedOutMessage => 'Kamu sudah keluar.';

	/// id: 'Masuk lewat Google'
	String get methodGoogle => 'Masuk lewat Google';

	/// id: 'Masuk lewat email'
	String get methodPassword => 'Masuk lewat email';

	/// id: 'Data kamu'
	String get dataTitle => 'Data kamu';

	/// id: 'Dompet, transaksi, dan anggaran tersimpan di perangkat ini. Keluar atau menghapus akun tidak menyentuhnya.'
	String get dataBody => 'Dompet, transaksi, dan anggaran tersimpan di perangkat ini. Keluar atau menghapus akun tidak menyentuhnya.';

	/// id: 'Keluar'
	String get signOutAction => 'Keluar';

	/// id: 'Zona bahaya'
	String get dangerTitle => 'Zona bahaya';

	/// id: 'Menghapus akun bersifat permanen dan tidak bisa dibatalkan.'
	String get dangerBody => 'Menghapus akun bersifat permanen dan tidak bisa dibatalkan.';

	/// id: 'Hapus Akun'
	String get deleteAction => 'Hapus Akun';

	/// id: 'Hapus akun?'
	String get deleteConfirmTitle => 'Hapus akun?';

	/// id: 'Akunmu dihapus permanen. Dompet, transaksi, dan anggaran di perangkat ini tetap ada.'
	String get deleteConfirmBody => 'Akunmu dihapus permanen. Dompet, transaksi, dan anggaran di perangkat ini tetap ada.';

	/// id: 'Masukkan kata sandi'
	String get deletePasswordTitle => 'Masukkan kata sandi';

	/// id: 'Demi keamanan, masukkan lagi kata sandimu untuk menghapus akun.'
	String get deletePasswordBody => 'Demi keamanan, masukkan lagi kata sandimu untuk menghapus akun.';

	/// id: 'Akun dihapus.'
	String get deletedMessage => 'Akun dihapus.';

	late final Translations$account$errors$id errors = Translations$account$errors$id.internal(_root);
}

// Path: currency
class Translations$currency$id {
	Translations$currency$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Pengaturan'
	String get settingsTitle => 'Pengaturan';

	/// id: 'Mata uang'
	String get label => 'Mata uang';

	/// id: 'Pilih mata uang'
	String get pickerTitle => 'Pilih mata uang';

	/// id: 'Ganti ke $code?'
	String changeTitle({required Object code}) => 'Ganti ke ${code}?';

	/// id: 'Angka yang sudah dicatat tidak dikonversi, hanya simbolnya yang berganti. Contoh: $before akan tampil sebagai $after.'
	String changeBody({required Object before, required Object after}) => 'Angka yang sudah dicatat tidak dikonversi, hanya simbolnya yang berganti. Contoh: ${before} akan tampil sebagai ${after}.';

	/// id: 'Ganti'
	String get changeAction => 'Ganti';

	/// id: 'Mata uang diganti ke $code.'
	String changedMessage({required Object code}) => 'Mata uang diganti ke ${code}.';

	late final Translations$currency$names$id names = Translations$currency$names$id.internal(_root);
}

// Path: category
class Translations$category$id {
	Translations$category$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	Map<String, String> get builtIn => {
		'food': 'Makan & Minum',
		'groceries': 'Belanja Harian',
		'transport': 'Transportasi',
		'bills': 'Tagihan',
		'internet': 'Pulsa & Internet',
		'health': 'Kesehatan',
		'entertainment': 'Hiburan',
		'shopping': 'Belanja',
		'education': 'Pendidikan',
		'family': 'Keluarga',
		'donation': 'Donasi',
		'expenseOther': 'Lainnya',
		'salary': 'Gaji',
		'freelance': 'Freelance',
		'bonus': 'Bonus',
		'gift': 'Hadiah',
		'incomeOther': 'Lainnya',
	};

	/// id: 'Kategori'
	String get title => 'Kategori';

	/// id: 'Kategori'
	String get accountEntryTitle => 'Kategori';

	/// id: 'Atur daftar kategori pemasukan dan pengeluaran.'
	String get accountEntryBody => 'Atur daftar kategori pemasukan dan pengeluaran.';

	/// id: 'Pengeluaran'
	String get expenseTab => 'Pengeluaran';

	/// id: 'Pemasukan'
	String get incomeTab => 'Pemasukan';

	/// id: 'Tambah kategori'
	String get addAction => 'Tambah kategori';

	/// id: 'Kategori baru'
	String get addTitle => 'Kategori baru';

	/// id: 'Ganti nama kategori'
	String get renameTitle => 'Ganti nama kategori';

	/// id: 'Nama kategori'
	String get nameHint => 'Nama kategori';

	/// id: 'Arsipkan'
	String get archiveAction => 'Arsipkan';

	/// id: 'Pulihkan'
	String get restoreAction => 'Pulihkan';

	/// id: 'Terarsip'
	String get archivedSection => 'Terarsip';

	/// id: 'Tidak ditawarkan di CATAT, tetapi transaksi lama tetap memakainya.'
	String get archivedHint => 'Tidak ditawarkan di CATAT, tetapi transaksi lama tetap memakainya.';

	/// id: 'Belum ada kategori aktif.'
	String get emptyActive => 'Belum ada kategori aktif.';

	/// id: 'Kategori "${name}" diarsipkan.'
	String archivedMessage({required Object name}) => 'Kategori "${name}" diarsipkan.';

	/// id: 'Kategori "${name}" dipulihkan.'
	String restoredMessage({required Object name}) => 'Kategori "${name}" dipulihkan.';
}

// Path: language
class Translations$language$id {
	Translations$language$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Bahasa'
	String get label => 'Bahasa';

	/// id: 'Pilih bahasa'
	String get pickerTitle => 'Pilih bahasa';

	/// id: 'Tampilan aplikasi dan bahasa ucapan'
	String get hint => 'Tampilan aplikasi dan bahasa ucapan';
}

// Path: notificationCapture
class Translations$notificationCapture$id {
	Translations$notificationCapture$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Catat dari notifikasi'
	String get accountEntryTitle => 'Catat dari notifikasi';

	/// id: 'Catat otomatis dari notifikasi bank dan e-wallet.'
	String get accountEntryBody => 'Catat otomatis dari notifikasi bank dan e-wallet.';

	/// id: 'Catat dari notifikasi'
	String get settingsTitle => 'Catat dari notifikasi';

	/// id: 'Aktifkan'
	String get enableLabel => 'Aktifkan';

	/// id: 'Butuh izin membaca notifikasi'
	String get accessMissingTitle => 'Butuh izin membaca notifikasi';

	/// id: 'Tanpa izin ini, Tanukonomy tidak bisa melihat notifikasi bank.'
	String get accessMissingBody => 'Tanpa izin ini, Tanukonomy tidak bisa melihat notifikasi bank.';

	/// id: 'Beri izin'
	String get accessAction => 'Beri izin';

	/// id: 'Izin notifikasi aktif'
	String get accessGranted => 'Izin notifikasi aktif';

	/// id: 'Sebelum memberi izin'
	String get disclosureTitle => 'Sebelum memberi izin';

	/// id: 'Tanukonomy akan bisa membaca notifikasi di HP-mu. • Hanya dari aplikasi yang kamu pilih dan cocok dengan filternya. • Notifikasi OTP tidak pernah disimpan. • Teks yang sulit dibaca bisa dikirim ke Gemini (Google). • Teks notifikasi disimpan di HP paling lama 7 hari.'
	String get disclosureBody => 'Tanukonomy akan bisa membaca notifikasi di HP-mu.\n\n• Hanya dari aplikasi yang kamu pilih dan cocok dengan filternya.\n• Notifikasi OTP tidak pernah disimpan.\n• Teks yang sulit dibaca bisa dikirim ke Gemini (Google).\n• Teks notifikasi disimpan di HP paling lama 7 hari.';

	/// id: 'Lanjut'
	String get disclosureAccept => 'Lanjut';

	/// id: 'Izin notifikasi ditolak. Nyalakan di setelan Android untuk menerima kabar.'
	String get reminderPermissionDenied => 'Izin notifikasi ditolak. Nyalakan di setelan Android untuk menerima kabar.';

	/// id: 'Aplikasi'
	String get sourcesTitle => 'Aplikasi';

	/// id: 'Pilih aplikasi bank atau e-wallet yang notifikasinya mau dicatat.'
	String get sourcesEmpty => 'Pilih aplikasi bank atau e-wallet yang notifikasinya mau dicatat.';

	/// id: 'Tambah aplikasi'
	String get addSource => 'Tambah aplikasi';

	/// id: 'Dompet belum dipilih'
	String get sourceNoWallet => 'Dompet belum dipilih';

	/// id: 'Dijeda'
	String get sourcePaused => 'Dijeda';

	/// id: 'Pilih aplikasi'
	String get pickAppTitle => 'Pilih aplikasi';

	/// id: 'Cari aplikasi'
	String get searchApps => 'Cari aplikasi';

	/// id: 'Pola bawaan'
	String get builtInPatternsBadge => 'Pola bawaan';

	/// id: 'Daftar aplikasi gagal dibaca.'
	String get appsLoadFailed => 'Daftar aplikasi gagal dibaca.';

	/// id: 'Tidak ada aplikasi yang cocok.'
	String get appsEmpty => 'Tidak ada aplikasi yang cocok.';

	/// id: 'Dengarkan aplikasi ini'
	String get sourceEnabled => 'Dengarkan aplikasi ini';

	/// id: 'Dompet'
	String get walletLabel => 'Dompet';

	/// id: 'Pilih dompet'
	String get walletNone => 'Pilih dompet';

	/// id: 'Filter'
	String get keywordsLabel => 'Filter';

	/// id: 'Hanya notifikasi yang memuat salah satu frasa ini yang dibaca.'
	String get keywordsHint => 'Hanya notifikasi yang memuat salah satu frasa ini yang dibaca.';

	/// id: 'Tambah frasa'
	String get keywordField => 'Tambah frasa';

	/// id: 'Tambah'
	String get addKeyword => 'Tambah';

	/// id: 'Pola'
	String get patternsTitle => 'Pola';

	/// id: 'Ajari Tanukonomy membaca format notifikasi aplikasi ini.'
	String get patternsHint => 'Ajari Tanukonomy membaca format notifikasi aplikasi ini.';

	/// id: 'Belum ada pola. Tanukonomy tetap membaca dengan aturan umum.'
	String get patternsEmpty => 'Belum ada pola. Tanukonomy tetap membaca dengan aturan umum.';

	/// id: 'Bawaan · hasilnya selalu kamu cek'
	String get builtInUnverified => 'Bawaan · hasilnya selalu kamu cek';

	/// id: 'Bawaan'
	String get builtInVerified => 'Bawaan';

	/// id: 'Buat pola dari contoh'
	String get newPattern => 'Buat pola dari contoh';

	/// id: 'Hapus aplikasi ini'
	String get removeSource => 'Hapus aplikasi ini';

	/// id: 'Berhenti membaca notifikasi ${app}?'
	String removeSourceConfirm({required Object app}) => 'Berhenti membaca notifikasi ${app}?';

	/// id: 'Simpan'
	String get save => 'Simpan';

	/// id: 'Buat pola'
	String get patternTitle => 'Buat pola';

	/// id: 'Contoh notifikasi'
	String get patternSampleLabel => 'Contoh notifikasi';

	/// id: 'Tempel teks notifikasi di sini'
	String get patternSampleHint => 'Tempel teks notifikasi di sini';

	/// id: 'Pilih penanda, lalu ketuk katanya. Ketuk lagi untuk menghapus tanda.'
	String get patternInstructions => 'Pilih penanda, lalu ketuk katanya. Ketuk lagi untuk menghapus tanda.';

	/// id: 'Nominal'
	String get roleAmount => 'Nominal';

	/// id: 'Catatan'
	String get roleNote => 'Catatan';

	/// id: 'Abaikan'
	String get roleIgnore => 'Abaikan';

	/// id: 'Jenis'
	String get patternKindLabel => 'Jenis';

	/// id: 'Keluar'
	String get kindExpense => 'Keluar';

	/// id: 'Masuk'
	String get kindIncome => 'Masuk';

	/// id: 'Transfer keluar'
	String get kindTransferOut => 'Transfer keluar';

	/// id: 'Transfer masuk'
	String get kindTransferIn => 'Transfer masuk';

	/// id: 'Kategori'
	String get patternCategory => 'Kategori';

	/// id: 'Tanpa kategori'
	String get patternNoCategory => 'Tanpa kategori';

	/// id: 'Dompet lawan'
	String get patternTransferWallet => 'Dompet lawan';

	/// id: 'Nama pola (opsional)'
	String get patternLabelField => 'Nama pola (opsional)';

	/// id: 'Terbaca: ${amount}'
	String patternPreview({required Object amount}) => 'Terbaca: ${amount}';

	/// id: 'Tandai satu nominal. Kata Catatan harus berurutan.'
	String get patternInvalid => 'Tandai satu nominal. Kata Catatan harus berurutan.';

	/// id: 'Hapus pola'
	String get deletePattern => 'Hapus pola';

	/// id: 'Kotak masuk notifikasi'
	String get inboxTitle => 'Kotak masuk notifikasi';

	/// id: 'Perlu dicek'
	String get inboxPendingTitle => 'Perlu dicek';

	/// id: 'Tercatat otomatis'
	String get inboxAutoTitle => 'Tercatat otomatis';

	/// id: 'Tidak ada yang perlu dicek.'
	String get inboxEmpty => 'Tidak ada yang perlu dicek.';

	/// id: 'Belum ada yang tercatat otomatis.'
	String get inboxAutoEmpty => 'Belum ada yang tercatat otomatis.';

	/// id: 'Daftar ini disimpan 7 hari.'
	String get inboxRetention => 'Daftar ini disimpan 7 hari.';

	/// id: 'Nominal belum terbaca'
	String get amountUnknown => 'Nominal belum terbaca';

	/// id: 'Mungkin sudah tercatat'
	String get possibleDuplicate => 'Mungkin sudah tercatat';

	/// id: 'Catat'
	String get recordAction => 'Catat';

	/// id: 'Abaikan'
	String get dismissAction => 'Abaikan';

	/// id: 'Buat pola dari teks ini'
	String get makePatternAction => 'Buat pola dari teks ini';

	/// id: 'Lihat'
	String get reviewAction => 'Lihat';

	/// id: 'Batalkan'
	String get undoAction => 'Batalkan';

	/// id: 'Batalkan transaksi?'
	String get undoConfirmTitle => 'Batalkan transaksi?';

	/// id: 'Transaksinya dihapus dan saldo dompet kembali seperti sebelumnya.'
	String get undoConfirm => 'Transaksinya dihapus dan saldo dompet kembali seperti sebelumnya.';

	/// id: 'Transaksi otomatis dibatalkan.'
	String get undone => 'Transaksi otomatis dibatalkan.';

	/// id: 'Tangkapan diabaikan.'
	String get dismissed => 'Tangkapan diabaikan.';

	/// id: '${n} transaksi dari notifikasi menunggu dicek'
	String banner({required Object n}) => '${n} transaksi dari notifikasi menunggu dicek';

	/// id: 'Cek'
	String get bannerAction => 'Cek';

	/// id: 'Tercatat otomatis: ${amount} · ${app}'
	String autoRecordedSnack({required Object amount, required Object app}) => 'Tercatat otomatis: ${amount} · ${app}';

	/// id: '${n} transaksi tercatat otomatis dari notifikasi'
	String autoRecordedSnackMany({required Object n}) => '${n} transaksi tercatat otomatis dari notifikasi';

	/// id: 'Catat dari notifikasi'
	String get reminderChannel => 'Catat dari notifikasi';

	/// id: 'Transaksi dari {app} tertangkap'
	String get reminderCapturedTitle => 'Transaksi dari {app} tertangkap';

	/// id: 'Ketuk untuk mencatat.'
	String get reminderCapturedBody => 'Ketuk untuk mencatat.';

	/// id: 'Cek ${amount} dari ${app}'
	String reminderReviewTitle({required Object amount, required Object app}) => 'Cek ${amount} dari ${app}';

	/// id: 'Ketuk untuk mencatat.'
	String get reminderReviewBody => 'Ketuk untuk mencatat.';

	/// id: 'Tercatat ${amount} · ${app}'
	String reminderRecordedTitle({required Object amount, required Object app}) => 'Tercatat ${amount} · ${app}';

	/// id: 'Ketuk untuk melihat.'
	String get reminderRecordedBody => 'Ketuk untuk melihat.';

	/// id: 'Contoh teks tertangkap (debug)'
	String get debugSamplesTitle => 'Contoh teks tertangkap (debug)';

	/// id: 'Ketuk untuk menyalin. Samarkan sebelum dibagikan.'
	String get debugSamplesHint => 'Ketuk untuk menyalin. Samarkan sebelum dibagikan.';

	/// id: 'Belum ada notifikasi dari aplikasi terdaftar.'
	String get debugSamplesEmpty => 'Belum ada notifikasi dari aplikasi terdaftar.';

	/// id: 'Tambah sumber uji adb (com.android.shell)'
	String get debugShellSource => 'Tambah sumber uji adb (com.android.shell)';

	/// id: 'Disalin.'
	String get copied => 'Disalin.';

	/// id: 'Tanpa filter, tidak ada notifikasi yang dibaca.'
	String get keywordsEmptyWarning => 'Tanpa filter, tidak ada notifikasi yang dibaca.';

	/// id: 'Pakai filter bawaan'
	String get addDefaultKeywords => 'Pakai filter bawaan';

	/// id: 'Filter kosong — tidak ada yang dibaca'
	String get sourceKeywordsNone => 'Filter kosong — tidak ada yang dibaca';

	/// id: 'Transaksi dari notifikasi bank dan e-wallet yang kamu pilih dicatat untukmu.'
	String get enableHint => 'Transaksi dari notifikasi bank dan e-wallet yang kamu pilih dicatat untukmu.';

	/// id: 'Kotak masuk'
	String get inboxEntryTitle => 'Kotak masuk';

	/// id: 'Cek tangkapan dan batalkan yang tercatat otomatis.'
	String get inboxEntryBody => 'Cek tangkapan dan batalkan yang tercatat otomatis.';

	/// id: 'Saat transaksi tertangkap'
	String get behaviorTitle => 'Saat transaksi tertangkap';

	/// id: 'Catat otomatis'
	String get autoRecordLabel => 'Catat otomatis';

	/// id: 'Semua menunggu kamu cek di kotak masuk.'
	String get autoRecordOffHint => 'Semua menunggu kamu cek di kotak masuk.';

	/// id: 'Yang terbaca jelas langsung tersimpan. Yang ragu tetap menunggu dicek.'
	String get autoRecordOnHint => 'Yang terbaca jelas langsung tersimpan. Yang ragu tetap menunggu dicek.';

	/// id: 'Walau kategori belum terbaca'
	String get autoRecordAnyCategoryLabel => 'Walau kategori belum terbaca';

	/// id: 'Kategori bisa kamu isi belakangan.'
	String get autoRecordAnyCategoryHint => 'Kategori bisa kamu isi belakangan.';

	/// id: 'Kabari lewat notifikasi'
	String get reminderLabel => 'Kabari lewat notifikasi';

	/// id: 'Muncul notifikasi tiap ada transaksi tertangkap.'
	String get reminderHint => 'Muncul notifikasi tiap ada transaksi tertangkap.';

	/// id: 'Dompet ${name}'
	String sourceWallet({required Object name}) => 'Dompet ${name}';

	/// id: 'Transaksi dari aplikasi ini dicatat di dompet ini.'
	String get walletHelp => 'Transaksi dari aplikasi ini dicatat di dompet ini.';

	/// id: 'Filter dan pola'
	String get advancedTitle => 'Filter dan pola';

	/// id: 'Opsional'
	String get advancedHint => 'Opsional';

	/// id: 'Tandai bagiannya'
	String get patternMarkLabel => 'Tandai bagiannya';

	/// id: '"${word}" bukan nominal. Nominal memakai Rp atau titik ribuan.'
	String patternNotAmount({required Object word}) => '"${word}" bukan nominal. Nominal memakai Rp atau titik ribuan.';

	/// id: 'Transfer'
	String get kindTransfer => 'Transfer';

	/// id: 'Arah transfer'
	String get transferDirectionLabel => 'Arah transfer';

	/// id: 'Belum ditentukan'
	String get patternTransferWalletNone => 'Belum ditentukan';

	/// id: 'Sunting templat'
	String get patternTemplateToggle => 'Sunting templat';

	/// id: 'Lainnya'
	String get moreActions => 'Lainnya';
}

// Path: recurring
class Translations$recurring$id {
	Translations$recurring$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$recurring$starters$id starters = Translations$recurring$starters$id.internal(_root);

	/// id: 'Rutin $month'
	String summaryTitle({required Object month}) => 'Rutin ${month}';

	/// id: 'Masih akan keluar'
	String get remainingOutLabel => 'Masih akan keluar';

	/// id: '$recorded dari $total tercatat'
	String recordedOfTotal({required Object recorded, required Object total}) => '${recorded} dari ${total} tercatat';

	/// id: 'Masuk terjadwal'
	String get scheduledInLabel => 'Masuk terjadwal';

	/// id: 'Langganan $perMonth/bln · $perYear/thn'
	String subscriptionsLine({required Object perMonth, required Object perYear}) => 'Langganan ${perMonth}/bln · ${perYear}/thn';

	/// id: 'kira-kira $amount'
	String approxSemantics({required Object amount}) => 'kira-kira ${amount}';

	/// id: 'Semua ($n)'
	String filterAll({required Object n}) => 'Semua (${n})';

	/// id: 'Masuk ($n)'
	String filterIncome({required Object n}) => 'Masuk (${n})';

	/// id: 'Keluar ($n)'
	String filterExpense({required Object n}) => 'Keluar (${n})';

	/// id: 'Transfer ($n)'
	String filterTransfer({required Object n}) => 'Transfer (${n})';

	/// id: 'Menunggu dicatat'
	String get groupPending => 'Menunggu dicatat';

	/// id: 'Bulan ini'
	String get groupThisMonth => 'Bulan ini';

	/// id: 'Nanti'
	String get groupLater => 'Nanti';

	/// id: 'Dijeda'
	String get groupPaused => 'Dijeda';

	/// id: 'Selesai'
	String get groupEnded => 'Selesai';

	/// id: 'tercatat'
	String get recordedMeta => 'tercatat';

	/// id: 'menunggu'
	String get pendingMeta => 'menunggu';

	/// id: '$n terlewat'
	String missedMeta({required Object n}) => '${n} terlewat';

	/// id: 'dilewati'
	String get skippedMeta => 'dilewati';

	/// id: 'autodebet'
	String get paymentAutoDebit => 'autodebet';

	/// id: 'bayar sendiri'
	String get paymentManual => 'bayar sendiri';

	/// id: 'tahunan'
	String get yearlyMeta => 'tahunan';

	/// id: '$amount, biasanya $usual'
	String priceUp({required Object amount, required Object usual}) => '${amount}, biasanya ${usual}';

	/// id: 'Belum ada rutin'
	String get emptyTitle => 'Belum ada rutin';

	/// id: 'Tambahkan yang pasti datang tiap bulan, lalu lihat berapa yang benar-benar bebas.'
	String get emptyBody => 'Tambahkan yang pasti datang tiap bulan, lalu lihat berapa yang benar-benar bebas.';

	/// id: 'Belum ada rutin di sini.'
	String get filteredEmpty => 'Belum ada rutin di sini.';

	/// id: 'Tampilkan semua'
	String get showAllAction => 'Tampilkan semua';

	/// id: 'Tambah rutin'
	String get addAction => 'Tambah rutin';

	/// id: 'Rutin gagal dimuat.'
	String get loadError => 'Rutin gagal dimuat.';

	/// id: 'Coba lagi'
	String get retryAction => 'Coba lagi';

	/// id: 'Berikutnya'
	String get nextTitle => 'Berikutnya';

	/// id: 'Tercatat'
	String get recordedTitle => 'Tercatat';

	/// id: 'Lewati'
	String get skipAction => 'Lewati';

	/// id: 'Batal lewati'
	String get unskipAction => 'Batal lewati';

	/// id: 'Ubah'
	String get editAction => 'Ubah';

	/// id: 'Jeda'
	String get pauseAction => 'Jeda';

	/// id: 'Lanjutkan'
	String get resumeAction => 'Lanjutkan';

	/// id: 'Akhiri'
	String get endAction => 'Akhiri';

	/// id: 'Hapus'
	String get deleteAction => 'Hapus';

	/// id: 'Aksi lain'
	String get moreActions => 'Aksi lain';

	/// id: 'Hapus rutin?'
	String get deleteTitle => 'Hapus rutin?';

	/// id: 'Transaksi yang sudah tercatat tidak ikut terhapus.'
	String get deleteBody => 'Transaksi yang sudah tercatat tidak ikut terhapus.';

	/// id: '$k dari $n tercatat'
	String progressLine({required Object k, required Object n}) => '${k} dari ${n} tercatat';

	/// id: 'berakhir $date'
	String endsOnLine({required Object date}) => 'berakhir ${date}';

	/// id: '$n kali'
	String countLine({required Object n}) => '${n} kali';

	/// id: 'Dijeda'
	String get pausedLine => 'Dijeda';

	/// id: 'Bayar sendiri · diingatkan H−$n'
	String reminderLine({required Object n}) => 'Bayar sendiri · diingatkan H−${n}';

	/// id: 'Autodebet'
	String get autoDebitLine => 'Autodebet';

	/// id: '$name dijeda.'
	String pausedMessage({required Object name}) => '${name} dijeda.';

	/// id: '$name dilanjutkan.'
	String resumedMessage({required Object name}) => '${name} dilanjutkan.';

	/// id: '$name diakhiri.'
	String endedMessage({required Object name}) => '${name} diakhiri.';

	/// id: '$name dihapus.'
	String deletedMessage({required Object name}) => '${name} dihapus.';

	/// id: '$date dilewati.'
	String skippedMessage({required Object date}) => '${date} dilewati.';

	/// id: 'Perbarui ke $amount'
	String priceUpdateAction({required Object amount}) => 'Perbarui ke ${amount}';

	/// id: 'Rutin ini sudah tidak ada.'
	String get notFound => 'Rutin ini sudah tidak ada.';

	/// id: 'Belum ada yang tercatat.'
	String get noRecorded => 'Belum ada yang tercatat.';

	/// id: '$name tercatat.'
	String recordedMessage({required Object name}) => '${name} tercatat.';

	/// id: '$n rutin tercatat.'
	String recordedAllMessage({required Object n}) => '${n} rutin tercatat.';

	/// id: '$name ditautkan.'
	String linkedMessage({required Object name}) => '${name} ditautkan.';

	/// id: 'Batalkan'
	String get undoAction => 'Batalkan';

	/// id: 'Sudah tercatat?'
	String get similarTitle => 'Sudah tercatat?';

	/// id: 'Mirip $name $amount · $date yang sudah tercatat.'
	String similarBody({required Object name, required Object amount, required Object date}) => 'Mirip ${name} ${amount} · ${date} yang sudah tercatat.';

	/// id: 'Tautkan'
	String get linkAction => 'Tautkan';

	/// id: 'Catat baru'
	String get recordNewAction => 'Catat baru';

	/// id: 'Catat'
	String get recordAction => 'Catat';

	/// id: 'Ubah dulu'
	String get editFirstAction => 'Ubah dulu';

	/// id: 'Catat semua'
	String get recordAllAction => 'Catat semua';

	/// id: 'Lihat semua'
	String get seeAllAction => 'Lihat semua';

	/// id: 'Menunggu dicatat'
	String get pendingCardTitle => 'Menunggu dicatat';

	/// id: 'Biasanya $usual. Periksa lagi nominalnya.'
	String unusualAmountNotice({required Object usual}) => 'Biasanya ${usual}. Periksa lagi nominalnya.';

	/// id: 'Jadwalnya $date. Pastikan tanggalnya benar.'
	String farDateNotice({required Object date}) => 'Jadwalnya ${date}. Pastikan tanggalnya benar.';

	/// id: 'Mencatat $name · $date'
	String occurrenceNotice({required Object name, required Object date}) => 'Mencatat ${name} · ${date}';

	/// id: 'Cocok dengan rutin $name · $date'
	String matchLabel({required Object name, required Object date}) => 'Cocok dengan rutin ${name} · ${date}';

	/// id: 'Tercocok dengan rutin'
	String get linkedTitle => 'Tercocok dengan rutin';

	/// id: 'Lepaskan'
	String get unlinkAction => 'Lepaskan';

	/// id: 'Tautan dilepas. Kemunculannya kembali menunggu.'
	String get unlinkedMessage => 'Tautan dilepas. Kemunculannya kembali menunggu.';

	/// id: 'Pengingat rutin'
	String get reminderChannelName => 'Pengingat rutin';

	/// id: 'Tagihan dan pemasukan rutin yang jatuh tempo.'
	String get reminderChannelDescription => 'Tagihan dan pemasukan rutin yang jatuh tempo.';

	/// id: '$n hari lagi'
	String reminderSoonTitle({required Object n}) => '${n} hari lagi';

	/// id: 'Jatuh tempo hari ini'
	String get reminderTodayTitle => 'Jatuh tempo hari ini';

	/// id: '$n rutin jatuh tempo hari ini'
	String reminderTodayManyTitle({required Object n}) => '${n} rutin jatuh tempo hari ini';

	/// id: '$name sudah tercatat.'
	String alreadyRecordedMessage({required Object name}) => '${name} sudah tercatat.';

	/// id: 'Pengingat rutin'
	String get remindersTitle => 'Pengingat rutin';

	/// id: 'Diingatkan sehari sebelum tagihan yang dibayar sendiri, dan pada hari jatuh tempo.'
	String get remindersBody => 'Diingatkan sehari sebelum tagihan yang dibayar sendiri, dan pada hari jatuh tempo.';

	/// id: 'Izin notifikasi belum diberikan. Nyalakan di setelan sistem.'
	String get remindersDenied => 'Izin notifikasi belum diberikan. Nyalakan di setelan sistem.';

	/// id: 'Ingatkan'
	String get ruleRemindersLabel => 'Ingatkan';

	/// id: 'Pengingat rutin mati. Nyalakan di Akun.'
	String get remindersOffHint => 'Pengingat rutin mati. Nyalakan di Akun.';

	/// id: '$k dari $n'
	String positionMeta({required Object k, required Object n}) => '${k} dari ${n}';

	/// id: 'ke $wallet'
	String toWalletMeta({required Object wallet}) => 'ke ${wallet}';

	/// id: 'Sisa rutin keluar · $month'
	String remainingTitle({required Object month}) => 'Sisa rutin keluar · ${month}';

	/// id: 'Rencana'
	String get plannedLabel => 'Rencana';

	/// id: 'Sudah keluar'
	String get outLabel => 'Sudah keluar';

	/// id: 'Semua'
	String get chipAll => 'Semua';

	/// id: 'Masuk'
	String get chipIncome => 'Masuk';

	/// id: 'Keluar'
	String get chipExpense => 'Keluar';

	/// id: 'Transfer'
	String get chipTransfer => 'Transfer';

	/// id: 'Pos anggaran'
	String get budgetLinkLabel => 'Pos anggaran';

	/// id: 'Belum tertaut. Tautkan supaya tidak terhitung dua kali dengan anggaran.'
	String get budgetLinkNone => 'Belum tertaut. Tautkan supaya tidak terhitung dua kali dengan anggaran.';

	/// id: '$item · $budget'
	String budgetLinkValue({required Object item, required Object budget}) => '${item} · ${budget}';

	/// id: 'Tautkan ke pos anggaran rutin'
	String get budgetLinkPickerTitle => 'Tautkan ke pos anggaran rutin';

	/// id: 'Lepas tautan'
	String get budgetLinkRemove => 'Lepas tautan';

	/// id: 'Belum ada pos anggaran rutin di dompet ini.'
	String get budgetLinkEmpty => 'Belum ada pos anggaran rutin di dompet ini.';

	/// id: '$name tertaut ke pos $item.'
	String budgetLinkedMessage({required Object name, required Object item}) => '${name} tertaut ke pos ${item}.';

	/// id: 'Tautan pos $name dilepas.'
	String budgetUnlinkedMessage({required Object name}) => 'Tautan pos ${name} dilepas.';

	/// id: 'Siapkan dana di $wallet'
	String fundingTitle({required Object wallet}) => 'Siapkan dana di ${wallet}';

	/// id: '$name $amount, $date. Perkiraan kurang ≈$shortfall.'
	String fundingBody({required Object name, required Object amount, required Object date, required Object shortfall}) => '${name} ${amount}, ${date}. Perkiraan kurang ≈${shortfall}.';

	/// id: 'Mulai $month ruang bebas +$amount/bln.'
	String installmentFreeLine({required Object month, required Object amount}) => 'Mulai ${month} ruang bebas +${amount}/bln.';

	/// id: 'Belum terlihat di notifikasi'
	String get unseenLabel => 'Belum terlihat di notifikasi';

	/// id: 'Belum terjadi'
	String get notYetAction => 'Belum terjadi';

	/// id: '$name ditanyakan lagi 2 hari lagi.'
	String snoozedMessage({required Object name}) => '${name} ditanyakan lagi 2 hari lagi.';

	/// id: 'Masih memakai $name?'
	String idleTitle({required Object name}) => 'Masih memakai ${name}?';

	/// id: 'Dua kemunculan terakhir dilewati atau belum terlihat.'
	String get idleBody => 'Dua kemunculan terakhir dilewati atau belum terlihat.';

	/// id: 'Biarkan'
	String get idleKeep => 'Biarkan';
}

// Path: plan
class Translations$plan$id {
	Translations$plan$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Rutin'
	String get recurringSegmentLabel => 'Rutin';

	/// id: 'Awal bulan keuangan'
	String get financialMonthTitle => 'Awal bulan keuangan';

	/// id: 'Bulan keuangan dimulai'
	String get financialMonthPickerTitle => 'Bulan keuangan dimulai';

	/// id: 'Tanggal $day'
	String financialMonthDay({required Object day}) => 'Tanggal ${day}';

	/// id: 'Bulan ini'
	String get thisMonthSegmentLabel => 'Bulan ini';

	/// id: 'Uang nganggur · $month'
	String unplannedTitle({required Object month}) => 'Uang nganggur · ${month}';

	/// id: 'Pemasukan'
	String get incomeRow => 'Pemasukan';

	/// id: 'Tagihan rutin'
	String get billsRow => 'Tagihan rutin';

	/// id: 'Anggaran'
	String get budgetRow => 'Anggaran';

	/// id: 'Di luar rencana'
	String get offPlanRow => 'Di luar rencana';

	/// id: 'Penjelasan'
	String get infoAction => 'Penjelasan';

	/// id: 'Uang nganggur'
	String get infoTitle => 'Uang nganggur';

	/// id: '+ Pemasukan terencana'
	String get infoIncome => '+ Pemasukan terencana';

	/// id: '− Tagihan rutin'
	String get infoBills => '− Tagihan rutin';

	/// id: '− Anggaran'
	String get infoBudget => '− Anggaran';

	/// id: '± Di luar rencana (sudah tercatat)'
	String get infoOffPlan => '± Di luar rencana (sudah tercatat)';

	/// id: '= Uang nganggur'
	String get infoResult => '= Uang nganggur';

	/// id: 'Bukan saldo dompet.'
	String get infoNotBalance => 'Bukan saldo dompet.';

	/// id: 'Saldo dompet ≈'
	String get balanceTitle => 'Saldo dompet ≈';

	/// id: 'Semua'
	String get allWallets => 'Semua';

	/// id: 'Akhir $date'
	String endOf({required Object date}) => 'Akhir ${date}';

	/// id: 'Paling tipis · $date'
	String lowestOn({required Object date}) => 'Paling tipis · ${date}';

	/// id: 'Rincian'
	String get detailsAction => 'Rincian';

	/// id: 'hari ini'
	String get todayLabel => 'hari ini';

	/// id: 'kira-kira $amount'
	String approx({required Object amount}) => 'kira-kira ${amount}';

	/// id: 'Perkiraan saldo'
	String get detailsTitle => 'Perkiraan saldo';

	/// id: 'Saldo sekarang'
	String get detailsNow => 'Saldo sekarang';

	/// id: 'Pemasukan rutin'
	String get detailsIncome => 'Pemasukan rutin';

	/// id: 'Tagihan rutin'
	String get detailsBills => 'Tagihan rutin';

	/// id: 'Sisa anggaran'
	String get detailsBudget => 'Sisa anggaran';

	/// id: 'Di luar rencana · $perDay/hari'
	String detailsUnplanned({required Object perDay}) => 'Di luar rencana · ${perDay}/hari';

	/// id: 'Freelance belum dibayar (belum pasti)'
	String get detailsUncertain => 'Freelance belum dibayar (belum pasti)';

	/// id: 'Transfer rutin'
	String get detailsTransfers => 'Transfer rutin';

	/// id: 'Akhir $date'
	String detailsEnd({required Object date}) => 'Akhir ${date}';

	/// id: 'Hitung jajan harian'
	String get unplannedToggle => 'Hitung jajan harian';

	/// id: 'Butuh riwayat sebulan penuh.'
	String get unplannedUnavailable => 'Butuh riwayat sebulan penuh.';

	/// id: 'Berikutnya'
	String get nextTitle => 'Berikutnya';

	/// id: 'Semua di Rutin'
	String get seeAllRecurring => 'Semua di Rutin';

	/// id: 'Rencanakan bulan ini'
	String get emptyTitle => 'Rencanakan bulan ini';

	/// id: 'Tambahkan yang pasti datang tiap bulan, lalu lihat berapa yang benar-benar bebas.'
	String get emptyBody => 'Tambahkan yang pasti datang tiap bulan, lalu lihat berapa yang benar-benar bebas.';

	/// id: 'Perkiraan saldo, paling tipis $low pada $date, akhir bulan $end'
	String chartSemantics({required Object low, required Object date, required Object end}) => 'Perkiraan saldo, paling tipis ${low} pada ${date}, akhir bulan ${end}';

	/// id: '$date · $amount'
	String chartPoint({required Object date, required Object amount}) => '${date} · ${amount}';

	/// id: 'Akhir $date ≈$amount · paling tipis ≈$low ($lowDate)'
	String forecastRow({required Object date, required Object amount, required Object low, required Object lowDate}) => 'Akhir ${date} ≈${amount} · paling tipis ≈${low} (${lowDate})';

	/// id: 'Rencana bulan ini gagal dimuat.'
	String get loadError => 'Rencana bulan ini gagal dimuat.';

	/// id: 'PERKIRAAN'
	String get forecastBadge => 'PERKIRAAN';

	/// id: 'Awal $date'
	String startOf({required Object date}) => 'Awal ${date}';

	/// id: '$value jt'
	String compactMillion({required Object value}) => '${value} jt';

	/// id: '$value rb'
	String compactThousand({required Object value}) => '${value} rb';

	/// id: 'SIAPKAN DANA'
	String get fundingTitle => 'SIAPKAN DANA';

	/// id: 'Saldo $wallet diperkirakan kurang ≈$shortfall saat $name, $date. Siapkan dana di $wallet sebelum tanggal itu.'
	String fundingBody({required Object wallet, required Object shortfall, required Object name, required Object date}) => 'Saldo ${wallet} diperkirakan kurang ≈${shortfall} saat ${name}, ${date}. Siapkan dana di ${wallet} sebelum tanggal itu.';

	/// id: 'Lihat perkiraan $wallet'
	String fundingAction({required Object wallet}) => 'Lihat perkiraan ${wallet}';

	/// id: '+$n lainnya'
	String fundingMore({required Object n}) => '+${n} lainnya';

	/// id: '$month dimulai'
	String reviewTitle({required Object month}) => '${month} dimulai';

	/// id: '$done/$total'
	String reviewProgress({required Object done, required Object total}) => '${done}/${total}';

	/// id: 'Anggaran rutin bulan ini $amount, lahir sendiri.'
	String reviewBudgets({required Object amount}) => 'Anggaran rutin bulan ini ${amount}, lahir sendiri.';

	/// id: '$name ≈$amount, sesuai?'
	String reviewEstimate({required Object name, required Object amount}) => '${name} ≈${amount}, sesuai?';

	/// id: 'Kilas balik $month'
	String reviewLookback({required Object month}) => 'Kilas balik ${month}';

	/// id: 'Sesuai'
	String get reviewOk => 'Sesuai';

	/// id: 'Ubah'
	String get reviewEdit => 'Ubah';

	/// id: 'Ubah perkiraan'
	String get reviewEditEstimate => 'Ubah perkiraan';

	/// id: 'Lihat'
	String get reviewSee => 'Lihat';

	/// id: 'Selesai meninjau'
	String get reviewDone => 'Selesai meninjau';

	/// id: 'Nanti'
	String get reviewLater => 'Nanti';

	/// id: 'Tinjau rencana $month ($done/$total)'
	String reviewCollapsed({required Object month, required Object done, required Object total}) => 'Tinjau rencana ${month} (${done}/${total})';

	/// id: 'Rencana $month siap.'
	String reviewDoneMessage({required Object month}) => 'Rencana ${month} siap.';

	/// id: 'Pemasukan terjadwal $income, terikat $committed, nganggur $free.'
	String homeReviewBody({required Object income, required Object committed, required Object free}) => 'Pemasukan terjadwal ${income}, terikat ${committed}, nganggur ${free}.';

	/// id: 'Ada rutin bernominal kira-kira yang perlu dicek.'
	String get homeReviewEstimates => 'Ada rutin bernominal kira-kira yang perlu dicek.';

	/// id: 'Tinjau rencana'
	String get homeReviewAction => 'Tinjau rencana';

	/// id: 'Kilas balik $month'
	String lookbackTitle({required Object month}) => 'Kilas balik ${month}';

	/// id: 'Rencana'
	String get lookbackPlanned => 'Rencana';

	/// id: 'Nyata'
	String get lookbackActual => 'Nyata';

	/// id: 'Uang nganggur'
	String get lookbackFree => 'Uang nganggur';

	/// id: 'Selisih terbesar: $line.'
	String lookbackBiggest({required Object line}) => 'Selisih terbesar: ${line}.';

	/// id: 'Perkiraan $month tepat.'
	String accuracyExact({required Object month}) => 'Perkiraan ${month} tepat.';

	/// id: 'Perkiraan $month meleset $amount.'
	String accuracyMissed({required Object month, required Object amount}) => 'Perkiraan ${month} meleset ${amount}.';

	/// id: 'Perkiraan $month meleset $amount, terbesar dari $line.'
	String accuracyMissedBy({required Object month, required Object amount, required Object line}) => 'Perkiraan ${month} meleset ${amount}, terbesar dari ${line}.';

	/// id: '${percent}% pemasukan $month sudah terikat (rutin + anggaran).'
	String committedShare({required Object percent, required Object month}) => '${percent}% pemasukan ${month} sudah terikat (rutin + anggaran).';

	/// id: '${percent}% pemasukan $month sudah terikat (rutin + anggaran); bulan sebelumnya ${previous}%.'
	String committedShareVs({required Object percent, required Object month, required Object previous}) => '${percent}% pemasukan ${month} sudah terikat (rutin + anggaran); bulan sebelumnya ${previous}%.';

	/// id: 'Sesudah $name selesai, mulai $month ruang bebas +$amount/bln.'
	String installmentFree({required Object name, required Object month, required Object amount}) => 'Sesudah ${name} selesai, mulai ${month} ruang bebas +${amount}/bln.';
}

// Path: record.draftIssue
class Translations$record$draftIssue$id {
	Translations$record$draftIssue$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Nominal belum terbaca. Isi sendiri.'
	String get amountMissing => 'Nominal belum terbaca. Isi sendiri.';

	/// id: 'Ada lebih dari satu nominal. Isi yang benar.'
	String get amountMultiple => 'Ada lebih dari satu nominal. Isi yang benar.';

	/// id: 'Angka tanpa satuan (ribu/juta). Pastikan nominalnya.'
	String get amountWithoutUnit => 'Angka tanpa satuan (ribu/juta). Pastikan nominalnya.';

	/// id: 'Nominal bisa dibaca dua cara. Pastikan nominalnya.'
	String get amountAmbiguous => 'Nominal bisa dibaca dua cara. Pastikan nominalnya.';

	/// id: 'Mata uang yang disebut berbeda dari mata uang aplikasi.'
	String get currencyUnsupported => 'Mata uang yang disebut berbeda dari mata uang aplikasi.';

	/// id: 'Dompet yang disebut tidak ada. Pilih dompetnya.'
	String get walletUnknown => 'Dompet yang disebut tidak ada. Pilih dompetnya.';

	/// id: 'Dompet asal belum jelas. Pilih dari dompet mana.'
	String get transferSourceMissing => 'Dompet asal belum jelas. Pilih dari dompet mana.';

	/// id: 'Dompet tujuan belum jelas. Pilih dompet tujuan.'
	String get transferTargetMissing => 'Dompet tujuan belum jelas. Pilih dompet tujuan.';

	/// id: 'Kategori yang disebut tidak ada. Pilih kategorinya.'
	String get categoryUnknown => 'Kategori yang disebut tidak ada. Pilih kategorinya.';

	/// id: 'Tanggal yang disebut tidak bisa dipakai. Pilih tanggalnya.'
	String get dateUnclear => 'Tanggal yang disebut tidak bisa dipakai. Pilih tanggalnya.';

	/// id: 'Arah transaksi tidak tertulis jelas. Pilih Keluar atau Masuk.'
	String get kindUnclear => 'Arah transaksi tidak tertulis jelas. Pilih Keluar atau Masuk.';
}

// Path: record.voice
class Translations$record$voice$id {
	Translations$record$voice$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Catat pakai suara'
	String get title => 'Catat pakai suara';

	/// id: 'Catat pakai suara'
	String get micLabel => 'Catat pakai suara';

	/// id: 'Silakan bicara.'
	String get listening => 'Silakan bicara.';

	/// id: 'Berhenti sendiri saat kamu diam.'
	String get autoStopHint => 'Berhenti sendiri saat kamu diam.';

	/// id: 'Contoh: “makan siang 35 ribu pakai BCA”'
	String get example => 'Contoh: “makan siang 35 ribu pakai BCA”';

	/// id: 'Memahami…'
	String get interpreting => 'Memahami…';

	/// id: 'Ketik saja'
	String get typeInstead => 'Ketik saja';

	late final Translations$record$voice$failure$id failure = Translations$record$voice$failure$id.internal(_root);

	/// id: 'Ketuk mikrofon, lalu ucapkan satu transaksi.'
	String get idleHint => 'Ketuk mikrofon, lalu ucapkan satu transaksi.';

	/// id: 'REKAM'
	String get recordingBadge => 'REKAM';

	/// id: 'Mulai merekam'
	String get startAction => 'Mulai merekam';

	/// id: 'Mendengarkan'
	String get listeningButtonLabel => 'Mendengarkan';

	/// id: 'Rekam ulang'
	String get retryAction => 'Rekam ulang';

	/// id: 'Kamu bicara dalam bahasa apa?'
	String get languageTitle => 'Kamu bicara dalam bahasa apa?';

	/// id: 'Dipakai untuk mengenali ucapan dan untuk tampilan aplikasi. Bisa diubah di Akun.'
	String get languageBody => 'Dipakai untuk mengenali ucapan dan untuk tampilan aplikasi. Bisa diubah di Akun.';

	/// id: 'Lanjut'
	String get languageContinue => 'Lanjut';
}

// Path: record.repeat
class Translations$record$repeat$id {
	Translations$record$repeat$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Ulangi'
	String get label => 'Ulangi';

	/// id: 'Tidak'
	String get off => 'Tidak';

	/// id: 'Tiap minggu'
	String get weekly => 'Tiap minggu';

	/// id: 'Tiap bulan'
	String get monthly => 'Tiap bulan';

	/// id: 'Tiap tahun'
	String get yearly => 'Tiap tahun';

	/// id: 'Tiap $day'
	String everyWeekday({required Object day}) => 'Tiap ${day}';

	/// id: 'Tiap tanggal $day'
	String everyMonthDay({required Object day}) => 'Tiap tanggal ${day}';

	/// id: 'Tiap $date'
	String everyYearDate({required Object date}) => 'Tiap ${date}';

	/// id: 'Tiap $n minggu'
	String everyNWeeks({required Object n}) => 'Tiap ${n} minggu';

	/// id: 'Tiap $n bulan'
	String everyNMonths({required Object n}) => 'Tiap ${n} bulan';

	/// id: 'Tiap $n tahun'
	String everyNYears({required Object n}) => 'Tiap ${n} tahun';

	/// id: 'Atur lebih lanjut'
	String get moreAction => 'Atur lebih lanjut';

	/// id: 'Kurangi'
	String get lessAction => 'Kurangi';

	/// id: 'Tambah'
	String get moreCountAction => 'Tambah';

	/// id: 'Berakhir'
	String get endLabel => 'Berakhir';

	/// id: 'Tidak pernah'
	String get endNever => 'Tidak pernah';

	/// id: 'Setelah N kali'
	String get endAfter => 'Setelah N kali';

	/// id: 'Sampai tanggal'
	String get endOn => 'Sampai tanggal';

	/// id: '$n kali'
	String endsAfterSummary({required Object n}) => '${n} kali';

	/// id: 'sampai $date'
	String endsOnSummary({required Object date}) => 'sampai ${date}';

	/// id: 'Nominal'
	String get amountLabel => 'Nominal';

	/// id: 'Tetap'
	String get amountFixed => 'Tetap';

	/// id: 'Kira-kira'
	String get amountEstimated => 'Kira-kira';

	/// id: 'Cara bayar'
	String get paymentLabel => 'Cara bayar';

	/// id: 'Bayar sendiri'
	String get paymentManual => 'Bayar sendiri';

	/// id: 'Autodebet'
	String get paymentAutoDebit => 'Autodebet';

	/// id: 'Catat & Jadwalkan'
	String get recordAndScheduleAction => 'Catat & Jadwalkan';

	/// id: 'Simpan Jadwal'
	String get saveScheduleAction => 'Simpan Jadwal';

	/// id: '$name dijadwalkan. Pertama $date.'
	String scheduledMessage({required Object name, required Object date}) => '${name} dijadwalkan. Pertama ${date}.';

	/// id: '$name tercatat dan dijadwalkan.'
	String recordedMessage({required Object name}) => '${name} tercatat dan dijadwalkan.';

	/// id: '$name tercatat. Berikutnya $date.'
	String recordedNextMessage({required Object name, required Object date}) => '${name} tercatat. Berikutnya ${date}.';

	/// id: 'Rutin'
	String get fallbackName => 'Rutin';

	/// id: '$name diperbarui.'
	String updatedMessage({required Object name}) => '${name} diperbarui.';

	/// id: 'Tautkan ke pos $item'
	String linkSuggestionAction({required Object item}) => 'Tautkan ke pos ${item}';
}

// Path: account.errors
class Translations$account$errors$id {
	Translations$account$errors$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Tidak bisa terhubung. Periksa koneksi internetmu, lalu coba lagi.'
	String get network => 'Tidak bisa terhubung. Periksa koneksi internetmu, lalu coba lagi.';

	/// id: 'Email atau kata sandi salah.'
	String get wrongCredentials => 'Email atau kata sandi salah.';

	/// id: 'Terlalu banyak percobaan. Tunggu sebentar, lalu coba lagi.'
	String get tooManyRequests => 'Terlalu banyak percobaan. Tunggu sebentar, lalu coba lagi.';

	/// id: 'Akun ini dinonaktifkan.'
	String get userDisabled => 'Akun ini dinonaktifkan.';

	/// id: 'Gagal masuk. Coba lagi.'
	String get other => 'Gagal masuk. Coba lagi.';
}

// Path: currency.names
class Translations$currency$names$id {
	Translations$currency$names$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Rupiah Indonesia'
	String get idr => 'Rupiah Indonesia';

	/// id: 'Dolar AS'
	String get usd => 'Dolar AS';

	/// id: 'Euro'
	String get eur => 'Euro';

	/// id: 'Pound Inggris'
	String get gbp => 'Pound Inggris';

	/// id: 'Yen Jepang'
	String get jpy => 'Yen Jepang';

	/// id: 'Yuan Tiongkok'
	String get cny => 'Yuan Tiongkok';

	/// id: 'Won Korea Selatan'
	String get krw => 'Won Korea Selatan';

	/// id: 'Rupee India'
	String get inr => 'Rupee India';

	/// id: 'Dolar Singapura'
	String get sgd => 'Dolar Singapura';

	/// id: 'Ringgit Malaysia'
	String get myr => 'Ringgit Malaysia';

	/// id: 'Baht Thailand'
	String get thb => 'Baht Thailand';

	/// id: 'Peso Filipina'
	String get php => 'Peso Filipina';

	/// id: 'Dong Vietnam'
	String get vnd => 'Dong Vietnam';

	/// id: 'Dolar Australia'
	String get aud => 'Dolar Australia';
}

// Path: recurring.starters
class Translations$recurring$starters$id {
	Translations$recurring$starters$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Gaji'
	String get salary => 'Gaji';

	/// id: 'Kos/Sewa'
	String get rent => 'Kos/Sewa';

	/// id: 'Listrik'
	String get electricity => 'Listrik';

	/// id: 'Internet'
	String get internet => 'Internet';

	/// id: 'BPJS'
	String get bpjs => 'BPJS';

	/// id: 'Cicilan'
	String get installment => 'Cicilan';

	/// id: 'Paylater'
	String get paylater => 'Paylater';

	/// id: 'Langganan'
	String get subscription => 'Langganan';

	/// id: 'Kirim ke orang tua'
	String get parents => 'Kirim ke orang tua';

	/// id: 'Arisan'
	String get arisan => 'Arisan';

	/// id: 'Tabungan'
	String get savings => 'Tabungan';
}

// Path: record.voice.failure
class Translations$record$voice$failure$id {
	Translations$record$voice$failure$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Izin mikrofon ditolak. Izinkan di pengaturan perangkat.'
	String get permissionDenied => 'Izin mikrofon ditolak. Izinkan di pengaturan perangkat.';

	/// id: 'Perangkat ini belum punya pengenal ucapan.'
	String get unavailable => 'Perangkat ini belum punya pengenal ucapan.';

	/// id: 'Bahasa ini belum bisa dikenali tanpa internet di HP ini. Sambungkan internet, atau unduh paket bahasanya di setelan pengenalan ucapan perangkat.'
	String get languageOffline => 'Bahasa ini belum bisa dikenali tanpa internet di HP ini. Sambungkan internet, atau unduh paket bahasanya di setelan pengenalan ucapan perangkat.';

	/// id: 'Tidak ada ucapan yang tertangkap. Coba lagi.'
	String get noMatch => 'Tidak ada ucapan yang tertangkap. Coba lagi.';

	/// id: 'Mengenali suara butuh internet di perangkat ini. Sambungkan internet lalu rekam ulang, atau ketik saja.'
	String get network => 'Mengenali suara butuh internet di perangkat ini. Sambungkan internet lalu rekam ulang, atau ketik saja.';

	/// id: 'Ada yang salah. Coba lagi.'
	String get other => 'Ada yang salah. Coba lagi.';
}

/// The flat map containing all translations for locale <id>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Tanukonomy',
			'common.quickAmountThousands' => ({required Object amount}) => '+${amount}rb',
			'common.quickAmountMillions' => ({required Object amount}) => '+${amount}jt',
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
			'appShell.transactionsTabLabel' => 'Riwayat',
			'appShell.walletsTabLabel' => 'Dompet',
			'appShell.planTabLabel' => 'Rencana',
			'record.incomeAction' => 'Catat Pemasukan',
			'record.expenseAction' => 'Catat Pengeluaran',
			'record.transferAction' => 'Catat Transfer',
			'record.toWalletFieldLabel' => 'Masuk ke Dompet',
			'record.fromWalletFieldLabel' => 'Dari Dompet',
			'record.destinationWalletFieldLabel' => 'Ke Dompet',
			'record.dateFieldLabel' => 'Tanggal',
			'record.noteFieldHint' => 'Tulis catatan singkat',
			'record.noWalletsMessage' => 'Belum ada dompet. Buat dompet dulu di tab Dompet.',
			'record.sameWalletWarning' => 'Dompet asal dan tujuan tidak boleh sama.',
			'record.incomeSavedMessage' => 'Pemasukan tercatat.',
			'record.expenseSavedMessage' => 'Pengeluaran tercatat.',
			'record.transferSavedMessage' => 'Transfer tercatat.',
			'record.walletNotSelectedPrompt' => 'Belum dipilih',
			'record.savingMessage' => 'Menyimpan...',
			'record.incomeBadge' => 'Uang Masuk',
			'record.expenseBadge' => 'Uang Keluar',
			'record.transferBadge' => 'Mutasi Internal',
			'record.stepLabel' => 'Catat // Transaksi',
			'record.editStepLabel' => 'Sunting // Transaksi',
			'record.expenseRuleTitle' => 'Aturan Kas: Saldo Terpotong',
			'record.expenseRuleBody' => 'Pengeluaran langsung memotong saldo dompet yang kamu pilih di bawah ini.',
			'record.transferNoticeTitle' => 'Pindah antar dompet',
			'record.transferNoticeBody' => 'Catat uang yang berpindah di antara dompetmu, misalnya tarik tunai atau isi e-wallet. Total saldomu tetap sama.',
			'record.amountLabelIncome' => 'Nominal Masuk',
			'record.amountLabelExpense' => 'Nominal Pengeluaran',
			'record.amountLabelTransfer' => 'Nominal Transfer',
			'record.clearAmountAction' => 'Bersihkan',
			'record.categorySectionLabel' => 'Kategori',
			'record.optionalHint' => 'Opsional',
			'record.expenseWalletSectionLabel' => 'Dompet Sumber Dana',
			'record.noteSectionLabel' => 'Keterangan / Catatan',
			'record.balanceDecreasesCaption' => 'Saldo berkurang',
			'record.balanceIncreasesCaption' => 'Saldo bertambah',
			'record.incomeSummary' => ({required Object wallet, required Object amount}) => 'Saldo ${wallet} akan bertambah ${amount} saat dicatat.',
			'record.expenseSummary' => ({required Object wallet, required Object amount}) => 'Saldo ${wallet} akan berkurang ${amount} saat dicatat.',
			'record.transferSummaryTitle' => 'Ringkasan Catatan Mutasi',
			'record.transferSummaryFrom' => ({required Object wallet, required Object amount}) => 'Dompet ${wallet} berkurang ${amount}',
			'record.transferSummaryTo' => ({required Object wallet, required Object amount}) => 'Dompet ${wallet} bertambah ${amount}',
			'record.balanceLabel' => 'Saldo',
			'record.categoryPlaceholder' => 'Pilih kategori',
			'record.categoryNoneLabel' => 'Tanpa kategori',
			'record.budgetItemLabel' => 'Pos anggaran',
			'record.budgetItemNone' => 'Tanpa anggaran',
			'record.budgetItemHelp' => 'Opsional. Hanya pos anggaran yang cocok dengan dompet di atas dan periodenya mencakup tanggal transaksi yang ditawarkan.',
			'record.budgetItemOutOfPeriod' => ({required Object name}) => 'Tanggal ini di luar periode anggaran "${name}", jadi transaksi ini tidak lagi masuk anggaran itu.',
			'record.freelanceCalloutTitle' => 'Honor freelance?',
			'record.freelanceCalloutAction' => 'Catat lewat Freelance',
			'record.kindSwitcherLabel' => 'Jenis transaksi',
			'record.kindExpense' => 'Keluar',
			'record.kindIncome' => 'Masuk',
			'record.kindTransfer' => 'Transfer',
			'record.categoryAddLabel' => 'Tambah kategori',
			'record.draftHeardLabel' => 'Tertangkap',
			'record.draftCheckTitle' => 'Periksa sebelum mencatat',
			'record.draftIssue.amountMissing' => 'Nominal belum terbaca. Isi sendiri.',
			'record.draftIssue.amountMultiple' => 'Ada lebih dari satu nominal. Isi yang benar.',
			'record.draftIssue.amountWithoutUnit' => 'Angka tanpa satuan (ribu/juta). Pastikan nominalnya.',
			'record.draftIssue.amountAmbiguous' => 'Nominal bisa dibaca dua cara. Pastikan nominalnya.',
			'record.draftIssue.currencyUnsupported' => 'Mata uang yang disebut berbeda dari mata uang aplikasi.',
			'record.draftIssue.walletUnknown' => 'Dompet yang disebut tidak ada. Pilih dompetnya.',
			'record.draftIssue.transferSourceMissing' => 'Dompet asal belum jelas. Pilih dari dompet mana.',
			'record.draftIssue.transferTargetMissing' => 'Dompet tujuan belum jelas. Pilih dompet tujuan.',
			'record.draftIssue.categoryUnknown' => 'Kategori yang disebut tidak ada. Pilih kategorinya.',
			'record.draftIssue.dateUnclear' => 'Tanggal yang disebut tidak bisa dipakai. Pilih tanggalnya.',
			'record.draftIssue.kindUnclear' => 'Arah transaksi tidak tertulis jelas. Pilih Keluar atau Masuk.',
			'record.voice.title' => 'Catat pakai suara',
			'record.voice.micLabel' => 'Catat pakai suara',
			'record.voice.listening' => 'Silakan bicara.',
			'record.voice.autoStopHint' => 'Berhenti sendiri saat kamu diam.',
			'record.voice.example' => 'Contoh: “makan siang 35 ribu pakai BCA”',
			'record.voice.interpreting' => 'Memahami…',
			'record.voice.typeInstead' => 'Ketik saja',
			'record.voice.failure.permissionDenied' => 'Izin mikrofon ditolak. Izinkan di pengaturan perangkat.',
			'record.voice.failure.unavailable' => 'Perangkat ini belum punya pengenal ucapan.',
			'record.voice.failure.languageOffline' => 'Bahasa ini belum bisa dikenali tanpa internet di HP ini. Sambungkan internet, atau unduh paket bahasanya di setelan pengenalan ucapan perangkat.',
			'record.voice.failure.noMatch' => 'Tidak ada ucapan yang tertangkap. Coba lagi.',
			'record.voice.failure.network' => 'Mengenali suara butuh internet di perangkat ini. Sambungkan internet lalu rekam ulang, atau ketik saja.',
			'record.voice.failure.other' => 'Ada yang salah. Coba lagi.',
			'record.voice.idleHint' => 'Ketuk mikrofon, lalu ucapkan satu transaksi.',
			'record.voice.recordingBadge' => 'REKAM',
			'record.voice.startAction' => 'Mulai merekam',
			'record.voice.listeningButtonLabel' => 'Mendengarkan',
			'record.voice.retryAction' => 'Rekam ulang',
			'record.voice.languageTitle' => 'Kamu bicara dalam bahasa apa?',
			'record.voice.languageBody' => 'Dipakai untuk mengenali ucapan dan untuk tampilan aplikasi. Bisa diubah di Akun.',
			'record.voice.languageContinue' => 'Lanjut',
			'record.repeat.label' => 'Ulangi',
			'record.repeat.off' => 'Tidak',
			'record.repeat.weekly' => 'Tiap minggu',
			'record.repeat.monthly' => 'Tiap bulan',
			'record.repeat.yearly' => 'Tiap tahun',
			'record.repeat.everyWeekday' => ({required Object day}) => 'Tiap ${day}',
			'record.repeat.everyMonthDay' => ({required Object day}) => 'Tiap tanggal ${day}',
			'record.repeat.everyYearDate' => ({required Object date}) => 'Tiap ${date}',
			'record.repeat.everyNWeeks' => ({required Object n}) => 'Tiap ${n} minggu',
			'record.repeat.everyNMonths' => ({required Object n}) => 'Tiap ${n} bulan',
			'record.repeat.everyNYears' => ({required Object n}) => 'Tiap ${n} tahun',
			'record.repeat.moreAction' => 'Atur lebih lanjut',
			'record.repeat.lessAction' => 'Kurangi',
			'record.repeat.moreCountAction' => 'Tambah',
			'record.repeat.endLabel' => 'Berakhir',
			'record.repeat.endNever' => 'Tidak pernah',
			'record.repeat.endAfter' => 'Setelah N kali',
			'record.repeat.endOn' => 'Sampai tanggal',
			'record.repeat.endsAfterSummary' => ({required Object n}) => '${n} kali',
			'record.repeat.endsOnSummary' => ({required Object date}) => 'sampai ${date}',
			'record.repeat.amountLabel' => 'Nominal',
			'record.repeat.amountFixed' => 'Tetap',
			'record.repeat.amountEstimated' => 'Kira-kira',
			'record.repeat.paymentLabel' => 'Cara bayar',
			'record.repeat.paymentManual' => 'Bayar sendiri',
			'record.repeat.paymentAutoDebit' => 'Autodebet',
			'record.repeat.recordAndScheduleAction' => 'Catat & Jadwalkan',
			'record.repeat.saveScheduleAction' => 'Simpan Jadwal',
			'record.repeat.scheduledMessage' => ({required Object name, required Object date}) => '${name} dijadwalkan. Pertama ${date}.',
			'record.repeat.recordedMessage' => ({required Object name}) => '${name} tercatat dan dijadwalkan.',
			'record.repeat.recordedNextMessage' => ({required Object name, required Object date}) => '${name} tercatat. Berikutnya ${date}.',
			'record.repeat.fallbackName' => 'Rutin',
			'record.repeat.updatedMessage' => ({required Object name}) => '${name} diperbarui.',
			'record.repeat.linkSuggestionAction' => ({required Object item}) => 'Tautkan ke pos ${item}',
			'transaction.pageTitle' => 'Riwayat',
			'transaction.searchHint' => 'Cari di bulan ini: catatan / kategori...',
			'transaction.monthStatusLabel' => 'Status log bulan ini',
			'transaction.logCountBadge' => ({required Object count}) => '${count} log aktif',
			'transaction.netFlowLabel' => 'Arus Bersih (Netto)',
			'transaction.flowIncomeLabel' => 'Masuk',
			'transaction.flowExpenseLabel' => 'Keluar',
			'transaction.allFilterLabel' => ({required Object count}) => 'Semua ${count}',
			'transaction.incomeFilterLabel' => ({required Object count}) => 'Masuk ${count}',
			'transaction.expenseFilterLabel' => ({required Object count}) => 'Keluar ${count}',
			'transaction.transferFilterLabel' => ({required Object count}) => 'Mutasi ${count}',
			'transaction.walletFilterAllLabel' => 'Semua Dompet',
			'transaction.walletFilterLabel' => 'Dompet',
			'transaction.categoryFilterAllLabel' => 'Semua Kategori',
			'transaction.categoryFilterLabel' => 'Kategori',
			'transaction.filterButtonLabel' => 'Filter',
			'transaction.filterSheetTitle' => 'Filter Transaksi',
			'transaction.filterSheetDoneAction' => 'Selesai',
			'transaction.todayLabel' => 'Hari Ini',
			'transaction.yesterdayLabel' => 'Kemarin',
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
			'transaction.trustFooterMessage' => 'Riwayat lengkapmu, tersimpan aman di perangkatmu',
			'transaction.emptyFilterTitle' => 'Tidak ada transaksi bulan ini yang cocok dengan filter',
			'transaction.emptyFilterSubtitle' => 'Pencarian dan filter hanya mencakup bulan yang sedang dibuka. Ganti bulan, atau ganti dan hapus filter.',
			'transaction.clearFiltersButton' => 'Hapus filter',
			'transaction.crossMonthSearchButton' => 'Cari di bulan lain',
			'transaction.crossMonthSearchingLabel' => 'Mencari di bulan sebelumnya...',
			'transaction.crossMonthResultsHeader' => 'Ditemukan di bulan lain',
			'transaction.crossMonthLoadMoreButton' => 'Cari lebih jauh',
			'transaction.crossMonthNoMoreResults' => 'Tidak ditemukan di bulan-bulan sebelumnya.',
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
			'transaction.detailNoteLabel' => 'Catatan',
			'transaction.detailFromLabel' => 'Dari',
			'transaction.detailToLabel' => 'Ke',
			'transaction.detailAmountLabel' => 'Jumlah',
			'transaction.detailManualNote' => 'Tersimpan aman di perangkatmu. Saldo dompet mengikuti setiap catatan, jadi saat kamu menyunting atau menghapusnya, saldonya ikut menyesuaikan.',
			'transaction.editAction' => 'Ubah Catatan Ini',
			'transaction.recordAgainAction' => 'Catat Lagi',
			'transaction.deleteAction' => 'Hapus Catatan dari Riwayat',
			'transaction.editSheetTitle' => 'Ubah Catatan',
			'transaction.saveChangesAction' => 'Simpan Perubahan',
			'transaction.updatedMessage' => 'Perubahan tersimpan.',
			'transaction.deletedMessage' => 'Catatan dihapus.',
			'transaction.undoDeleteAction' => 'Urungkan',
			'transaction.restoredMessage' => 'Catatan dikembalikan.',
			'transaction.budgetLabel' => 'Anggaran',
			'transaction.openBudgetAction' => 'Lihat anggaran',
			'transaction.detailFreelanceNote' => 'Pemasukan ini dicatat dari pembayaran freelance. Untuk mengubahnya, batalkan penerimaannya di Freelance.',
			'transaction.makeRecurringAction' => 'Jadikan Rutin',
			'wallet.subtitle' => 'Posisi saldo kas saat ini',
			'wallet.activeBadge' => ({required Object count}) => '${count} kantong aktif',
			'wallet.totalLabel' => 'Total saldo semua dompet',
			'wallet.listHeading' => 'Daftar Dompet',
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
			'wallet.initialBalanceHelp' => 'Saldo awal adalah uang di dompet ini sekarang, titik mulai pencatatanmu. Setiap transaksi berikutnya dihitung dari sini.',
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
			'wallet.detailIncomeLabel' => 'Pemasukan',
			'wallet.detailExpenseLabel' => 'Pengeluaran',
			'wallet.detailRecentEmptyTitle' => 'Belum ada transaksi',
			'wallet.detailRecentEmpty' => 'Belum ada transaksi bulan ini untuk dompet ini.',
			'wallet.detailViewAllAction' => 'Lihat Semua Transaksi',
			'wallet.detailRecordAction' => 'Catat Transaksi Dompet Ini',
			'wallet.detailTransferInLabel' => 'Transfer masuk',
			'wallet.detailTransferOutLabel' => 'Transfer keluar',
			'wallet.detailBalanceChangeLabel' => 'Perubahan saldo',
			'budget.activeBadge' => ({required Object count}) => '${count} aktif',
			'budget.summaryTitle' => 'Total rencana anggaran aktif',
			'budget.summaryPercent' => ({required Object percent}) => '${percent}% terpakai',
			'budget.plannedLabel' => 'Rencana',
			'budget.spentLabel' => 'Terpakai',
			'budget.remainingLabel' => 'Sisa',
			'budget.spentPercentLabel' => ({required Object percent}) => 'Terpakai (${percent}%)',
			'budget.paceLabel' => ({required Object percent}) => 'Periode berjalan (${percent}%)',
			'budget.summaryNote' => 'Anggaran adalah rencana belanjamu. Angka terpakai naik setiap kali pengeluaran atau transfer yang ditautkan dicatat.',
			'budget.filterAll' => 'Semua',
			'budget.filterActive' => 'Aktif',
			'budget.filterFinished' => 'Selesai',
			'budget.filterArchived' => 'Nonaktif',
			'budget.filterWalletLabel' => 'Dompet',
			'budget.filterWalletAll' => 'Semua dompet',
			'budget.addAction' => 'Buat Anggaran Baru',
			'budget.periodWeekly' => 'Mingguan',
			'budget.periodMonthly' => 'Bulanan',
			'budget.itemStatusPlanned' => 'Belum terpakai',
			'budget.itemStatusPartiallySpent' => 'Terpakai sebagian',
			'budget.itemStatusCompleted' => 'Selesai',
			'budget.itemStatusOverspent' => 'Lewat anggaran',
			'budget.itemCount' => ({required Object count}) => '${count} pos',
			'budget.emptyBadge' => 'Slot rencana kosong',
			'budget.emptyTitle' => 'Belum ada anggaran',
			'budget.emptyBody' => 'Rencanakan batas belanja mingguan atau bulanan untuk satu dompet, lalu pantau berapa yang sudah terpakai.',
			'budget.emptyFilteredTitle' => 'Tidak ada anggaran yang cocok',
			'budget.emptyFilteredBody' => 'Tidak ada anggaran dengan status dan dompet yang dipilih.',
			'budget.resetFilterAction' => 'Tampilkan semua anggaran',
			'budget.noWalletTitle' => 'Buat dompet dulu',
			'budget.noWalletBody' => 'Setiap anggaran terikat ke satu dompet. Tambahkan dompet di tab Dompet, lalu kembali ke sini.',
			'budget.loadErrorTitle' => 'Anggaran gagal dimuat',
			'budget.loadErrorSubtitle' => 'Data anggaran tidak bisa dibaca. Coba lagi.',
			'budget.savedMessage' => 'Anggaran tersimpan.',
			'budget.updatedMessage' => 'Perubahan anggaran tersimpan.',
			'budget.deletedMessage' => 'Anggaran dihapus.',
			'budget.archivedMessage' => 'Anggaran diarsipkan.',
			'budget.unarchivedMessage' => 'Anggaran diaktifkan kembali.',
			'budget.addStepLabel' => 'Anggaran baru',
			'budget.editStepLabel' => 'Sunting anggaran',
			'budget.addTitle' => 'Buat Anggaran',
			'budget.editTitle' => 'Ubah Anggaran',
			'budget.ruleTitle' => 'Aturan Anggaran',
			'budget.ruleBody' => 'Rencana ini jadi patokan belanjamu. Saldo dompet bergerak dari transaksi yang kamu catat.',
			'budget.nameLabel' => 'Nama anggaran',
			'budget.nameHint' => 'Contoh: Kebutuhan Rumah Tangga',
			'budget.requiredHint' => 'Wajib',
			'budget.walletLabel' => 'Dompet terkait',
			'budget.walletHelp' => 'Hanya pengeluaran dan transfer keluar dari dompet ini yang terhitung ke anggaran.',
			'budget.walletBalance' => ({required Object amount}) => 'Saldo: ${amount}',
			'budget.periodLabel' => 'Periode',
			'budget.startDateLabel' => 'Mulai',
			'budget.periodRange' => ({required Object start, required Object end}) => '${start} – ${end}',
			'budget.itemsLabel' => 'Pos anggaran',
			'budget.itemsHelp' => 'Rincian rencana belanja atau rencana transfer. Total rencana anggaran adalah jumlah seluruh pos.',
			'budget.addItemAction' => 'Tambah Pos',
			'budget.saveAddAction' => 'Simpan Anggaran',
			'budget.archiveAction' => 'Arsipkan Anggaran',
			'budget.unarchiveAction' => 'Aktifkan Kembali',
			'budget.archiveHelp' => 'Anggaran nonaktif disembunyikan dari daftar aktif. Transaksi yang tertaut tetap tercatat.',
			'budget.deleteAction' => 'Hapus Anggaran',
			'budget.deleteConfirmTitle' => 'Hapus anggaran?',
			'budget.deleteConfirmMessage' => ({required Object name}) => 'Anggaran "${name}" beserta posnya akan dihapus. Transaksi yang tertaut tetap tercatat dan saldo dompet tidak berubah.',
			'budget.itemAddTitle' => 'Tambah Pos',
			'budget.itemEditTitle' => 'Ubah Pos',
			'budget.itemNameLabel' => 'Nama pos',
			'budget.itemNameHint' => 'Contoh: Beras',
			'budget.itemModeAmount' => 'Nominal',
			'budget.itemModeItemized' => 'Jumlah × harga',
			'budget.itemAmountLabel' => 'Nominal rencana',
			'budget.itemQuantityLabel' => 'Jumlah',
			'budget.itemUnitPriceLabel' => 'Harga satuan',
			'budget.itemTotalLabel' => 'Total pos',
			'budget.itemItemizedDetail' => ({required Object quantity, required Object price}) => '${quantity} × ${price}',
			'budget.itemSaveAction' => 'Simpan Pos',
			'budget.itemDeleteAction' => 'Hapus Pos',
			'budget.detailBackLabel' => 'Daftar Anggaran',
			'budget.detailEditAction' => 'Sunting anggaran',
			'budget.detailRecordExpenseAction' => 'Catat Pengeluaran',
			'budget.detailRecordTransferAction' => 'Catat Transfer',
			'budget.detailItemsHeading' => 'Pos Anggaran',
			'budget.detailNoItems' => 'Anggaran ini belum punya pos. Tambahkan pos lewat Sunting supaya pengeluaran bisa ditautkan.',
			'budget.detailLinkedHeading' => 'Transaksi Tertaut',
			'budget.detailLinkedEmpty' => 'Belum ada transaksi yang tertaut ke anggaran ini.',
			'budget.detailHowTitle' => 'Cara kerja pos anggaran',
			'budget.detailHowBody' => ({required Object wallet}) => 'Catat lewat tombol di tiap pos. Pos pengeluaran menghitung pengeluaran dari ${wallet}; pos transfer menghitung transfer dari ${wallet} ke dompet tujuannya.',
			'budget.unknownWallet' => 'Dompet tidak ditemukan',
			'budget.totalPlannedLabel' => 'Total rencana anggaran',
			'budget.itemsRequiredHint' => 'Tambahkan minimal satu pos. Transaksi dicatat ke pos, jadi anggaran tanpa pos tidak bisa melacak pengeluaran.',
			'budget.walletUnchangedNote' => ({required Object wallet}) => 'Saldo ${wallet} tetap',
			'budget.itemKindLabel' => 'Jenis pos',
			'budget.itemKindExpense' => 'Pengeluaran',
			'budget.itemKindTransfer' => 'Transfer',
			'budget.itemKindLockedHint' => 'Jenis tidak bisa diganti karena pos ini sudah punya transaksi tertaut.',
			'budget.itemTargetWalletLabel' => 'Dompet tujuan',
			'budget.itemTargetWalletHelp' => 'Hanya transfer dari dompet anggaran ke dompet ini yang terhitung ke pos.',
			'budget.itemNoTargetWallet' => 'Butuh dompet aktif lain sebagai tujuan transfer.',
			'budget.itemTransferTo' => ({required Object wallet}) => 'Ke ${wallet}',
			'budget.itemTargetConflict' => ({required Object name}) => 'Pos transfer "${name}" menuju dompet anggaran itu sendiri. Ganti dompet tujuan posnya atau dompet anggarannya.',
			'budget.templatesAction' => 'Template Anggaran',
			'budget.templatesTitle' => 'Template Anggaran',
			'budget.templatesSavedBadge' => ({required Object count}) => '${count} tersimpan',
			'budget.templatesInfoTitle' => 'Apa itu template anggaran?',
			'budget.templatesInfoBody' => 'Susunan pos rencana yang bisa dipakai ulang tanpa mengetik dari nol. Setiap pemakaian membuat anggaran baru yang berdiri sendiri.',
			'budget.templateItemCount' => ({required Object count}) => '${count} pos',
			'budget.templateItemsLabel' => 'Daftar pos rencana',
			'budget.templateTotalLabel' => 'Total rencana',
			'budget.templateUseAction' => 'Gunakan Template Ini',
			'budget.templateEditAction' => 'Ubah',
			'budget.templateDuplicateAction' => 'Duplikat',
			'budget.templateInactiveBadge' => 'Nonaktif',
			'budget.templateAddAction' => 'Buat Template Baru',
			'budget.templatesFooter' => 'Template bisa disunting kapan saja tanpa mengubah anggaran yang sudah dibuat darinya.',
			'budget.templatesEmptyBadge' => 'Belum ada template',
			'budget.templatesEmptyTitle' => 'Belum ada template',
			'budget.templatesEmptyBody' => 'Simpan susunan pos yang sering dipakai, misalnya belanja bulanan, supaya anggaran berikutnya tinggal dipakai.',
			'budget.templateNeedsWallet' => 'Buat dompet aktif dulu untuk memakai template.',
			'budget.templatesLoadError' => 'Template gagal dimuat',
			'budget.templateStepLabel' => 'Template anggaran',
			'budget.templateAddTitle' => 'Buat Template',
			'budget.templateEditTitle' => 'Ubah Template',
			'budget.templateRuleBody' => 'Template menyimpan susunan pos rencanamu. Dompet dan periodenya dipilih saat template dipakai.',
			'budget.templateNameHint' => 'Contoh: Belanja bulanan',
			'budget.templateEnabledLabel' => 'Tawarkan template ini',
			'budget.templateEnabledHelp' => 'Template nonaktif tetap tersimpan, tapi tidak bisa dipakai membuat anggaran.',
			'budget.templateSaveAction' => 'Simpan Template',
			'budget.templateDeleteAction' => 'Hapus Template',
			'budget.templateDeleteConfirmTitle' => 'Hapus template?',
			'budget.templateDeleteConfirmMessage' => ({required Object name}) => 'Template "${name}" akan dihapus. Anggaran yang pernah dibuat darinya tidak ikut terhapus.',
			'budget.templateSavedMessage' => 'Template tersimpan.',
			'budget.templateUpdatedMessage' => 'Perubahan template tersimpan.',
			'budget.templateDeletedMessage' => 'Template dihapus.',
			'budget.templateDuplicatedMessage' => 'Template digandakan.',
			'budget.templateCopyName' => ({required Object name}) => '${name} (salinan)',
			'budget.fromTemplateStepLabel' => ({required Object name}) => 'Dari template ${name}',
			'budget.templateNameLabel' => 'Nama template',
			'budget.repeatLabel' => 'Ulangi tiap periode',
			'budget.repeatHelpMonthly' => ({required Object date}) => 'Lahir lagi tiap bulan mulai ${date} dengan pos yang sama.',
			'budget.repeatHelpWeekly' => ({required Object date}) => 'Lahir lagi tiap minggu mulai ${date} dengan pos yang sama.',
			'budget.repeatUnavailable' => 'Anggaran bulanan bisa diulang bila mulai tanggal 1–28.',
			'budget.repeatPastNote' => 'Periode ini sudah lewat. Perubahannya tidak memengaruhi periode berikutnya.',
			'budget.scopeTitle' => 'Berlaku untuk',
			'budget.scopeThisPeriod' => 'Hanya periode ini',
			'budget.scopeThisAndNext' => 'Periode ini dan berikutnya',
			'budget.recurringBadge' => 'Rutin',
			'budget.templateScheduledMonthly' => ({required Object wallet}) => 'Ulangi tiap bulan · ${wallet}',
			'budget.templateScheduledWeekly' => ({required Object wallet}) => 'Ulangi tiap minggu · ${wallet}',
			'freelance.title' => 'Freelance',
			'freelance.worklogTab' => ({required Object count}) => 'Worklog (${count})',
			'freelance.paymentsTab' => ({required Object count}) => 'Pembayaran (${count})',
			'freelance.loadErrorTitle' => 'Data freelance gagal dimuat',
			'freelance.ruleTitle' => 'Aturan kas freelance',
			'freelance.ruleBody' => 'Jam kerja terkumpul jadi tagihan, dan saldo dompet bertambah saat pembayarannya dicatat diterima.',
			'freelance.summaryTitle' => 'Ringkasan upah & jam',
			'freelance.totalHoursLabel' => 'Waktu kerja',
			'freelance.hoursValue' => ({required Object hours}) => '${hours} jam',
			'freelance.hourShort' => 'jam',
			'freelance.projectCount' => ({required Object count}) => '${count} proyek',
			'freelance.earnedLabel' => 'Total diperoleh',
			'freelance.earnedCaption' => 'Jam × tarif, sebelum potongan',
			'freelance.paidLabel' => 'Sudah diterima',
			'freelance.paidCaption' => 'Gaji kotor · pembayarannya sudah dicatat',
			'freelance.unpaidLabel' => 'Belum diterima',
			'freelance.unpaidCaption' => 'Gaji kotor · belum ditagih atau tertunda',
			'freelance.paidRatio' => ({required Object percent}) => '${percent}% sudah diterima',
			'freelance.projectsLabel' => 'Proyek',
			'freelance.projectsEmpty' => 'Belum ada proyek. Tambahkan klien atau proyek beserta tarif per jamnya dulu.',
			'freelance.projectStepLabel' => 'Proyek freelance',
			'freelance.projectAddTitle' => 'Tambah Proyek',
			'freelance.projectEditTitle' => 'Ubah Proyek',
			'freelance.projectNameLabel' => 'Nama klien atau proyek',
			'freelance.projectNameHint' => 'Contoh: Studio Koding',
			'freelance.requiredHint' => 'Wajib',
			'freelance.hourlyRateLabel' => 'Tarif per jam',
			'freelance.hourlyRateHelp' => 'Tarif bawaan untuk entri baru. Mengubahnya tidak mengubah entri yang sudah dicatat.',
			'freelance.deductionsLabel' => 'Potongan',
			'freelance.deductionsHelp' => 'Dipotong dari gaji kotor setiap pembayaran, misalnya pajak. Mengubahnya tidak mengubah pembayaran yang sudah dibuat.',
			'freelance.deductionAddAction' => 'Tambah potongan',
			'freelance.deductionTitle' => 'Potongan',
			'freelance.deductionLabelLabel' => 'Nama potongan',
			'freelance.deductionLabelHint' => 'Contoh: Pajak',
			'freelance.deductionKindPercentage' => 'Persen',
			'freelance.deductionKindFixed' => 'Nominal tetap',
			'freelance.deductionPercentLabel' => 'Persen dari gaji kotor',
			'freelance.deductionPercentHelp' => 'Paling banyak satu angka di belakang koma, misalnya 2,5.',
			'freelance.deductionAmountLabel' => 'Nominal per pembayaran',
			'freelance.deductionSaveAction' => 'Simpan potongan',
			'freelance.deductionRemoveAction' => 'Hapus potongan',
			'freelance.projectSaveAction' => 'Simpan proyek',
			'freelance.projectDeleteAction' => 'Hapus proyek',
			'freelance.projectDeleteLockedHint' => 'Proyek yang sudah punya entri worklog tidak bisa dihapus.',
			'freelance.projectDeleteConfirmTitle' => 'Hapus proyek?',
			'freelance.projectDeleteConfirmMessage' => ({required Object name}) => 'Proyek "${name}" akan dihapus.',
			'freelance.projectDeleteRefused' => 'Proyek ini sudah punya entri worklog, jadi tidak bisa dihapus.',
			'freelance.projectSavedMessage' => 'Proyek tersimpan.',
			'freelance.projectUpdatedMessage' => 'Perubahan proyek tersimpan.',
			'freelance.projectDeletedMessage' => 'Proyek dihapus.',
			'freelance.projectLabel' => 'Proyek',
			'freelance.projectPick' => 'Pilih proyek',
			'freelance.entryStepLabel' => 'Log pekerjaan',
			'freelance.entryAddTitle' => 'Tambah Worklog',
			'freelance.entryEditTitle' => 'Ubah Worklog',
			'freelance.entryRuleBody' => 'Jam kerja terkumpul jadi tagihan. Uangnya masuk ke saldo saat pembayarannya dicatat diterima.',
			'freelance.workDateLabel' => 'Tanggal kerja',
			'freelance.hoursLabel' => 'Durasi pengerjaan',
			'freelance.entryRateHelp' => 'Terisi dari tarif proyek. Ubah kalau tarif entri ini berbeda.',
			'freelance.noteLabel' => 'Catatan',
			'freelance.noteHint' => 'Apa yang dikerjakan (opsional)',
			'freelance.entrySaveAction' => 'Simpan Worklog',
			'freelance.entrySaveHint' => 'Nominal ini tercatat sebagai diperoleh, belum diterima.',
			'freelance.entryDeleteAction' => 'Hapus entri',
			'freelance.entryDeleteConfirmTitle' => 'Hapus entri worklog?',
			'freelance.entryDeleteConfirmMessage' => 'Entri ini akan dihapus. Saldo dompet tidak berubah.',
			'freelance.entryLockedMessage' => 'Entri yang sudah masuk pembayaran tidak bisa diubah atau dihapus.',
			'freelance.entrySavedMessage' => 'Worklog tersimpan.',
			'freelance.entryUpdatedMessage' => 'Perubahan worklog tersimpan.',
			'freelance.entryDeletedMessage' => 'Worklog dihapus.',
			'freelance.hoursTimesRate' => ({required Object hours, required Object rate}) => '${hours} jam × ${rate}',
			'freelance.statusUnbilled' => 'Belum ditagih',
			'freelance.statusPending' => 'Tertunda',
			'freelance.statusPaid' => 'Diterima',
			'freelance.expectedOn' => ({required Object date}) => 'Perkiraan diterima ${date}',
			'freelance.receivedOn' => ({required Object date, required Object wallet}) => 'Diterima ${date} di ${wallet}',
			'freelance.unknownProject' => 'Proyek terhapus',
			'freelance.unknownWallet' => 'dompet terhapus',
			'freelance.pendingTotalLabel' => 'Tertunda (bersih)',
			'freelance.paidTotalLabel' => 'Diterima (bersih)',
			'freelance.paymentCount' => ({required Object count}) => '${count} pembayaran',
			'freelance.paymentStepLabel' => 'Pembayaran freelance',
			'freelance.paymentAddTitle' => 'Buat Pembayaran',
			'freelance.paymentCreateRuleBody' => 'Pembayaran mengelompokkan jam kerja jadi satu tagihan. Saat dicatat diterima, saldo dompet bertambah.',
			'freelance.paymentEntriesLabel' => ({required Object count, required Object hours}) => 'Entri ditagih: ${count} (${hours} jam)',
			'freelance.paymentEntriesSummary' => ({required Object count, required Object hours}) => '${count} entri · ${hours} jam',
			'freelance.expectedDateLabel' => 'Perkiraan tanggal diterima',
			'freelance.grossPayLabel' => 'Gaji kotor',
			'freelance.netPayLabel' => 'Gaji bersih',
			'freelance.netPayNotPositive' => 'Potongan tidak boleh sama dengan atau melebihi gaji kotor.',
			'freelance.paymentCreateAction' => 'Buat Pembayaran',
			'freelance.paymentChangeDateAction' => 'Ubah tanggal',
			'freelance.paymentDeleteAction' => 'Hapus',
			'freelance.paymentDeleteConfirmTitle' => 'Hapus pembayaran?',
			'freelance.paymentDeleteConfirmMessage' => 'Pembayaran tertunda ini dihapus dan entrinya kembali belum ditagih. Saldo dompet tidak berubah.',
			'freelance.paymentEntriesInvalid' => 'Entri yang dipilih sudah ditagih atau bukan milik proyek ini.',
			'freelance.paymentPaidLocked' => 'Pembayaran yang sudah diterima tidak bisa dihapus. Batalkan penerimaannya dulu.',
			'freelance.paymentAlreadyPaid' => 'Pembayaran ini sudah dicatat diterima.',
			'freelance.paymentCreatedMessage' => 'Pembayaran dibuat.',
			_ => null,
		} ?? switch (path) {
			'freelance.paymentUpdatedMessage' => 'Tanggal pembayaran diperbarui.',
			'freelance.paymentDeletedMessage' => 'Pembayaran dihapus.',
			'freelance.receiveTitle' => 'Catat Pembayaran Diterima',
			'freelance.receiveRuleTitle' => 'Honor sudah masuk',
			'freelance.receiveRuleBody' => 'Catat saat uangnya sudah kamu terima. Saldo dompet pilihan bertambah sebesar gaji bersih, dan tagihan ini tercatat lunas.',
			'freelance.receiveAmountLabel' => 'Nominal diterima',
			'freelance.receiveWalletLabel' => 'Dompet penerima',
			'freelance.receiveDateLabel' => 'Tanggal diterima',
			'freelance.receiveNoteDefault' => ({required Object project}) => 'Pembayaran freelance ${project}',
			'freelance.receiveAction' => 'Catat Diterima',
			'freelance.paymentReceivedMessage' => 'Pembayaran dicatat diterima. Saldo dompet bertambah.',
			'freelance.receiptCancelAction' => 'Batalkan penerimaan',
			'freelance.receiptCancelConfirmTitle' => 'Batalkan penerimaan?',
			'freelance.receiptCancelConfirmMessage' => 'Catatan pemasukannya dihapus dan saldo dompet berkurang kembali. Pembayaran kembali tertunda.',
			'freelance.receiptCancelledMessage' => 'Penerimaan dibatalkan. Pembayaran kembali tertunda.',
			'freelance.changeAction' => 'Ubah',
			'freelance.receiptCancelConfirmAction' => 'Hapus pemasukan',
			'freelance.billAction' => ({required Object count}) => 'Tagih (${count})',
			'freelance.entriesEmptyBadge' => 'Belum ada jam kerja',
			'freelance.entriesEmptyTitle' => 'Belum ada worklog',
			'freelance.entriesEmptyBody' => 'Catat jam kerja proyek ini lewat tombol + Worklog di bawah.',
			'freelance.entriesFilteredEmpty' => 'Tidak ada entri dengan status ini.',
			'freelance.entryAddShortAction' => '+ Worklog',
			'freelance.entryCountLabel' => ({required Object count}) => '${count} entri',
			'freelance.filterAll' => 'Semua',
			'freelance.lastEntryOn' => ({required Object date}) => 'Terakhir ${date}',
			'freelance.noDeductions' => 'Tanpa potongan',
			'freelance.noEntriesYet' => 'Belum ada entri',
			'freelance.projectTotals' => ({required Object hours, required Object amount}) => 'Total ${hours} jam · ${amount}',
			'freelance.projectsEmptyBadge' => 'Slot proyek kosong',
			'freelance.projectsEmptyTitle' => 'Belum ada proyek',
			'freelance.unbilledLabel' => 'Belum ditagih',
			'freelance.unbilledNone' => 'Semua sudah ditagih',
			'freelance.paymentsEmptyBadge' => 'Belum ada tagihan',
			'freelance.paymentsEmptyTitle' => 'Belum ada pembayaran',
			'freelance.paymentsEmptyBody' => 'Tekan Tagih di bawah untuk mengelompokkan jam kerja yang belum ditagih jadi satu pembayaran.',
			'freelance.paymentsFilteredEmpty' => 'Tidak ada pembayaran dengan status ini.',
			'freelance.nextExpected' => ({required Object count, required Object date}) => '${count} tagihan · terdekat ${date}',
			'freelance.paymentWorkRange' => ({required Object range}) => 'Kerja ${range}',
			'home.loadErrorTitle' => 'Beranda gagal dimuat',
			'home.balanceLabel' => 'Total kas aktif',
			'home.walletCount' => ({required Object count}) => '${count} dompet aktif',
			'home.moreWallets' => ({required Object count}) => '+${count} lainnya',
			'home.startBadge' => 'Mulai catat',
			'home.noWalletsBody' => 'Belum ada saldo dompet yang tercatat.',
			'home.incomeLabel' => ({required Object month}) => 'Pemasukan ${month}',
			'home.expenseLabel' => ({required Object month}) => 'Pengeluaran ${month}',
			'home.budgetTitle' => 'Anggaran aktif',
			'home.budgetRemaining' => 'Sisa',
			'home.budgetOver' => 'Lewat rencana',
			'home.budgetAction' => 'Lihat Anggaran',
			'home.freelanceTitle' => 'Freelance',
			'home.freelancePaid' => ({required Object amount}) => 'Diterima: ${amount}',
			'home.freelanceAction' => 'Lihat Freelance',
			'home.recentTitle' => 'Transaksi terbaru',
			'home.seeAll' => 'Lihat semua',
			'home.emptyBadge' => 'Inventaris kosong',
			'home.emptyTitle' => 'Belum ada transaksi',
			'home.emptyBody' => 'Mulai dengan mencatat pemasukan, pengeluaran, atau transfer pertamamu.',
			'home.emptyNoWalletBody' => 'Buat dompet pertamamu beserta saldo awalnya dulu, lalu catat transaksi pertama.',
			'home.recordAction' => 'Catat Transaksi',
			'home.createWalletAction' => 'Buat Dompet Pertama',
			'home.budgetLink' => 'Atau buat anggaran pengeluaran',
			'home.guideTitle' => 'Panduan singkat',
			'home.guideCount' => '3 aturan utama',
			'home.guideWalletTitle' => 'Dompet',
			'home.guideWalletTag' => 'Aset nyata',
			'home.guideWalletBody' => 'Catat rekening bank, dompet digital, atau uang tunai beserta saldonya saat ini.',
			'home.guideBudgetTitle' => 'Anggaran',
			'home.guideBudgetTag' => 'Rencana',
			'home.guideBudgetBody' => 'Rencanakan batas belanja dan pantau berapa yang sudah terpakai.',
			'home.guideFreelanceTitle' => 'Freelance',
			'home.guideFreelanceTag' => 'Piutang',
			'home.guideFreelanceBody' => 'Pantau jam kerja dan tagihan. Uang baru masuk ke dompet saat pembayarannya dicatat diterima.',
			'home.budgetSpentOf' => ({required Object spent, required Object planned}) => '${spent} terpakai dari ${planned}',
			'home.freelanceUnpaidTitle' => 'Belum diterima (kotor)',
			'home.freelanceDueLabel' => 'Jatuh tempo',
			'home.freelancePendingInvoices' => ({required Object count}) => '${count} tagihan tertunda',
			'home.freelanceSummaryLine' => ({required Object hours, required Object earned}) => '${hours} · diperoleh ${earned}',
			'home.openCard' => ({required Object name}) => 'Buka ${name}',
			'home.budgetUsedBadge' => ({required Object percent}) => '${percent}% terpakai',
			'onboarding.skipAction' => 'Lewati',
			'onboarding.nextAction' => 'Lanjut',
			'onboarding.closeAction' => 'Tutup',
			'onboarding.pageIndicatorLabel' => ({required Object current, required Object total}) => 'Halaman ${current} dari ${total}',
			'onboarding.page1Title' => 'Semua uangmu, satu buku',
			'onboarding.page1Body' => 'Lihat di mana uangmu berada, apa saja yang terjadi padanya, dan ke mana kamu merencanakannya — semuanya di buku kas pribadimu.',
			'onboarding.page2Title' => 'Tahu di mana uangmu',
			'onboarding.page2Body' => 'Rekening bank, e-wallet, dan uang tunai jadi dompet. Saldo tiap dompet dan totalnya selalu terlihat.',
			'onboarding.page3Title' => 'Catat dalam hitungan detik',
			'onboarding.page3Body' => 'Uang masuk, keluar, atau pindah dompet — ketuk CATAT. Dompet yang biasa kamu pakai dan kategori favoritmu sudah menunggu.',
			'onboarding.page4Title' => 'Rencanakan, lalu pantau',
			'onboarding.page4Body' => 'Susun anggaran per minggu atau bulan dengan pos-pos belanjamu. Saldo tetap utuh, dan kamu melihat berapa yang sudah terpakai dari rencana.',
			'onboarding.finalTitle' => 'Mulai dari dompet pertamamu',
			'onboarding.finalBody' => 'Tambahkan satu dompet, lalu catat transaksi pertamamu. Di tiap layar, tanuki akan menunjukkan jalannya.',
			'onboarding.createWalletAction' => 'Buat Dompet Pertama',
			'onboarding.laterAction' => 'Nanti saja',
			'onboarding.signInAction' => 'Sudah punya akun? Masuk',
			'onboarding.backAction' => 'Kembali',
			'onboarding.currencyTitle' => 'Pilih mata uangmu',
			'onboarding.currencyBody' => 'Semua nominal di Tanukonomy memakai mata uang ini. Nanti bisa diganti di layar Akun, tapi angka yang sudah dicatat tidak dikonversi.',
			'onboarding.currencySuggested' => 'Sesuai wilayah perangkatmu',
			'onboarding.currencyChooseFirst' => 'Pilih mata uang dulu',
			'onboarding.currencyConfirm' => ({required Object code}) => 'Pakai ${code}',
			'onboarding.languageTitle' => 'Pilih bahasa',
			'onboarding.languageBody' => 'Dipakai untuk tampilan aplikasi dan saat mencatat dengan suara. Bisa diubah lagi di layar Akun.',
			'onboarding.languageConfirm' => 'Lanjut',
			'tour.nextAction' => 'Lanjut',
			'tour.doneAction' => 'Selesai',
			'tour.skipAction' => 'Lewati tur',
			'tour.stepCounter' => ({required Object current, required Object total}) => '${current}/${total}',
			'tour.stepSemantics' => ({required Object current, required Object total, required Object title, required Object body}) => 'Langkah ${current} dari ${total}: ${title}. ${body}',
			'tour.homeBalanceTitle' => 'Total saldo tercatat',
			'tour.homeBalanceBody' => 'Jumlah saldo semua dompet aktif — posisi uangmu dalam sekali lihat.',
			'tour.homeRecordTitle' => 'Satu pintu mencatat',
			'tour.homeRecordBody' => 'Semua uang masuk, keluar, dan pindah dompet dicatat dari sini.',
			'tour.homeCashFlowTitle' => 'Arus bulan ini',
			'tour.homeCashFlowBody' => 'Uang yang benar-benar masuk dan keluar bulan ini.',
			'tour.homeBudgetTitle' => 'Sisa anggaran aktif',
			'tour.homeBudgetBody' => 'Sisa rencana dari anggaran yang sedang berjalan. Ketuk untuk rinciannya.',
			'tour.homeFreelanceTitle' => 'Ringkasan freelance',
			'tour.homeFreelanceBody' => 'Penghasilan yang sudah dikerjakan dan yang masih tertunda. Saldo dompet baru bertambah saat pembayaran dicatat diterima.',
			'tour.homeRecentTitle' => 'Transaksi terbaru',
			'tour.homeRecentBody' => 'Catatan terakhirmu. Ketuk salah satunya untuk rincian, atau Lihat semua untuk riwayat per bulan.',
			'tour.recordKindTitle' => 'Pilih jenisnya',
			'tour.recordKindBody' => 'Keluar mengurangi saldo, Masuk menambah, dan Transfer hanya memindahkan antar dompetmu — totalmu tetap.',
			'tour.recordFreelanceTitle' => 'Honor freelance lewat jalur sendiri',
			'tour.recordFreelanceBody' => 'Honor proyek dicatat sebagai pembayaran diterima di Freelance, jadi jam kerja dan tagihannya ikut lunas.',
			'tour.recordAmountTitle' => 'Nominal',
			'tour.recordAmountBody' => 'Ketik nominalnya, atau pakai tombol cepat.',
			'tour.recordWalletTitle' => 'Dompet terisi otomatis',
			'tour.recordWalletBody' => 'Dompet terakhir yang kamu pakai sudah terpilih. Ganti kalau perlu.',
			'tour.recordBudgetItemTitle' => 'Tautkan ke anggaran',
			'tour.recordBudgetItemBody' => 'Opsional. Pengeluaran yang ditautkan menambah angka terpakai pos itu, selama tanggalnya di dalam periode anggaran.',
			'tour.walletSummaryTitle' => 'Total semua dompet',
			'tour.walletSummaryBody' => 'Jumlah saldo tercatat dompet aktif.',
			'tour.walletCardTitle' => 'Rincian dompet',
			'tour.walletCardBody' => 'Ketuk untuk melihat riwayat dompet ini dan mencatat langsung dari sana.',
			'tour.walletAddTitle' => 'Tambah dompet',
			'tour.walletAddBody' => 'Rekening, e-wallet, atau tunai. Saldo awalnya bisa diubah kapan saja, dan saldo tercatat ikut menyesuaikan.',
			'tour.txnMonthTitle' => 'Satu bulan per tampilan',
			'tour.txnMonthBody' => 'Geser bulan untuk melihat riwayat lain. Arus masuk dan keluar di sini hanya untuk bulan yang tampil.',
			'tour.txnFilterTitle' => 'Cari dan saring',
			'tour.txnFilterBody' => 'Cari catatan atau kategori, lalu saring per dompet dan kategori lewat Filter. Kalau bulan ini kosong, pencarian bisa dilanjutkan ke bulan lain.',
			'tour.txnRowTitle' => 'Sunting atau hapus',
			'tour.txnRowBody' => 'Ketuk transaksi untuk rinciannya; dari sana bisa disunting, dicatat lagi, atau dihapus, dan saldo dihitung ulang.',
			'tour.budgetSummaryTitle' => 'Sisa semua anggaran aktif',
			'tour.budgetSummaryBody' => 'Rencana dikurangi terpakai — sisa ruang belanjamu di semua anggaran aktif.',
			'tour.budgetFilterTitle' => 'Aktif lebih dulu',
			'tour.budgetFilterBody' => 'Daftar menampilkan anggaran aktif. Pilih Selesai atau Nonaktif untuk melihat yang lama.',
			'tour.budgetTemplatesTitle' => 'Pakai template',
			'tour.budgetTemplatesBody' => 'Simpan susunan pos yang berulang, lalu buat anggaran baru darinya.',
			'tour.budgetDetailItemTitle' => 'Pos anggaran',
			'tour.budgetDetailItemBody' => 'Terpakai naik dari transaksi yang ditautkan ke pos ini dalam periode anggaran.',
			'tour.budgetDetailRecordTitle' => 'Catat dari pos',
			'tour.budgetDetailRecordBody' => 'Membuka CATAT dengan pos ini sudah terpilih.',
			'tour.freelanceProjectTitle' => 'Proyek dan tarif',
			'tour.freelanceProjectBody' => 'Setiap proyek punya tarif per jam dan potongan. Ketuk proyek untuk mencatat jam kerja dan pembayarannya.',
			'tour.freelanceWorklogTitle' => 'Jam kerja',
			'tour.freelanceWorklogBody' => 'Jam kerja adalah penghasilan yang sudah kamu peroleh. Kumpulkan jadi tagihan, lalu catat saat dibayar.',
			'tour.freelanceReceiveTitle' => 'Uang benar-benar masuk',
			'tour.freelanceReceiveBody' => 'Catat saat honornya masuk: saldo dompet bertambah dan tagihannya lunas.',
			'tour.homeVoiceTitle' => 'Catat pakai suara',
			'tour.homeVoiceBody' => 'Ketuk, ucapkan satu transaksi, lalu periksa formulirnya sebelum dicatat.',
			'tour.planTabsTitle' => 'Rencana',
			'tour.planTabsBody' => 'Bulan ini, anggaran, dan transaksi rutin ada di sini. Ketuk untuk berpindah.',
			'tour.planUnplannedTitle' => 'Uang nganggur',
			'tour.planUnplannedBody' => 'Pemasukan bulan ini dikurangi semua yang sudah terikat.',
			'tour.planForecastTitle' => 'Saldo dompet ≈',
			'tour.planForecastBody' => 'Perkiraan saldo sampai akhir bulan, termasuk titik paling tipisnya.',
			'tour.homeForecastTitle' => 'Perkiraan saldo',
			'tour.homeForecastBody' => 'Saldo dompet perkiraan di akhir bulan dan titik paling tipisnya. Ketuk untuk rinciannya di Rencana.',
			'tour.homePendingTitle' => 'Menunggu dicatat',
			'tour.homePendingBody' => 'Tagihan dan pemasukan rutin yang sudah tiba. Catat satu ketuk, ubah dulu, atau Lewati.',
			'tour.recordRepeatTitle' => 'Ulangi',
			'tour.recordRepeatBody' => 'Untuk tagihan, gaji, atau langganan. Kemunculan berikutnya akan menunggu kamu catat; tidak pernah dicatat diam-diam.',
			'tour.recurringStartersTitle' => 'Mulai cepat',
			'tour.recurringStartersBody' => 'Pilih yang paling sering, mis. gaji atau listrik. Formulirnya terisi, tinggal sesuaikan.',
			'tour.recurringSummaryTitle' => 'Sisa rutin keluar',
			'tour.recurringSummaryBody' => 'Tagihan rutin yang belum tercatat bulan ini — uang yang sudah ada tujuannya.',
			'tour.recurringPendingTitle' => 'Menunggu dicatat',
			'tour.recurringPendingBody' => 'Kemunculan yang sudah tiba. Catat satu ketuk, ubah dulu, atau Lewati yang ini.',
			'tour.recurringAddTitle' => 'Tambah rutin',
			'tour.recurringAddBody' => 'Bisa juga dari CATAT lewat Ulangi, atau Jadikan Rutin di rincian transaksi.',
			'tour.budgetRepeatTitle' => 'Ulangi tiap periode',
			'tour.budgetRepeatBody' => 'Nyalakan supaya anggaran ini lahir lagi tiap bulan dengan pos yang sama. Tidak ada uang yang dipindahkan.',
			'tour.planMonthPickerTitle' => 'Bulan depan',
			'tour.planMonthPickerBody' => 'Lihat perkiraan dua bulan ke depan. Angka di tiap bulan adalah perkiraan akhir bulannya.',
			'info.menuTooltip' => 'Info dan tur',
			'info.replayTourAction' => 'Tur layar ini',
			'info.showIntroAction' => 'Pengenalan Tanukonomy',
			'info.resetAllAction' => 'Setel ulang semua tutorial',
			'info.resetConfirmTitle' => 'Setel ulang tutorial?',
			'info.resetConfirmMessage' => 'Pengenalan dan semua tur akan tampil lagi seperti pertama kali. Data keuanganmu tidak tersentuh.',
			'info.resetConfirmAction' => 'Setel Ulang',
			'info.resetDoneMessage' => 'Tutorial disetel ulang.',
			'account.title' => 'Akun',
			'account.signedOutTitle' => 'Siapkan akunmu',
			'account.signedOutBody' => 'Semua pencatatan berjalan penuh tanpa akun. Akun menyiapkan cadangan dan sinkronisasi antarperangkat yang sedang kami bangun.',
			'account.googleSignInAction' => 'Masuk dengan Google',
			'account.emailSignInToggle' => 'Masuk dengan email',
			'account.emailFormHint' => 'Untuk akun yang sudah dibuatkan khusus untukmu.',
			'account.emailLabel' => 'Email',
			'account.passwordLabel' => 'Kata sandi',
			'account.emailSignInAction' => 'Masuk',
			'account.emailRequired' => 'Isi email dan kata sandi dulu.',
			'account.signedInMessage' => 'Kamu sudah masuk.',
			'account.signedOutMessage' => 'Kamu sudah keluar.',
			'account.methodGoogle' => 'Masuk lewat Google',
			'account.methodPassword' => 'Masuk lewat email',
			'account.dataTitle' => 'Data kamu',
			'account.dataBody' => 'Dompet, transaksi, dan anggaran tersimpan di perangkat ini. Keluar atau menghapus akun tidak menyentuhnya.',
			'account.signOutAction' => 'Keluar',
			'account.dangerTitle' => 'Zona bahaya',
			'account.dangerBody' => 'Menghapus akun bersifat permanen dan tidak bisa dibatalkan.',
			'account.deleteAction' => 'Hapus Akun',
			'account.deleteConfirmTitle' => 'Hapus akun?',
			'account.deleteConfirmBody' => 'Akunmu dihapus permanen. Dompet, transaksi, dan anggaran di perangkat ini tetap ada.',
			'account.deletePasswordTitle' => 'Masukkan kata sandi',
			'account.deletePasswordBody' => 'Demi keamanan, masukkan lagi kata sandimu untuk menghapus akun.',
			'account.deletedMessage' => 'Akun dihapus.',
			'account.errors.network' => 'Tidak bisa terhubung. Periksa koneksi internetmu, lalu coba lagi.',
			'account.errors.wrongCredentials' => 'Email atau kata sandi salah.',
			'account.errors.tooManyRequests' => 'Terlalu banyak percobaan. Tunggu sebentar, lalu coba lagi.',
			'account.errors.userDisabled' => 'Akun ini dinonaktifkan.',
			'account.errors.other' => 'Gagal masuk. Coba lagi.',
			'currency.settingsTitle' => 'Pengaturan',
			'currency.label' => 'Mata uang',
			'currency.pickerTitle' => 'Pilih mata uang',
			'currency.changeTitle' => ({required Object code}) => 'Ganti ke ${code}?',
			'currency.changeBody' => ({required Object before, required Object after}) => 'Angka yang sudah dicatat tidak dikonversi, hanya simbolnya yang berganti. Contoh: ${before} akan tampil sebagai ${after}.',
			'currency.changeAction' => 'Ganti',
			'currency.changedMessage' => ({required Object code}) => 'Mata uang diganti ke ${code}.',
			'currency.names.idr' => 'Rupiah Indonesia',
			'currency.names.usd' => 'Dolar AS',
			'currency.names.eur' => 'Euro',
			'currency.names.gbp' => 'Pound Inggris',
			'currency.names.jpy' => 'Yen Jepang',
			'currency.names.cny' => 'Yuan Tiongkok',
			'currency.names.krw' => 'Won Korea Selatan',
			'currency.names.inr' => 'Rupee India',
			'currency.names.sgd' => 'Dolar Singapura',
			'currency.names.myr' => 'Ringgit Malaysia',
			'currency.names.thb' => 'Baht Thailand',
			'currency.names.php' => 'Peso Filipina',
			'currency.names.vnd' => 'Dong Vietnam',
			'currency.names.aud' => 'Dolar Australia',
			'category.builtIn.food' => 'Makan & Minum',
			'category.builtIn.groceries' => 'Belanja Harian',
			'category.builtIn.transport' => 'Transportasi',
			'category.builtIn.bills' => 'Tagihan',
			'category.builtIn.internet' => 'Pulsa & Internet',
			'category.builtIn.health' => 'Kesehatan',
			'category.builtIn.entertainment' => 'Hiburan',
			'category.builtIn.shopping' => 'Belanja',
			'category.builtIn.education' => 'Pendidikan',
			'category.builtIn.family' => 'Keluarga',
			'category.builtIn.donation' => 'Donasi',
			'category.builtIn.expenseOther' => 'Lainnya',
			'category.builtIn.salary' => 'Gaji',
			'category.builtIn.freelance' => 'Freelance',
			'category.builtIn.bonus' => 'Bonus',
			'category.builtIn.gift' => 'Hadiah',
			'category.builtIn.incomeOther' => 'Lainnya',
			'category.title' => 'Kategori',
			'category.accountEntryTitle' => 'Kategori',
			'category.accountEntryBody' => 'Atur daftar kategori pemasukan dan pengeluaran.',
			'category.expenseTab' => 'Pengeluaran',
			'category.incomeTab' => 'Pemasukan',
			'category.addAction' => 'Tambah kategori',
			'category.addTitle' => 'Kategori baru',
			'category.renameTitle' => 'Ganti nama kategori',
			'category.nameHint' => 'Nama kategori',
			'category.archiveAction' => 'Arsipkan',
			'category.restoreAction' => 'Pulihkan',
			'category.archivedSection' => 'Terarsip',
			'category.archivedHint' => 'Tidak ditawarkan di CATAT, tetapi transaksi lama tetap memakainya.',
			'category.emptyActive' => 'Belum ada kategori aktif.',
			'category.archivedMessage' => ({required Object name}) => 'Kategori "${name}" diarsipkan.',
			'category.restoredMessage' => ({required Object name}) => 'Kategori "${name}" dipulihkan.',
			'language.label' => 'Bahasa',
			'language.pickerTitle' => 'Pilih bahasa',
			'language.hint' => 'Tampilan aplikasi dan bahasa ucapan',
			'notificationCapture.accountEntryTitle' => 'Catat dari notifikasi',
			'notificationCapture.accountEntryBody' => 'Catat otomatis dari notifikasi bank dan e-wallet.',
			'notificationCapture.settingsTitle' => 'Catat dari notifikasi',
			'notificationCapture.enableLabel' => 'Aktifkan',
			'notificationCapture.accessMissingTitle' => 'Butuh izin membaca notifikasi',
			'notificationCapture.accessMissingBody' => 'Tanpa izin ini, Tanukonomy tidak bisa melihat notifikasi bank.',
			'notificationCapture.accessAction' => 'Beri izin',
			'notificationCapture.accessGranted' => 'Izin notifikasi aktif',
			'notificationCapture.disclosureTitle' => 'Sebelum memberi izin',
			'notificationCapture.disclosureBody' => 'Tanukonomy akan bisa membaca notifikasi di HP-mu.\n\n• Hanya dari aplikasi yang kamu pilih dan cocok dengan filternya.\n• Notifikasi OTP tidak pernah disimpan.\n• Teks yang sulit dibaca bisa dikirim ke Gemini (Google).\n• Teks notifikasi disimpan di HP paling lama 7 hari.',
			'notificationCapture.disclosureAccept' => 'Lanjut',
			'notificationCapture.reminderPermissionDenied' => 'Izin notifikasi ditolak. Nyalakan di setelan Android untuk menerima kabar.',
			'notificationCapture.sourcesTitle' => 'Aplikasi',
			'notificationCapture.sourcesEmpty' => 'Pilih aplikasi bank atau e-wallet yang notifikasinya mau dicatat.',
			'notificationCapture.addSource' => 'Tambah aplikasi',
			'notificationCapture.sourceNoWallet' => 'Dompet belum dipilih',
			'notificationCapture.sourcePaused' => 'Dijeda',
			'notificationCapture.pickAppTitle' => 'Pilih aplikasi',
			'notificationCapture.searchApps' => 'Cari aplikasi',
			'notificationCapture.builtInPatternsBadge' => 'Pola bawaan',
			'notificationCapture.appsLoadFailed' => 'Daftar aplikasi gagal dibaca.',
			'notificationCapture.appsEmpty' => 'Tidak ada aplikasi yang cocok.',
			'notificationCapture.sourceEnabled' => 'Dengarkan aplikasi ini',
			'notificationCapture.walletLabel' => 'Dompet',
			'notificationCapture.walletNone' => 'Pilih dompet',
			'notificationCapture.keywordsLabel' => 'Filter',
			'notificationCapture.keywordsHint' => 'Hanya notifikasi yang memuat salah satu frasa ini yang dibaca.',
			'notificationCapture.keywordField' => 'Tambah frasa',
			'notificationCapture.addKeyword' => 'Tambah',
			'notificationCapture.patternsTitle' => 'Pola',
			'notificationCapture.patternsHint' => 'Ajari Tanukonomy membaca format notifikasi aplikasi ini.',
			'notificationCapture.patternsEmpty' => 'Belum ada pola. Tanukonomy tetap membaca dengan aturan umum.',
			'notificationCapture.builtInUnverified' => 'Bawaan · hasilnya selalu kamu cek',
			'notificationCapture.builtInVerified' => 'Bawaan',
			'notificationCapture.newPattern' => 'Buat pola dari contoh',
			'notificationCapture.removeSource' => 'Hapus aplikasi ini',
			'notificationCapture.removeSourceConfirm' => ({required Object app}) => 'Berhenti membaca notifikasi ${app}?',
			'notificationCapture.save' => 'Simpan',
			'notificationCapture.patternTitle' => 'Buat pola',
			'notificationCapture.patternSampleLabel' => 'Contoh notifikasi',
			'notificationCapture.patternSampleHint' => 'Tempel teks notifikasi di sini',
			'notificationCapture.patternInstructions' => 'Pilih penanda, lalu ketuk katanya. Ketuk lagi untuk menghapus tanda.',
			'notificationCapture.roleAmount' => 'Nominal',
			'notificationCapture.roleNote' => 'Catatan',
			'notificationCapture.roleIgnore' => 'Abaikan',
			'notificationCapture.patternKindLabel' => 'Jenis',
			'notificationCapture.kindExpense' => 'Keluar',
			'notificationCapture.kindIncome' => 'Masuk',
			'notificationCapture.kindTransferOut' => 'Transfer keluar',
			'notificationCapture.kindTransferIn' => 'Transfer masuk',
			'notificationCapture.patternCategory' => 'Kategori',
			'notificationCapture.patternNoCategory' => 'Tanpa kategori',
			'notificationCapture.patternTransferWallet' => 'Dompet lawan',
			'notificationCapture.patternLabelField' => 'Nama pola (opsional)',
			'notificationCapture.patternPreview' => ({required Object amount}) => 'Terbaca: ${amount}',
			'notificationCapture.patternInvalid' => 'Tandai satu nominal. Kata Catatan harus berurutan.',
			'notificationCapture.deletePattern' => 'Hapus pola',
			'notificationCapture.inboxTitle' => 'Kotak masuk notifikasi',
			'notificationCapture.inboxPendingTitle' => 'Perlu dicek',
			'notificationCapture.inboxAutoTitle' => 'Tercatat otomatis',
			'notificationCapture.inboxEmpty' => 'Tidak ada yang perlu dicek.',
			'notificationCapture.inboxAutoEmpty' => 'Belum ada yang tercatat otomatis.',
			'notificationCapture.inboxRetention' => 'Daftar ini disimpan 7 hari.',
			'notificationCapture.amountUnknown' => 'Nominal belum terbaca',
			'notificationCapture.possibleDuplicate' => 'Mungkin sudah tercatat',
			'notificationCapture.recordAction' => 'Catat',
			'notificationCapture.dismissAction' => 'Abaikan',
			'notificationCapture.makePatternAction' => 'Buat pola dari teks ini',
			'notificationCapture.reviewAction' => 'Lihat',
			'notificationCapture.undoAction' => 'Batalkan',
			'notificationCapture.undoConfirmTitle' => 'Batalkan transaksi?',
			'notificationCapture.undoConfirm' => 'Transaksinya dihapus dan saldo dompet kembali seperti sebelumnya.',
			'notificationCapture.undone' => 'Transaksi otomatis dibatalkan.',
			'notificationCapture.dismissed' => 'Tangkapan diabaikan.',
			'notificationCapture.banner' => ({required Object n}) => '${n} transaksi dari notifikasi menunggu dicek',
			'notificationCapture.bannerAction' => 'Cek',
			'notificationCapture.autoRecordedSnack' => ({required Object amount, required Object app}) => 'Tercatat otomatis: ${amount} · ${app}',
			'notificationCapture.autoRecordedSnackMany' => ({required Object n}) => '${n} transaksi tercatat otomatis dari notifikasi',
			'notificationCapture.reminderChannel' => 'Catat dari notifikasi',
			'notificationCapture.reminderCapturedTitle' => 'Transaksi dari {app} tertangkap',
			'notificationCapture.reminderCapturedBody' => 'Ketuk untuk mencatat.',
			'notificationCapture.reminderReviewTitle' => ({required Object amount, required Object app}) => 'Cek ${amount} dari ${app}',
			'notificationCapture.reminderReviewBody' => 'Ketuk untuk mencatat.',
			'notificationCapture.reminderRecordedTitle' => ({required Object amount, required Object app}) => 'Tercatat ${amount} · ${app}',
			'notificationCapture.reminderRecordedBody' => 'Ketuk untuk melihat.',
			'notificationCapture.debugSamplesTitle' => 'Contoh teks tertangkap (debug)',
			'notificationCapture.debugSamplesHint' => 'Ketuk untuk menyalin. Samarkan sebelum dibagikan.',
			'notificationCapture.debugSamplesEmpty' => 'Belum ada notifikasi dari aplikasi terdaftar.',
			'notificationCapture.debugShellSource' => 'Tambah sumber uji adb (com.android.shell)',
			'notificationCapture.copied' => 'Disalin.',
			'notificationCapture.keywordsEmptyWarning' => 'Tanpa filter, tidak ada notifikasi yang dibaca.',
			'notificationCapture.addDefaultKeywords' => 'Pakai filter bawaan',
			'notificationCapture.sourceKeywordsNone' => 'Filter kosong — tidak ada yang dibaca',
			'notificationCapture.enableHint' => 'Transaksi dari notifikasi bank dan e-wallet yang kamu pilih dicatat untukmu.',
			'notificationCapture.inboxEntryTitle' => 'Kotak masuk',
			'notificationCapture.inboxEntryBody' => 'Cek tangkapan dan batalkan yang tercatat otomatis.',
			'notificationCapture.behaviorTitle' => 'Saat transaksi tertangkap',
			'notificationCapture.autoRecordLabel' => 'Catat otomatis',
			'notificationCapture.autoRecordOffHint' => 'Semua menunggu kamu cek di kotak masuk.',
			'notificationCapture.autoRecordOnHint' => 'Yang terbaca jelas langsung tersimpan. Yang ragu tetap menunggu dicek.',
			'notificationCapture.autoRecordAnyCategoryLabel' => 'Walau kategori belum terbaca',
			'notificationCapture.autoRecordAnyCategoryHint' => 'Kategori bisa kamu isi belakangan.',
			'notificationCapture.reminderLabel' => 'Kabari lewat notifikasi',
			'notificationCapture.reminderHint' => 'Muncul notifikasi tiap ada transaksi tertangkap.',
			'notificationCapture.sourceWallet' => ({required Object name}) => 'Dompet ${name}',
			'notificationCapture.walletHelp' => 'Transaksi dari aplikasi ini dicatat di dompet ini.',
			'notificationCapture.advancedTitle' => 'Filter dan pola',
			'notificationCapture.advancedHint' => 'Opsional',
			'notificationCapture.patternMarkLabel' => 'Tandai bagiannya',
			'notificationCapture.patternNotAmount' => ({required Object word}) => '"${word}" bukan nominal. Nominal memakai Rp atau titik ribuan.',
			'notificationCapture.kindTransfer' => 'Transfer',
			'notificationCapture.transferDirectionLabel' => 'Arah transfer',
			'notificationCapture.patternTransferWalletNone' => 'Belum ditentukan',
			'notificationCapture.patternTemplateToggle' => 'Sunting templat',
			'notificationCapture.moreActions' => 'Lainnya',
			'recurring.starters.salary' => 'Gaji',
			'recurring.starters.rent' => 'Kos/Sewa',
			'recurring.starters.electricity' => 'Listrik',
			'recurring.starters.internet' => 'Internet',
			'recurring.starters.bpjs' => 'BPJS',
			'recurring.starters.installment' => 'Cicilan',
			'recurring.starters.paylater' => 'Paylater',
			'recurring.starters.subscription' => 'Langganan',
			'recurring.starters.parents' => 'Kirim ke orang tua',
			'recurring.starters.arisan' => 'Arisan',
			'recurring.starters.savings' => 'Tabungan',
			'recurring.summaryTitle' => ({required Object month}) => 'Rutin ${month}',
			'recurring.remainingOutLabel' => 'Masih akan keluar',
			'recurring.recordedOfTotal' => ({required Object recorded, required Object total}) => '${recorded} dari ${total} tercatat',
			'recurring.scheduledInLabel' => 'Masuk terjadwal',
			'recurring.subscriptionsLine' => ({required Object perMonth, required Object perYear}) => 'Langganan ${perMonth}/bln · ${perYear}/thn',
			'recurring.approxSemantics' => ({required Object amount}) => 'kira-kira ${amount}',
			'recurring.filterAll' => ({required Object n}) => 'Semua (${n})',
			'recurring.filterIncome' => ({required Object n}) => 'Masuk (${n})',
			'recurring.filterExpense' => ({required Object n}) => 'Keluar (${n})',
			'recurring.filterTransfer' => ({required Object n}) => 'Transfer (${n})',
			'recurring.groupPending' => 'Menunggu dicatat',
			'recurring.groupThisMonth' => 'Bulan ini',
			'recurring.groupLater' => 'Nanti',
			'recurring.groupPaused' => 'Dijeda',
			'recurring.groupEnded' => 'Selesai',
			'recurring.recordedMeta' => 'tercatat',
			'recurring.pendingMeta' => 'menunggu',
			'recurring.missedMeta' => ({required Object n}) => '${n} terlewat',
			'recurring.skippedMeta' => 'dilewati',
			'recurring.paymentAutoDebit' => 'autodebet',
			'recurring.paymentManual' => 'bayar sendiri',
			'recurring.yearlyMeta' => 'tahunan',
			'recurring.priceUp' => ({required Object amount, required Object usual}) => '${amount}, biasanya ${usual}',
			'recurring.emptyTitle' => 'Belum ada rutin',
			'recurring.emptyBody' => 'Tambahkan yang pasti datang tiap bulan, lalu lihat berapa yang benar-benar bebas.',
			'recurring.filteredEmpty' => 'Belum ada rutin di sini.',
			'recurring.showAllAction' => 'Tampilkan semua',
			'recurring.addAction' => 'Tambah rutin',
			'recurring.loadError' => 'Rutin gagal dimuat.',
			'recurring.retryAction' => 'Coba lagi',
			'recurring.nextTitle' => 'Berikutnya',
			'recurring.recordedTitle' => 'Tercatat',
			'recurring.skipAction' => 'Lewati',
			'recurring.unskipAction' => 'Batal lewati',
			'recurring.editAction' => 'Ubah',
			'recurring.pauseAction' => 'Jeda',
			'recurring.resumeAction' => 'Lanjutkan',
			'recurring.endAction' => 'Akhiri',
			'recurring.deleteAction' => 'Hapus',
			'recurring.moreActions' => 'Aksi lain',
			'recurring.deleteTitle' => 'Hapus rutin?',
			'recurring.deleteBody' => 'Transaksi yang sudah tercatat tidak ikut terhapus.',
			'recurring.progressLine' => ({required Object k, required Object n}) => '${k} dari ${n} tercatat',
			'recurring.endsOnLine' => ({required Object date}) => 'berakhir ${date}',
			'recurring.countLine' => ({required Object n}) => '${n} kali',
			'recurring.pausedLine' => 'Dijeda',
			'recurring.reminderLine' => ({required Object n}) => 'Bayar sendiri · diingatkan H−${n}',
			'recurring.autoDebitLine' => 'Autodebet',
			'recurring.pausedMessage' => ({required Object name}) => '${name} dijeda.',
			'recurring.resumedMessage' => ({required Object name}) => '${name} dilanjutkan.',
			'recurring.endedMessage' => ({required Object name}) => '${name} diakhiri.',
			'recurring.deletedMessage' => ({required Object name}) => '${name} dihapus.',
			'recurring.skippedMessage' => ({required Object date}) => '${date} dilewati.',
			'recurring.priceUpdateAction' => ({required Object amount}) => 'Perbarui ke ${amount}',
			'recurring.notFound' => 'Rutin ini sudah tidak ada.',
			'recurring.noRecorded' => 'Belum ada yang tercatat.',
			'recurring.recordedMessage' => ({required Object name}) => '${name} tercatat.',
			'recurring.recordedAllMessage' => ({required Object n}) => '${n} rutin tercatat.',
			'recurring.linkedMessage' => ({required Object name}) => '${name} ditautkan.',
			'recurring.undoAction' => 'Batalkan',
			'recurring.similarTitle' => 'Sudah tercatat?',
			'recurring.similarBody' => ({required Object name, required Object amount, required Object date}) => 'Mirip ${name} ${amount} · ${date} yang sudah tercatat.',
			'recurring.linkAction' => 'Tautkan',
			'recurring.recordNewAction' => 'Catat baru',
			'recurring.recordAction' => 'Catat',
			'recurring.editFirstAction' => 'Ubah dulu',
			'recurring.recordAllAction' => 'Catat semua',
			'recurring.seeAllAction' => 'Lihat semua',
			'recurring.pendingCardTitle' => 'Menunggu dicatat',
			'recurring.unusualAmountNotice' => ({required Object usual}) => 'Biasanya ${usual}. Periksa lagi nominalnya.',
			'recurring.farDateNotice' => ({required Object date}) => 'Jadwalnya ${date}. Pastikan tanggalnya benar.',
			'recurring.occurrenceNotice' => ({required Object name, required Object date}) => 'Mencatat ${name} · ${date}',
			'recurring.matchLabel' => ({required Object name, required Object date}) => 'Cocok dengan rutin ${name} · ${date}',
			'recurring.linkedTitle' => 'Tercocok dengan rutin',
			'recurring.unlinkAction' => 'Lepaskan',
			'recurring.unlinkedMessage' => 'Tautan dilepas. Kemunculannya kembali menunggu.',
			'recurring.reminderChannelName' => 'Pengingat rutin',
			'recurring.reminderChannelDescription' => 'Tagihan dan pemasukan rutin yang jatuh tempo.',
			'recurring.reminderSoonTitle' => ({required Object n}) => '${n} hari lagi',
			'recurring.reminderTodayTitle' => 'Jatuh tempo hari ini',
			'recurring.reminderTodayManyTitle' => ({required Object n}) => '${n} rutin jatuh tempo hari ini',
			'recurring.alreadyRecordedMessage' => ({required Object name}) => '${name} sudah tercatat.',
			'recurring.remindersTitle' => 'Pengingat rutin',
			'recurring.remindersBody' => 'Diingatkan sehari sebelum tagihan yang dibayar sendiri, dan pada hari jatuh tempo.',
			'recurring.remindersDenied' => 'Izin notifikasi belum diberikan. Nyalakan di setelan sistem.',
			'recurring.ruleRemindersLabel' => 'Ingatkan',
			'recurring.remindersOffHint' => 'Pengingat rutin mati. Nyalakan di Akun.',
			'recurring.positionMeta' => ({required Object k, required Object n}) => '${k} dari ${n}',
			'recurring.toWalletMeta' => ({required Object wallet}) => 'ke ${wallet}',
			'recurring.remainingTitle' => ({required Object month}) => 'Sisa rutin keluar · ${month}',
			'recurring.plannedLabel' => 'Rencana',
			'recurring.outLabel' => 'Sudah keluar',
			'recurring.chipAll' => 'Semua',
			'recurring.chipIncome' => 'Masuk',
			'recurring.chipExpense' => 'Keluar',
			'recurring.chipTransfer' => 'Transfer',
			'recurring.budgetLinkLabel' => 'Pos anggaran',
			'recurring.budgetLinkNone' => 'Belum tertaut. Tautkan supaya tidak terhitung dua kali dengan anggaran.',
			'recurring.budgetLinkValue' => ({required Object item, required Object budget}) => '${item} · ${budget}',
			'recurring.budgetLinkPickerTitle' => 'Tautkan ke pos anggaran rutin',
			'recurring.budgetLinkRemove' => 'Lepas tautan',
			'recurring.budgetLinkEmpty' => 'Belum ada pos anggaran rutin di dompet ini.',
			'recurring.budgetLinkedMessage' => ({required Object name, required Object item}) => '${name} tertaut ke pos ${item}.',
			_ => null,
		} ?? switch (path) {
			'recurring.budgetUnlinkedMessage' => ({required Object name}) => 'Tautan pos ${name} dilepas.',
			'recurring.fundingTitle' => ({required Object wallet}) => 'Siapkan dana di ${wallet}',
			'recurring.fundingBody' => ({required Object name, required Object amount, required Object date, required Object shortfall}) => '${name} ${amount}, ${date}. Perkiraan kurang ≈${shortfall}.',
			'recurring.installmentFreeLine' => ({required Object month, required Object amount}) => 'Mulai ${month} ruang bebas +${amount}/bln.',
			'recurring.unseenLabel' => 'Belum terlihat di notifikasi',
			'recurring.notYetAction' => 'Belum terjadi',
			'recurring.snoozedMessage' => ({required Object name}) => '${name} ditanyakan lagi 2 hari lagi.',
			'recurring.idleTitle' => ({required Object name}) => 'Masih memakai ${name}?',
			'recurring.idleBody' => 'Dua kemunculan terakhir dilewati atau belum terlihat.',
			'recurring.idleKeep' => 'Biarkan',
			'plan.recurringSegmentLabel' => 'Rutin',
			'plan.financialMonthTitle' => 'Awal bulan keuangan',
			'plan.financialMonthPickerTitle' => 'Bulan keuangan dimulai',
			'plan.financialMonthDay' => ({required Object day}) => 'Tanggal ${day}',
			'plan.thisMonthSegmentLabel' => 'Bulan ini',
			'plan.unplannedTitle' => ({required Object month}) => 'Uang nganggur · ${month}',
			'plan.incomeRow' => 'Pemasukan',
			'plan.billsRow' => 'Tagihan rutin',
			'plan.budgetRow' => 'Anggaran',
			'plan.offPlanRow' => 'Di luar rencana',
			'plan.infoAction' => 'Penjelasan',
			'plan.infoTitle' => 'Uang nganggur',
			'plan.infoIncome' => '+ Pemasukan terencana',
			'plan.infoBills' => '− Tagihan rutin',
			'plan.infoBudget' => '− Anggaran',
			'plan.infoOffPlan' => '± Di luar rencana (sudah tercatat)',
			'plan.infoResult' => '= Uang nganggur',
			'plan.infoNotBalance' => 'Bukan saldo dompet.',
			'plan.balanceTitle' => 'Saldo dompet ≈',
			'plan.allWallets' => 'Semua',
			'plan.endOf' => ({required Object date}) => 'Akhir ${date}',
			'plan.lowestOn' => ({required Object date}) => 'Paling tipis · ${date}',
			'plan.detailsAction' => 'Rincian',
			'plan.todayLabel' => 'hari ini',
			'plan.approx' => ({required Object amount}) => 'kira-kira ${amount}',
			'plan.detailsTitle' => 'Perkiraan saldo',
			'plan.detailsNow' => 'Saldo sekarang',
			'plan.detailsIncome' => 'Pemasukan rutin',
			'plan.detailsBills' => 'Tagihan rutin',
			'plan.detailsBudget' => 'Sisa anggaran',
			'plan.detailsUnplanned' => ({required Object perDay}) => 'Di luar rencana · ${perDay}/hari',
			'plan.detailsUncertain' => 'Freelance belum dibayar (belum pasti)',
			'plan.detailsTransfers' => 'Transfer rutin',
			'plan.detailsEnd' => ({required Object date}) => 'Akhir ${date}',
			'plan.unplannedToggle' => 'Hitung jajan harian',
			'plan.unplannedUnavailable' => 'Butuh riwayat sebulan penuh.',
			'plan.nextTitle' => 'Berikutnya',
			'plan.seeAllRecurring' => 'Semua di Rutin',
			'plan.emptyTitle' => 'Rencanakan bulan ini',
			'plan.emptyBody' => 'Tambahkan yang pasti datang tiap bulan, lalu lihat berapa yang benar-benar bebas.',
			'plan.chartSemantics' => ({required Object low, required Object date, required Object end}) => 'Perkiraan saldo, paling tipis ${low} pada ${date}, akhir bulan ${end}',
			'plan.chartPoint' => ({required Object date, required Object amount}) => '${date} · ${amount}',
			'plan.forecastRow' => ({required Object date, required Object amount, required Object low, required Object lowDate}) => 'Akhir ${date} ≈${amount} · paling tipis ≈${low} (${lowDate})',
			'plan.loadError' => 'Rencana bulan ini gagal dimuat.',
			'plan.forecastBadge' => 'PERKIRAAN',
			'plan.startOf' => ({required Object date}) => 'Awal ${date}',
			'plan.compactMillion' => ({required Object value}) => '${value} jt',
			'plan.compactThousand' => ({required Object value}) => '${value} rb',
			'plan.fundingTitle' => 'SIAPKAN DANA',
			'plan.fundingBody' => ({required Object wallet, required Object shortfall, required Object name, required Object date}) => 'Saldo ${wallet} diperkirakan kurang ≈${shortfall} saat ${name}, ${date}. Siapkan dana di ${wallet} sebelum tanggal itu.',
			'plan.fundingAction' => ({required Object wallet}) => 'Lihat perkiraan ${wallet}',
			'plan.fundingMore' => ({required Object n}) => '+${n} lainnya',
			'plan.reviewTitle' => ({required Object month}) => '${month} dimulai',
			'plan.reviewProgress' => ({required Object done, required Object total}) => '${done}/${total}',
			'plan.reviewBudgets' => ({required Object amount}) => 'Anggaran rutin bulan ini ${amount}, lahir sendiri.',
			'plan.reviewEstimate' => ({required Object name, required Object amount}) => '${name} ≈${amount}, sesuai?',
			'plan.reviewLookback' => ({required Object month}) => 'Kilas balik ${month}',
			'plan.reviewOk' => 'Sesuai',
			'plan.reviewEdit' => 'Ubah',
			'plan.reviewEditEstimate' => 'Ubah perkiraan',
			'plan.reviewSee' => 'Lihat',
			'plan.reviewDone' => 'Selesai meninjau',
			'plan.reviewLater' => 'Nanti',
			'plan.reviewCollapsed' => ({required Object month, required Object done, required Object total}) => 'Tinjau rencana ${month} (${done}/${total})',
			'plan.reviewDoneMessage' => ({required Object month}) => 'Rencana ${month} siap.',
			'plan.homeReviewBody' => ({required Object income, required Object committed, required Object free}) => 'Pemasukan terjadwal ${income}, terikat ${committed}, nganggur ${free}.',
			'plan.homeReviewEstimates' => 'Ada rutin bernominal kira-kira yang perlu dicek.',
			'plan.homeReviewAction' => 'Tinjau rencana',
			'plan.lookbackTitle' => ({required Object month}) => 'Kilas balik ${month}',
			'plan.lookbackPlanned' => 'Rencana',
			'plan.lookbackActual' => 'Nyata',
			'plan.lookbackFree' => 'Uang nganggur',
			'plan.lookbackBiggest' => ({required Object line}) => 'Selisih terbesar: ${line}.',
			'plan.accuracyExact' => ({required Object month}) => 'Perkiraan ${month} tepat.',
			'plan.accuracyMissed' => ({required Object month, required Object amount}) => 'Perkiraan ${month} meleset ${amount}.',
			'plan.accuracyMissedBy' => ({required Object month, required Object amount, required Object line}) => 'Perkiraan ${month} meleset ${amount}, terbesar dari ${line}.',
			'plan.committedShare' => ({required Object percent, required Object month}) => '${percent}% pemasukan ${month} sudah terikat (rutin + anggaran).',
			'plan.committedShareVs' => ({required Object percent, required Object month, required Object previous}) => '${percent}% pemasukan ${month} sudah terikat (rutin + anggaran); bulan sebelumnya ${previous}%.',
			'plan.installmentFree' => ({required Object name, required Object month, required Object amount}) => 'Sesudah ${name} selesai, mulai ${month} ruang bebas +${amount}/bln.',
			_ => null,
		};
	}
}
