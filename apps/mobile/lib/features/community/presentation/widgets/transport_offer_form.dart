import 'package:flutter/material.dart';

class TransportOfferForm extends StatefulWidget {
  const TransportOfferForm({super.key});

  @override
  State<TransportOfferForm> createState() => _TransportOfferFormState();
}

class _TransportOfferFormState extends State<TransportOfferForm> {
  final _messageController = TextEditingController();
  DateTime? _pickupStart;
  DateTime? _pickupEnd;

  @override
  void dispose() {
    _messageController.dispose();
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
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(labelText: 'Message (optional)'),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(
              _pickupStart == null
                  ? 'Select Pickup Start'
                  : _pickupStart.toString(),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) {
                setState(() {
                  _pickupStart = date;
                });
              }
            },
          ),
          ListTile(
            title: Text(
              _pickupEnd == null ? 'Select Pickup End' : _pickupEnd.toString(),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) {
                setState(() {
                  _pickupEnd = date;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Submit offer'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
