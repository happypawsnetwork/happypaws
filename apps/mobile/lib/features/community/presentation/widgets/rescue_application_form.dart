import 'package:flutter/material.dart';

class RescueApplicationForm extends StatefulWidget {
  const RescueApplicationForm({super.key});

  @override
  State<RescueApplicationForm> createState() => _RescueApplicationFormState();
}

class _RescueApplicationFormState extends State<RescueApplicationForm> {
  final _messageController = TextEditingController();
  final _experienceController = TextEditingController();
  bool _hasVehicle = false;
  String _role = 'foster';

  @override
  void dispose() {
    _messageController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'foster', label: Text('Foster')),
              ButtonSegment(value: 'adopter', label: Text('Adopter')),
            ],
            selected: {_role},
            onSelectionChanged: (set) {
              setState(() {
                _role = set.first;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _experienceController,
            decoration: const InputDecoration(labelText: 'Experience summary'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(labelText: 'Message (optional)'),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('I have a vehicle'),
            value: _hasVehicle,
            onChanged: (val) {
              setState(() {
                _hasVehicle = val ?? false;
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Submit application'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
