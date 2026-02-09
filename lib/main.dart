import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpyc_raceday/core/error_handler.dart';
import 'package:mpyc_raceday/core/offline_queue.dart';
import 'package:mpyc_raceday/core/theme.dart';
import 'package:mpyc_raceday/firebase_options.dart';
import 'package:mpyc_raceday/mobile/mobile_router.dart';
import 'package:mpyc_raceday/shared/widgets/network_status_banner.dart';
import 'package:mpyc_raceday/web/web_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler
  ErrorHandler.init();

  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Optional at runtime in local/dev. CLUBSPOT_API_KEY can also be passed via --dart-define.
    }
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Already initialized (e.g. by google-services.json on Android)
  }

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize offline write queue
  OfflineQueue.instance.init();

  runApp(const ProviderScope(child: MpycRacedayApp()));
}

class MpycRacedayApp extends StatelessWidget {
  const MpycRacedayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = kIsWeb ? webRouter : mobileRouter;

    return MaterialApp.router(
      title: 'MPYC Raceday',
      debugShowCheckedModeBanner: false,
      theme: kIsWeb ? AppTheme.webTheme : AppTheme.mobileTheme,
      darkTheme: kIsWeb ? null : AppTheme.mobileDarkTheme,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        // Wrap with network status banner on mobile
        if (!kIsWeb) {
          return NetworkStatusBanner(child: child);
        }
        return child;
      },
    );
  }
}
