import 'package:flutter/material.dart';
import '../../models/salesperson_subscription_payment.dart';
import '../../services/admin_service.dart';
import '../../services/api_services.dart';

class SalespersonDetailsScreen extends StatefulWidget {
  final String salespersonId;
  final String salespersonName;
  final String? salespersonEmail;
  final String? salespersonPhone;

  const SalespersonDetailsScreen({
    super.key,
    required this.salespersonId,
    required this.salespersonName,
    this.salespersonEmail,
    this.salespersonPhone,
  });

  @override
  State<SalespersonDetailsScreen> createState() => _SalespersonDetailsScreenState();
}

class _SalespersonDetailsScreenState extends State<SalespersonDetailsScreen> {
  final AdminService _adminService = AdminService(baseUrl: ApiService.baseUrl);
  SalespersonCreatedEntitiesResponse _entities = const SalespersonCreatedEntitiesResponse.empty();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionPayments();
  }

  Future<void> _loadSubscriptionPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _adminService.getSalespersonSubscriptionPayments(
        salespersonId: widget.salespersonId,
      );

      if (response['success']) {
        final data = response['data'];
        setState(() {
          if (data is Map<String, dynamic>) {
            _entities = SalespersonCreatedEntitiesResponse.fromJson(
              Map<String, dynamic>.from(data),
            );
          } else {
            _entities = const SalespersonCreatedEntitiesResponse.empty();
          }
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load subscription payments');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'inactive':
        return Colors.red;
      case 'no_subscription':
        return Colors.grey.shade600;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.salespersonName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSubscriptionPayments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Companies Section
                      if (_entities.companies.isNotEmpty) ...[
                        _buildSectionHeader('Companies', _entities.companies.length, Icons.business),
                        const SizedBox(height: 12),
                        ..._entities.companies.map((company) => _buildCompanyCard(company)),
                        const SizedBox(height: 24),
                      ],

                      // Wholesalers Section
                      if (_entities.wholesalers.isNotEmpty) ...[
                        _buildSectionHeader('Wholesalers', _entities.wholesalers.length, Icons.store),
                        const SizedBox(height: 12),
                        ..._entities.wholesalers.map((wholesaler) => _buildWholesalerCard(wholesaler)),
                        const SizedBox(height: 24),
                      ],

                      // Service Providers Section
                      if (_entities.serviceProviders.isNotEmpty) ...[
                        _buildSectionHeader('Service Providers', _entities.serviceProviders.length, Icons.handyman),
                        const SizedBox(height: 12),
                        ..._entities.serviceProviders.map((sp) => _buildServiceProviderCard(sp)),
                      ],

                      // Empty State
                      if (_entities.totalUsers == 0)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No users created yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A1747),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyCard(CompanySubscriptionPayment company) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  company.isSponsorship ? Icons.star : Icons.business,
                  color: company.isSponsorship ? Colors.amber : const Color(0xFF1565C0),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    company.companyName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(company.status, _getStatusColor(company.status)),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Branch', company.branchName),
            if (company.hasNoSubscription) ...[
              _buildDetailRow('Status', 'No Subscription', Colors.grey.shade600),
            ] else ...[
              _buildDetailRow(
                'Subscription Type',
                company.isSponsorship ? 'Sponsorship' : 'Plan',
                company.isSponsorship ? Colors.amber.shade700 : const Color(0xFF1565C0),
              ),
              if (company.isSponsorship) ...[
                if (company.sponsorshipTitle != null && company.sponsorshipTitle!.isNotEmpty)
                  _buildDetailRow('Sponsorship', company.sponsorshipTitle!),
                if (company.sponsorshipPrice != null)
                  _buildDetailRow('Price', '\$${company.sponsorshipPrice!.toStringAsFixed(2)}'),
              ] else ...[
                if (company.planTitle.isNotEmpty)
                  _buildDetailRow('Plan', company.planTitle),
                if (company.planPrice > 0)
                  _buildDetailRow('Price', '\$${company.planPrice.toStringAsFixed(2)}'),
              ],
            ],
            if (!company.hasNoSubscription) ...[
              if (company.paymentMethod.isNotEmpty)
                _buildDetailRow('Payment Method', company.paymentMethod),
              if (company.requestedAt.year > 2000)
                _buildDetailRow('Requested At', _formatDate(company.requestedAt)),
              if (company.paidAt != null)
                _buildDetailRow('Paid At', _formatDate(company.paidAt)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWholesalerCard(WholesalerSubscriptionPayment wholesaler) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  wholesaler.isSponsorship ? Icons.star : Icons.store,
                  color: wholesaler.isSponsorship ? Colors.amber : const Color(0xFF1565C0),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    wholesaler.wholesalerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(wholesaler.status, _getStatusColor(wholesaler.status)),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Branch', wholesaler.branchName),
            _buildDetailRow(
              'Subscription Type',
              wholesaler.isSponsorship ? 'Sponsorship' : 'Plan',
              wholesaler.isSponsorship ? Colors.amber.shade700 : const Color(0xFF1565C0),
            ),
            if (wholesaler.isSponsorship) ...[
              if (wholesaler.sponsorshipTitle != null && wholesaler.sponsorshipTitle!.isNotEmpty)
                _buildDetailRow('Sponsorship', wholesaler.sponsorshipTitle!),
              if (wholesaler.sponsorshipPrice != null)
                _buildDetailRow('Price', '\$${wholesaler.sponsorshipPrice!.toStringAsFixed(2)}'),
            ] else ...[
              if (wholesaler.planTitle.isNotEmpty)
                _buildDetailRow('Plan', wholesaler.planTitle),
              if (wholesaler.planPrice > 0)
                _buildDetailRow('Price', '\$${wholesaler.planPrice.toStringAsFixed(2)}'),
            ],
            if (wholesaler.paymentMethod.isNotEmpty)
              _buildDetailRow('Payment Method', wholesaler.paymentMethod),
            if (wholesaler.requestedAt.year > 2000)
              _buildDetailRow('Requested At', _formatDate(wholesaler.requestedAt)),
            if (wholesaler.paidAt != null)
              _buildDetailRow('Paid At', _formatDate(wholesaler.paidAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceProviderCard(ServiceProviderSubscriptionPayment sp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  sp.isSponsorship ? Icons.star : Icons.handyman,
                  color: sp.isSponsorship ? Colors.amber : const Color(0xFF1565C0),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sp.businessName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(sp.status, _getStatusColor(sp.status)),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Subscription Type',
              sp.isSponsorship ? 'Sponsorship' : 'Plan',
              sp.isSponsorship ? Colors.amber.shade700 : const Color(0xFF1565C0),
            ),
            if (sp.isSponsorship) ...[
              if (sp.sponsorshipTitle != null && sp.sponsorshipTitle!.isNotEmpty)
                _buildDetailRow('Sponsorship', sp.sponsorshipTitle!),
              if (sp.sponsorshipPrice != null)
                _buildDetailRow('Price', '\$${sp.sponsorshipPrice!.toStringAsFixed(2)}'),
            ] else ...[
              if (sp.planTitle.isNotEmpty)
                _buildDetailRow('Plan', sp.planTitle),
              if (sp.planPrice > 0)
                _buildDetailRow('Price', '\$${sp.planPrice.toStringAsFixed(2)}'),
            ],
            if (sp.paymentMethod.isNotEmpty)
              _buildDetailRow('Payment Method', sp.paymentMethod),
            if (sp.requestedAt.year > 2000)
              _buildDetailRow('Requested At', _formatDate(sp.requestedAt)),
            if (sp.paidAt != null)
              _buildDetailRow('Paid At', _formatDate(sp.paidAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black87,
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

