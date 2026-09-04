import 'package:flutter/material.dart';

class MyTransportsScreen extends StatelessWidget {
  const MyTransportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Transports')),
      body: ListView.builder(
        itemCount: 0,
        itemBuilder: (context, index) {
          return const ListTile();
        },
      ),
    );
  }
}
