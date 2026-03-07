import 'package:flutter/material.dart';
import 'package:primekit_firebase/primekit_firebase.dart';

// ignore: unused_element
Future<void> _setup() async {
  // Configure crash reporting with Firebase Crashlytics
  await CrashConfig.initialize(FirebaseCrashReporter());
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'PrimeKit Firebase Example',
      home: Scaffold(
        body: Center(child: Text('PrimeKit Firebase Example')),
      ),
    );
  }
}
