import 'package:flutter/material.dart';
import '../models/sponsorship.dart';

class SponsorshipSubscriptionRequestCard extends StatelessWidget {
  final SponsorshipSubscriptionRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isLoading;

  const SponsorshipSubscriptionRequestCard({
    Key? key,
    required this.request,
    this.onApprove,
    this.onReject,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${request.entityType.replaceAll('_', ' ').toUpperCase()} Request',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1C4B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Only Entity Name and Requested At
            if (request.entity != null) ...[
              _buildInfoRow('Entity', _getEntityName(request.entity!)),
              const SizedBox(height: 8),
            ],
            _buildInfoRow('Requested At', _formatDate(request.requestedAt)),

            // Action Buttons (only for pending requests)
            if (request.isPending && (onApprove != null || onReject != null)) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onApprove != null) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (onReject != null) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onReject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Reject'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getEntityName(Map<String, dynamic> entity) {
    if (entity['companyInfo'] != null) {
      return entity['companyInfo']['businessName'] ?? 'N/A';
    } else if (entity['name'] != null) {
      return entity['name'];
    } else if (entity['businessName'] != null) {
      return entity['businessName'];
    }
    return 'N/A';
  }
}
