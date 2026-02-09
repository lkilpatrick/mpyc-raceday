import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Subtle banner shown at top of screen when device is offline.
class NetworkStatusBanner extends StatefulWidget {
  const NetworkStatusBanner({super.key, required this.child});

  final Widget child;

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (mounted && offline != _isOffline) {
        setState(() => _isOffline = offline);
      }
    });
    _checkInitial();
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() =>
          _isOffline = results.every((r) => r == ConnectivityResult.none));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isOffline ? 28 : 0,
          color: Colors.grey.shade800,
          child: _isOffline
              ? const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, size: 14, color: Colors.white70),
                      SizedBox(width: 6),
                      Text(
                        'You are offline — changes will sync when reconnected',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
