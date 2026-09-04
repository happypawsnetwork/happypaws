import 'package:flutter/material.dart';

class MyRescuesScreen extends StatelessWidget {
  const MyRescuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Rescues')),
      body: ListView.builder(
        itemCount: 0,
        itemBuilder: (context, index) {
          return const ListTile();
        },
      ),
    );
  }
}
