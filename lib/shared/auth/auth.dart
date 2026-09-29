/// Identitas opsional (ADR-023): masuk Google, keluar, hapus akun. Tidak
/// menyimpan atau menyinkronkan dompet/transaksi/anggaran — murni identitas.
library;

export 'data/repositories/firebase_auth_repository_impl.dart';
export 'domain/auth_failure_codes.dart';
export 'domain/entities/app_user.dart';
export 'domain/repositories/auth_repository.dart';
