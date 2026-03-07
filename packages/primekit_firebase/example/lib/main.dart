import 'package:flutter/material.dart';
import 'package:primekit_firebase/primekit_firebase.dart';

// Example: create the crash reporter and storage uploader.
// In a real app, pass these to the corresponding PrimeKit initializers.
// ignore: unused_element
void _createServices() {
  // ignore: unused_local_variable
  final crashReporter = FirebaseCrashReporter();
  // ignore: unused_local_variable
  final storageUploader = FirebaseStorageUploader();
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
