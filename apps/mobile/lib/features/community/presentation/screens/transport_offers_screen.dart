import 'package:flutter/material.dart';

class TransportOffersScreen extends StatelessWidget {
  const TransportOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transport Offers')),
      body: ListView.builder(
        itemCount: 0,
        itemBuilder: (context, index) {
          return const ListTile();
        },
      ),
    );
  }
}
