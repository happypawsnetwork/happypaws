import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/app_colors.dart';

class MyRescuesScreen extends StatefulWidget {
  const MyRescuesScreen({super.key});

  @override
  State<MyRescuesScreen> createState() => _MyRescuesScreenState();
}

class _MyRescuesScreenState extends State<MyRescuesScreen> {
  late ApiClient _apiClient;
  bool _initialized = false;
  List<dynamic> _rescues = [];
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _apiClient = context.read<ApiClient>();
      _fetchRescues();
    }
  }

  Future<void> _fetchRescues() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await _apiClient.get('/api/v1/community/my-rescues');
      setState(() {
        _rescues = data is List ? data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Rescues', style: GoogleFonts.outfit())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _rescues.isEmpty
          ? const Center(child: Text('You have not created any rescues yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rescues.length,
              itemBuilder: (context, index) {
                final rescue = _rescues[index];
                final id = rescue['id']?.toString() ?? '';
                final title = rescue['title'] ?? 'Untitled Rescue';
                final animal = rescue['animalType'] ?? 'Unknown';
                final status = rescue['status'] ?? 'PENDING';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.outfit(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Animal: $animal',
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              context.push('/community/post/$id');
                            },
                            child: const Text('View rescue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
