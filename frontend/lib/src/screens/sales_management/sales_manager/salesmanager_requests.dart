import 'package:flutter/material.dart';
import '../../../services/sales_manager_service.dart';
import '../../../components/header.dart';
import '../../../components/sidebar.dart';
import '../../../utils/auth_manager.dart';

class SalesManagerRequestsPage extends StatefulWidget {
  const SalesManagerRequestsPage({Key? key}) : super(key: key);

  @override
  State<SalesManagerRequestsPage> createState() => _SalesManagerRequestsPageState();
}

class _SalesManagerRequestsPageState extends State<SalesManagerRequestsPage> {
  final SalesManagerService _service = SalesManagerService.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _pendingCompanies = [];
  List<dynamic> _pendingWholesalers = [];
  List<dynamic> _pendingServiceProviders = [];
  bool? _hasAccess;
  
  // Salesperson summary data

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  void initState() {
    super.initState();
    _fetchAllRequests();
  }

  // Removed access check; always fetch requests

  
  Future<void> _fetchAllRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final companiesResp = await _service.getPendingCompanies();
      final wholesalersResp = await _service.getPendingWholesalers();
      final serviceProvidersResp = await _service.getPendingServiceProviders();
      if (companiesResp.status == Status.error) throw companiesResp.message;
      if (wholesalersResp.status == Status.error) throw wholesalersResp.message;
      if (serviceProvidersResp.status == Status.error) throw serviceProvidersResp.message;
      setState(() {
        _pendingCompanies = companiesResp.data ?? [];
        _pendingWholesalers = wholesalersResp.data ?? [];
        _pendingServiceProviders = serviceProvidersResp.data ?? [];
        _isLoading = false;
      });
      
      // Calculate salesperson request counts
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleApprove(String type, String id) async {
    setState(() => _isLoading = true);
    try {
      ApiResponse<String> resp;
      if (type == 'company') {
        resp = await _service.approvePendingCompany(id);
      } else if (type == 'wholesaler') {
        resp = await _service.approvePendingWholesaler(id);
      } else if (type == 'serviceProvider') {
        resp = await _service.approvePendingServiceProvider(id);
      } else {
        resp = ApiResponse.error('Unknown type');
      }
      // if (resp.status == Status.COMPLETED) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text(resp.message), backgroundColor: Colors.green),
      //   );
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text(resp.message), backgroundColor: Colors.red),
      //   );
      // }
      await _fetchAllRequests();
      // Refresh salesperson counts after approval
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleReject(String type, String id) async {
    setState(() => _isLoading = true);
    try {
      ApiResponse<String> resp;
      if (type == 'company') {
        resp = await _service.rejectPendingCompany(id);
      } else if (type == 'wholesaler') {
        resp = await _service.rejectPendingWholesaler(id);
      } else if (type == 'serviceProvider') {
        resp = await _service.rejectPendingServiceProvider(id);
      } else {
        resp = ApiResponse.error('Unknown type');
      }
      if (resp.status == Status.completed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp.message), backgroundColor: Colors.red),
        );
      }
      await _fetchAllRequests();
      // Refresh salesperson counts after rejection
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildRequestList(String title, List<dynamic> items, String type) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No pending $title requests.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            '$title Requests',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        ...items.map((item) {
          // Get business name from the correct structure
          String businessName = '';
          if (type == 'company') {
            businessName = item['company']?['businessName'] ?? 'No Name';
          } else if (type == 'wholesaler') {
            businessName = item['wholesaler']?['businessName'] ?? 'No Name';
          } else if (type == 'serviceProvider') {
            businessName = item['serviceProvider']?['businessName'] ?? 'No Name';
          }

          // Get additional info
          String category = '';
          String phone = '';
          if (type == 'company') {
            category = item['company']?['category'] ?? '';
            phone = item['company']?['contactInfo']?['phone'] ?? '';
          } else if (type == 'wholesaler') {
            category = item['wholesaler']?['category'] ?? '';
            phone = item['wholesaler']?['contactInfo']?['phone'] ?? '';
          } else if (type == 'serviceProvider') {
            category = item['serviceProvider']?['category'] ?? '';
            phone = item['serviceProvider']?['contactInfo']?['phone'] ?? '';
          }

          // Get email from the main item
          String email = item['email'] ?? '';
          
          // Get salesperson information
          String salespersonEmail = item['salespersonEmail'] ?? 'Not specified';
          String salespersonName = item['salespersonName'] ?? 'Not specified';
          
          // Debug: Print the item structure to see available fields
          print('Request item structure: ${item.keys.toList()}');
          print('Salesperson data - Name: $salespersonName, Email: $salespersonEmail');

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(businessName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category.isNotEmpty) Text(
                    'Category: $category',
                    style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontStyle: FontStyle.italic,
                          ),
                  ),
                  if (phone.isNotEmpty) Text(
                    'Phone: $phone',
                    style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontStyle: FontStyle.italic,
                          ),
                  ),
                  if (email.isNotEmpty) Text(
                    'Email: $email',
                    style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontStyle: FontStyle.italic,
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                          'Salesperson: $salespersonName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                  const SizedBox(height: 2),
                  Text(
                    'Salesperson Email: $salespersonEmail',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _handleApprove(type, item['_id']),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _handleReject(type, item['_id']),
                    tooltip: 'Reject',
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Drawer(
        width: 220,
        backgroundColor: Colors.transparent,
        child: SalesManagerSidebar(
          onCollapse: () => Navigator.of(context).pop(),
          parentContext: context,
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: HeaderComponent(
            logoPath: 'assets/logo/logo.png',
            scaffoldKey: _scaffoldKey,
            onMenuPressed: _openDrawer,
            backgroundColor: const Color(0xFF5B87EA),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error:  [31m [1m [4m [7m$_error [0m'))
              : RefreshIndicator(
                  onRefresh: _fetchAllRequests,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          'Pending Requests',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        
                        
                        _buildRequestList('Company', _pendingCompanies, 'company'),
                        const SizedBox(height: 16),
                        _buildRequestList('Wholesaler', _pendingWholesalers, 'wholesaler'),
                        const SizedBox(height: 16),
                        _buildRequestList('Service Provider', _pendingServiceProviders, 'serviceProvider'),
                      ],
                    ),
                  ),
                ),
    );
  }
}
