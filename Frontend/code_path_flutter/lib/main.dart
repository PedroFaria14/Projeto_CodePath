import 'package:flutter/material.dart';
import 'pages/login.dart';

void main() => runApp(CodePath());

class CodePath extends StatelessWidget {
  const CodePath({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CodePath',
      home: const Login(),
    );
  }
}
