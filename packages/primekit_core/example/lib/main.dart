import 'package:flutter/material.dart';
import 'package:primekit_core/primekit_core.dart';

void main() {
  // Example: validate user input with PkSchema
  final schema = PkSchema({
    'email': PkField.string().email(),
    'age': PkField.number().min(0).max(150),
  });

  final result = schema.validate({'email': 'user@example.com', 'age': 30});
  debugPrint('Validation result: $result');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'PrimeKit Core Example',
      home: Scaffold(
        body: Center(child: Text('PrimeKit Core Example')),
      ),
    );
  }
}
