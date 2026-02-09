import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpyc_raceday/core/theme.dart';
import 'package:mpyc_raceday/firebase_options.dart';
import 'package:mpyc_raceday/mobile/mobile_router.dart';
import 'package:mpyc_raceday/web/web_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      routerConfig: router,
    );
  }
}
