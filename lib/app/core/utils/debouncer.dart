import 'dart:async';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
  }

  bool get isActive => _timer?.isActive ?? false;
}

/// Periodic batcher: accumulates items and flushes at fixed intervals
class PeriodicBatcher<T> {
  final int intervalMs;
  final void Function(List<T> batch) onFlush;
  final List<T> _buffer = [];
  Timer? _timer;

  PeriodicBatcher({
    required this.intervalMs,
    required this.onFlush,
  });

  void add(T item) {
    _buffer.add(item);
    _startTimer();
  }

  void _startTimer() {
    _timer ??= Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => flush(),
    );
  }

  void flush() {
    if (_buffer.isNotEmpty) {
      final batch = List<T>.from(_buffer);
      _buffer.clear();
      onFlush(batch);
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    flush();
    stop();
  }
}
