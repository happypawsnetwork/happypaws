import 'package:flutter/material.dart';

class SponsorshipProofScreen extends StatelessWidget {
  const SponsorshipProofScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proof Documents')),
      body: ListView.builder(
        itemCount: 0,
        itemBuilder: (context, index) {
          return const ListTile();
        },
      ),
    );
  }
}
