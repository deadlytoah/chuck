import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkType { wifi, cellular, none, other }

class NetworkMonitor extends StateNotifier<NetworkType>
    with WidgetsBindingObserver {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final bool _skipInit;

  NetworkMonitor({bool skipInit = false})
      : _skipInit = skipInit,
        super(NetworkType.none) {
    if (!skipInit) {
      WidgetsBinding.instance.addObserver(this);
      _init();
    }
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      state = NetworkType.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      state = NetworkType.cellular;
    } else if (results.contains(ConnectivityResult.none)) {
      state = NetworkType.none;
    } else {
      // Bluetooth, VPN, etc. - treat as conservatively as 'other'
      state = NetworkType.other;
    }
  }

  bool get isUnmetered => state == NetworkType.wifi;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _connectivity.checkConnectivity().then(_updateStatus);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }
}

final networkMonitorProvider =
    StateNotifierProvider<NetworkMonitor, NetworkType>((ref) {
      return NetworkMonitor();
    });
