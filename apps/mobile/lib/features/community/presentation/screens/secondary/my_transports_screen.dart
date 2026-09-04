import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/app_colors.dart';

class MyTransportsScreen extends StatefulWidget {
  const MyTransportsScreen({super.key});

  @override
  State<MyTransportsScreen> createState() => _MyTransportsScreenState();
}

class _MyTransportsScreenState extends State<MyTransportsScreen> {
  late ApiClient _apiClient;
  bool _initialized = false;
  List<dynamic> _activeTransports = [];
  List<dynamic> _completedTransports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _apiClient = context.read<ApiClient>();
      _fetchTransports();
    }
  }

  Future<void> _fetchTransports() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await _apiClient.get('/api/v1/community/my-transports');
      final allTransports = data is List ? data : [];

      setState(() {
        _activeTransports = allTransports
            .where((t) => t['status'] != 'COMPLETED')
            .toList();
        _completedTransports = allTransports
            .where((t) => t['status'] == 'COMPLETED')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildTransportList(List<dynamic> transports, String emptyMessage) {
    if (transports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(emptyMessage, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transports.length,
      itemBuilder: (context, index) {
        final transport = transports[index];

        final destination = transport['destination'] ?? 'Unknown destination';
        final status = transport['status'] ?? 'PENDING';
        final date = transport['scheduledDate'] ?? 'Not scheduled';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.directions_car, color: AppColors.surface),
            ),
            title: Text(
              'To: $destination',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Date: $date', style: GoogleFonts.outfit()),
                const SizedBox(height: 4),
                Text(
                  'Status: $status',
                  style: GoogleFonts.outfit(color: AppColors.primary),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Optionally navigate to details
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Transports', style: GoogleFonts.outfit()),
          bottom: TabBar(
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.outfit(),
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : TabBarView(
                children: [
                  _buildTransportList(
                    _activeTransports,
                    'No active transports.',
                  ),
                  _buildTransportList(
                    _completedTransports,
                    'No completed transports.',
                  ),
                ],
              ),
      ),
    );
  }
}
