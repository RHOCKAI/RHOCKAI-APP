import 'dart:async';

/// Debounce utility to prevent rapid-fire function calls
class Debounce {
  final Duration duration;
  Timer? _timer;
  
  Debounce({this.duration = const Duration(milliseconds: 500)});
  
  /// Call function after debounce duration
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }
  
  /// Cancel pending debounced call
  void cancel() {
    _timer?.cancel();
  }
  
  /// Dispose of the debounce timer
  void dispose() {
    _timer?.cancel();
  }
}

/// Throttle utility to limit function call frequency
class Throttle {
  final Duration duration;
  Timer? _timer;
  bool _isThrottled = false;
  
  Throttle({this.duration = const Duration(milliseconds: 500)});
  
  /// Call function immediately if not throttled, then throttle for duration
  void call(void Function() action) {
    if (!_isThrottled) {
      action();
      _isThrottled = true;
      _timer = Timer(duration, () {
        _isThrottled = false;
      });
    }
  }
  
  /// Cancel throttle
  void cancel() {
    _timer?.cancel();
    _isThrottled = false;
  }
  
  /// Dispose of the throttle timer
  void dispose() {
    _timer?.cancel();
  }
}

/// Extension for easy debouncing on functions
extension DebouncedFunction on void Function() {
  void debounced([Duration duration = const Duration(milliseconds: 500)]) {
    final debounce = Debounce(duration: duration);
    debounce.call(this);
  }
  
  void throttled([Duration duration = const Duration(milliseconds: 500)]) {
    final throttle = Throttle(duration: duration);
    throttle.call(this);
  }
}
