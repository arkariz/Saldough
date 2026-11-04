import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';

void main() {
  test('capture_inbox_opened: jumlah per kelas kartu', () {
    final event = CaptureEvents.inboxOpened(planned: 1, recognized: 2, needsInput: 3);

    expect(event.name, 'capture_inbox_opened');
    expect(event.parameters, {'planned': 1, 'recognized': 2, 'needs_input': 3});
  });

  test('capture_card_action: aksi dan kelas saja', () {
    final event = CaptureEvents.cardAction(action: 'one_tap', cardClass: 'recognized');

    expect(event.name, 'capture_card_action');
    expect(event.parameters, {'action': 'one_tap', 'card_class': 'recognized'});
  });

  test('capture_record_saved: lewat mana CATAT dibuka', () {
    final event = CaptureEvents.recordSaved(via: 'edit_first', cardClass: 'planned');

    expect(event.name, 'capture_record_saved');
    expect(event.parameters, {'via': 'edit_first', 'card_class': 'planned'});
  });

  test('parameter hanya angka kecil atau kata kunci, tanpa nominal atau teks bebas (ADR-023)', () {
    final events = [
      CaptureEvents.inboxOpened(planned: 0, recognized: 0, needsInput: 0),
      CaptureEvents.cardAction(action: 'dismiss', cardClass: 'needs_input'),
      CaptureEvents.recordSaved(via: 'record', cardClass: 'needs_input'),
    ];
    for (final event in events) {
      for (final value in event.parameters.values) {
        expect(value, anyOf(isA<int>(), matches(RegExp(r'^[a-z_]+$'))));
      }
    }
  });
}
