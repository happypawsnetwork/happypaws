import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/verified_badge.dart';

class TransportOffersScreen extends StatefulWidget {
  final String taskId;
  const TransportOffersScreen({super.key, required this.taskId});

  @override
  State<TransportOffersScreen> createState() => _TransportOffersScreenState();
}

class _TransportOffersScreenState extends State<TransportOffersScreen> {
  late ApiClient _apiClient;
  bool _initialized = false;
  List<dynamic> _offers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _apiClient = context.read<ApiClient>();
      _fetchOffers();
    }
  }

  Future<void> _fetchOffers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await _apiClient.get(
        '/api/v1/community/transport-tasks/${widget.taskId}',
      );
      setState(() {
        _offers = (data?['offers'] as List?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptOffer(String offerId) async {
    try {
      await _apiClient.post(
        '/api/v1/community/transport-offers/$offerId/accept',
      );
      _fetchOffers();
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
        title: Text('Transport Offers', style: GoogleFonts.outfit()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _offers.isEmpty
          ? const Center(child: Text('No offers available for this task.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _offers.length,
              itemBuilder: (context, index) {
                final offer = _offers[index];
                final offerId = offer['id']?.toString() ?? '';
                final transporterName =
                    offer['transporterName'] ?? 'Unknown Transporter';
                final isTransporterVerified =
                    offer['isTransporterVerified'] as bool? ?? false;
                final pickupWindow = offer['pickupWindow'] ?? 'Anytime';
                final message = offer['message'] ?? '';
                final status = offer['status'] as String?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                transporterName,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isTransporterVerified) ...[
                              const SizedBox(width: 4),
                              const VerifiedBadge(size: 14),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pickup: $pickupWindow',
                              style: GoogleFonts.outfit(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(message, style: GoogleFonts.outfit()),
                        ],
                        const SizedBox(height: 16),
                        if (status == 'PENDING')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _acceptOffer(offerId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.surface,
                              ),
                              child: const Text('Accept offer'),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'ACCEPTED'
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.textSecondary.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Status: $status',
                              style: GoogleFonts.outfit(
                                color: status == 'ACCEPTED'
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
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
