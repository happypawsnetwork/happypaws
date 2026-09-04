import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/app_colors.dart';

class SponsorshipProofScreen extends StatefulWidget {
  final String id;
  const SponsorshipProofScreen({super.key, required this.id});

  @override
  State<SponsorshipProofScreen> createState() => _SponsorshipProofScreenState();
}

class _SponsorshipProofScreenState extends State<SponsorshipProofScreen> {
  late ApiClient _apiClient;
  bool _initialized = false;
  List<dynamic> _documents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _apiClient = context.read<ApiClient>();
      _fetchProofDocuments();
    }
  }

  Future<void> _fetchProofDocuments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await _apiClient.get(
        '/api/v1/community/sponsorships/${widget.id}/proof-documents',
      );
      setState(() {
        _documents = data is List ? data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document')),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Proof Documents', style: GoogleFonts.outfit()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _documents.isEmpty
          ? const Center(child: Text('No proof documents found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                final filename = doc['filename'] ?? 'document';
                final mimeType = doc['mimeType'] ?? 'unknown';
                final sizeBytes = (doc['size'] as num?)?.toInt() ?? 0;
                final url = doc['url'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      mimeType.contains('image')
                          ? Icons.image
                          : Icons.picture_as_pdf,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    title: Text(
                      filename,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '$mimeType • ${_formatSize(sizeBytes)}',
                      style: GoogleFonts.outfit(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _openDocument(url),
                      tooltip: 'Open',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
