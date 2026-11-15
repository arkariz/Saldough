import 'dart:async';

/// Permintaan layar lain ke shell (ADR-030): shell memiliki tab dan segmennya,
/// jadi layar yang dibuka sebagai rute tidak bisa memindahkannya sendiri.
enum ShellRequest {
  /// Buka tab Rencana pada segmen Rutin.
  showPlanRecurring,
}

/// Saluran permintaan ke shell. Satu instans di akar; shell mendengarkan lewat
/// `ShellRequestHost` di bawah seluruh `BlocProvider`-nya.
final class ShellRequests {
  final _controller = StreamController<ShellRequest>.broadcast();

  /// Permintaan yang masuk.
  Stream<ShellRequest> get stream => _controller.stream;

  /// Mengirim [request].
  void send(ShellRequest request) => _controller.add(request);
}
