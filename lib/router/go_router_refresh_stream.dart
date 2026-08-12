// lib/router/go_router_refresh_stream.dart
import 'package:flutter/foundation.dart';
import 'dart:async';

/// A simple [ChangeNotifier] that listens to a [Stream] and calls
/// `notifyListeners()` whenever the stream emits a new event. This can be
/// used as the `refreshListenable` for a [GoRouter] when you want the router
/// to react to Riverpod state changes (e.g., auth token updates).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
