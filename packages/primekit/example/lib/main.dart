import 'package:flutter/material.dart';
import 'package:primekit/primekit.dart';

void main() {
  runApp(
    ErrorBoundary(
      reporter: CrashConfig.reporter,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'PrimeKit Example',
      home: Scaffold(
        body: Center(child: Text('PrimeKit Example')),
      ),
    );
  }
}
