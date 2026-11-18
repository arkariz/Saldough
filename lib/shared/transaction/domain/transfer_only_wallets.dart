/// Dompet yang hanya boleh menerima dan mengirim transfer: dompet milik tujuan
/// tabungan (ADR-048 §8.2a). Port di sini supaya `RecordTransaction` bisa
/// menegakkannya tanpa mengimpor modul tujuan; implementasinya di
/// `shared/savings_goal`, dipasang akar komposisi.
// Port DI (ADR-030), bukan fungsi: dipasang lewat kontainer.
// ignore: one_member_abstracts
abstract interface class TransferOnlyWallets {
  /// Id dompet yang hanya untuk transfer.
  Future<Set<String>> walletIds();
}

/// [TransferOnlyWallets] tanpa dompet: untuk lingkup dan uji yang tidak
/// memasang tujuan tabungan.
final class NoTransferOnlyWallets implements TransferOnlyWallets {
  /// Membuat [NoTransferOnlyWallets].
  const NoTransferOnlyWallets();

  @override
  Future<Set<String>> walletIds() async => const {};
}
