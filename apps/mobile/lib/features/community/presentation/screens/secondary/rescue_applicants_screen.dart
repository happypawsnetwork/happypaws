import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/app_colors.dart';

class RescueApplicantsScreen extends StatefulWidget {
  const RescueApplicantsScreen({super.key});

  @override
  State<RescueApplicantsScreen> createState() => _RescueApplicantsScreenState();
}

class _RescueApplicantsScreenState extends State<RescueApplicantsScreen> {
  late ApiClient _apiClient;
  bool _initialized = false;
  List<dynamic> _applicants = [];
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _apiClient = context.read<ApiClient>();
      _fetchApplicants();
    }
  }

  Future<void> _fetchApplicants() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await _apiClient.get(
        '/api/v1/community/rescue-applications',
      );
      setState(() {
        _applicants = data is List ? data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _reviewApplicant(String id, bool approved) async {
    try {
      await _apiClient.patch(
        '/api/v1/community/rescue-applications/$id/review',
        body: {'approved': approved},
      );
      _fetchApplicants();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rescue Applicants', style: GoogleFonts.outfit()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _applicants.isEmpty
          ? const Center(child: Text('No applicants found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _applicants.length,
              itemBuilder: (context, index) {
                final item = _applicants[index];
                final applicantId = item['id']?.toString() ?? '';
                final name = item['applicantName'] ?? 'Unknown';
                final role = item['role'] ?? 'Applicant';
                final avatarUrl = item['avatarUrl'] as String?;
                final status = item['status'] as String?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  role,
                                  style: GoogleFonts.outfit(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (status == 'PENDING') ...[
                          IconButton(
                            icon: const Icon(
                              Icons.check,
                              color: AppColors.success,
                            ),
                            onPressed: () =>
                                _reviewApplicant(applicantId, true),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.error,
                            ),
                            onPressed: () =>
                                _reviewApplicant(applicantId, false),
                          ),
                        ] else ...[
                          Text(
                            status ?? '',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: status == 'APPROVED'
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
