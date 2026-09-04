import 'package:flutter/material.dart';

class RescueApplicantsScreen extends StatelessWidget {
  const RescueApplicantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rescue Applicants')),
      body: ListView.builder(
        itemCount: 0,
        itemBuilder: (context, index) {
          return const ListTile();
        },
      ),
    );
  }
}
