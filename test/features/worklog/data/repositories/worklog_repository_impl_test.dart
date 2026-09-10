import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/worklog/data/repositories/worklog_repository_impl.dart';
import 'package:saldough/features/worklog/domain/entities/work_log_entry.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late WorklogRepositoryImpl repository;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = WorklogRepositoryImpl(storage: storage);
  });

  group('WorklogRepositoryImpl', () {
    test('entri tanpa startsNewBook menyambung ke buku terbuka yang sama (FR-TIME-002)', () async {
      final first = WorkLogEntry(id: 'e1', date: DateTime(2026, 8, 29), hours: 8, startsNewBook: true);
      final second = WorkLogEntry(id: 'e2', date: DateTime(2026, 9, 2), hours: 7);

      await repository.addEntry(sourceId: 'gaji-menul', entry: first);
      final result = await repository.addEntry(sourceId: 'gaji-menul', entry: second);

      final book = result.getOrElse((_) => throw StateError('expected Right'));
      expect(book.entries, hasLength(2));
      expect(book.totalHours, 15);
      expect(book.isClosed, isFalse);
    });

    test('entri ber-startsNewBook memulai buku baru, tidak menyambung ke yang lama', () async {
      final first = WorkLogEntry(id: 'e1', date: DateTime(2026, 8, 29), hours: 8, startsNewBook: true);
      final second = WorkLogEntry(id: 'e2', date: DateTime(2026, 10, 3), hours: 12, startsNewBook: true);

      await repository.addEntry(sourceId: 'gaji-menul', entry: first);
      await repository.addEntry(sourceId: 'gaji-menul', entry: second);

      final booksResult = await repository.listBooks('gaji-menul');
      final books = booksResult.getOrElse((_) => throw StateError('expected Right'));
      expect(books, hasLength(2));
      expect(books[0].totalHours, 8);
      expect(books[1].totalHours, 12);
    });

    test('entri baru setelah buku ditutup memulai buku baru walau startsNewBook false', () async {
      final first = WorkLogEntry(id: 'e1', date: DateTime(2026, 8, 29), hours: 8, startsNewBook: true);
      await repository.addEntry(sourceId: 'gaji-menul', entry: first);
      final books = (await repository.listBooks('gaji-menul')).getOrElse((_) => []);
      await repository.saveBook(books.single.close(netPayAmount: 1));

      final second = WorkLogEntry(id: 'e2', date: DateTime(2026, 10, 4), hours: 5);
      final result = await repository.addEntry(sourceId: 'gaji-menul', entry: second);

      final newBook = result.getOrElse((_) => throw StateError('expected Right'));
      expect(newBook.entries, hasLength(1));
      expect(newBook.isClosed, isFalse);
    });

    test('buku dari sumber berbeda tidak saling bercampur', () async {
      final a = WorkLogEntry(id: 'a1', date: DateTime(2026, 8, 29), hours: 8, startsNewBook: true);
      final b = WorkLogEntry(id: 'b1', date: DateTime(2026, 8, 29), hours: 3, startsNewBook: true);
      await repository.addEntry(sourceId: 'sumber-a', entry: a);
      await repository.addEntry(sourceId: 'sumber-b', entry: b);

      final booksA = (await repository.listBooks('sumber-a')).getOrElse((_) => []);
      expect(booksA, hasLength(1));
      expect(booksA.single.totalHours, 8);
    });
  });
}
