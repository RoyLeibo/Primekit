import 'package:flutter/material.dart';
import 'package:primekit/primekit.dart';

import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialize Primekit ────────────────────────────────────────────────────
  await PrimekitConfig.initialize(
    environment: PrimekitEnvironment.debug,
    logLevel: PrimekitLogLevel.verbose,
    enableAnalytics: true,
  );

  runApp(const PrimekitExampleApp());
}

class PrimekitExampleApp extends StatelessWidget {
  const PrimekitExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Primekit Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      );
}
