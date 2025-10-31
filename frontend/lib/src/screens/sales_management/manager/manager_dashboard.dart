import 'package:flutter/material.dart';
import '../../../components/header.dart';
import '../../../components/sidebar.dart';
import '../../../models/company_model.dart';
import '../../../models/service_provider_model.dart';
import '../../../models/enriched_company.dart';
import '../../../services/manager_service.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final String _logoPath = 'assets/logo/logo.png';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;

  bool _isLoading = true;
  String? _error;
  String? _salespersonName;
  List<EnrichedCompany> _companies = [];
  List<ServiceProvider> _serviceProviders = [];
  List<EnrichedWholesaler> _wholesalers = [];

  @override
  void initState() {
    super.initState();
    _loadCreatedUsers();
  }

  Future<void> _loadCreatedUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ManagerService.getCreatedUsers();
      setState(() {
        _salespersonName = data['userName'] as String?;
        final companiesList = data['companies'] as List? ?? [];
        final companies = <EnrichedCompany>[];
        for (var e in companiesList) {
          if (e != null && e is Map<String, dynamic>) {
            try {
              companies.add(EnrichedCompany.fromJson(e));
            } catch (error) {
              print('Error parsing enriched company: $error');
            }
          }
        }
        _companies = companies;
        final serviceProvidersList = data['serviceProviders'] as List? ?? [];
        final serviceProviders = <ServiceProvider>[];
        for (var e in serviceProvidersList) {
          if (e != null && e is Map<String, dynamic>) {
            try {
              serviceProviders.add(ServiceProvider.fromJson(e));
            } catch (error) {
              print('Error parsing service provider: $error');
            }
          }
        }
        _serviceProviders = serviceProviders;
        final wholesalersList = data['wholesalers'] as List? ?? [];
        final wholesalers = <EnrichedWholesaler>[];
        for (var e in wholesalersList) {
          if (e != null && e is Map<String, dynamic>) {
            try {
              wholesalers.add(EnrichedWholesaler.fromJson(e));
            } catch (error) {
              print('Error parsing enriched wholesaler: $error');
            }
          }
        }
        _wholesalers = wholesalers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openDrawer() {
    setState(() {
      _isDrawerOpen = true;
    });
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _closeDrawer() {
    setState(() {
      _isDrawerOpen = false;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      endDrawer: Drawer(
        width: 220,
        backgroundColor: Colors.transparent,
        child: SalesManagerSidebar(
          onCollapse: _closeDrawer,
          parentContext: context,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          HeaderComponent(
            logoPath: _logoPath,
            scaffoldKey: _scaffoldKey,
            onMenuPressed: _openDrawer,
          ),
          // White section with title and add button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sales Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6), // Blue color matching screenshot
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      // TODO: Implement add new company logic
                    },
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search and filter section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                      ),
                      // TODO: Implement search logic
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Color(0xFF64748B)),
                    onPressed: () {
                      // TODO: Implement filter logic
                    },
                  ),
                ),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: _isLoading
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
                                onPressed: _loadCreatedUsers,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: ListView.builder(
                            itemCount: _companies.length,
                            itemBuilder: (context, index) {
                              return _EnrichedCompanyCard(enrichedCompany: _companies[index]);
                            },
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection<T>(String title, List<T> items, Widget Function(T) itemBuilder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        items.isEmpty
            ? const Text('No items found', style: TextStyle(color: Color(0xFF718096)))
            : Column(
                children: items.map(itemBuilder).toList(),
              ),
      ],
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Company company;
  const _CompanyCard({required this.company});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: company.logoUrl != null && company.logoUrl!.isNotEmpty
            ? CircleAvatar(backgroundImage: NetworkImage(company.logoUrl!))
            : const CircleAvatar(child: Icon(Icons.business)),
        title: Text(company.businessName),
        subtitle: Text(company.email),
        trailing: Text(company.category),
      ),
    );
  }
}

class _ServiceProviderCard extends StatelessWidget {
  final ServiceProvider serviceProvider;
  const _ServiceProviderCard({required this.serviceProvider});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: serviceProvider.profileImage != null && serviceProvider.profileImage!.isNotEmpty
            ? CircleAvatar(backgroundImage: NetworkImage(serviceProvider.profileImage!))
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(serviceProvider.name),
        subtitle: Text(serviceProvider.email),
        trailing: Text(serviceProvider.userType),
      ),
    );
  }
}

class _WholesalerCard extends StatelessWidget {
  final dynamic wholesaler;
  const _WholesalerCard({required this.wholesaler});

  @override
  Widget build(BuildContext context) {
    // Fallback for dynamic structure
    final name = wholesaler['name'] ?? wholesaler['fullName'] ?? 'Wholesaler';
    final email = wholesaler['email'] ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.store)),
        title: Text(name),
        subtitle: Text(email),
      ),
    );
  }
}

class _EnrichedCompanyCard extends StatelessWidget {
  final EnrichedCompany enrichedCompany;
  const _EnrichedCompanyCard({required this.enrichedCompany});

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final company = enrichedCompany.company;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Company logo with green online indicator
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: company.logoUrl != null && company.logoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(company.logoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: company.logoUrl == null || company.logoUrl!.isEmpty
                      ? const Icon(Icons.business, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981), // Green color
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Company details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.businessName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    company.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 14,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        enrichedCompany.salespersonName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Date and delete button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(company.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFF6B7280),
                      size: 18,
                    ),
                    onPressed: () {
                      // TODO: Implement delete logic
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}