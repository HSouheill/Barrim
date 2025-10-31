import 'package:flutter/material.dart';
import '../../../services/api_services.dart';
import '../../../services/manager_service.dart';

class ManagerApprovalsPage extends StatefulWidget {
  @override
  _ManagerApprovalsPageState createState() => _ManagerApprovalsPageState();
}

class _ManagerApprovalsPageState extends State<ManagerApprovalsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List pendingCompanies = [];
  List pendingServiceProviders = [];
  List pendingWholesalers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => isLoading = true);
    
    print('=== FETCHING PENDING REQUESTS ===');
    
    // Fetch company requests
    try {
      print('Fetching company subscription requests...');
      pendingCompanies = await ManagerService.getPendingCompanySubscriptionRequests();
      print('Company requests received: ${pendingCompanies.length}');
      print('Company data: $pendingCompanies');
    } catch (e) {
      print('Error fetching company requests: $e');
      pendingCompanies = [];
    }
    
    // Fetch service provider requests
    try {
      print('Fetching service provider subscription requests...');
      pendingServiceProviders = await ManagerService.getPendingServiceProviderSubscriptionRequests();
      print('Service provider requests received: ${pendingServiceProviders.length}');
      print('Service provider data: $pendingServiceProviders');
    } catch (e) {
      print('Error fetching service provider requests: $e');
      pendingServiceProviders = [];
    }
    
    // Fetch wholesaler requests
    try {
      print('Fetching wholesaler subscription requests...');
      pendingWholesalers = await ManagerService.getPendingWholesalerSubscriptionRequests();
      print('Wholesaler requests received: ${pendingWholesalers.length}');
      print('Wholesaler data: $pendingWholesalers');
    } catch (e) {
      print('Error fetching wholesaler requests: $e');
      pendingWholesalers = [];
    }
    
    print('Setting isLoading to false');
    setState(() => isLoading = false);
    print('State updated - isLoading: $isLoading');
    print('Final counts - Companies: ${pendingCompanies.length}, Service Providers: ${pendingServiceProviders.length}, Wholesalers: ${pendingWholesalers.length}');
  }

  Future<void> _approve(String type, String id) async {
    print('=== APPROVING $type with ID: $id ===');
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Approving $type...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    bool success = false;
    try {
      if (type == 'company') {
        success = await ManagerService.approveCompanySubscription(id);
      } else if (type == 'serviceprovider') {
        success = await ManagerService.approveServiceProviderSubscription(id);
      } else if (type == 'wholesaler') {
        success = await ManagerService.approveWholesalerSubscription(id);
      }
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$type approved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _fetchAll(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve $type'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error approving $type: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving $type: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deny(String type, String id) async {
    print('=== REJECTING $type with ID: $id ===');
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rejecting $type...'),
        duration: Duration(seconds: 2),
      ),
    );
    
    bool success = false;
    try {
      if (type == 'company') {
        success = await ManagerService.rejectCompanySubscription(id);
      } else if (type == 'serviceprovider') {
        success = await ManagerService.rejectServiceProviderSubscription(id);
      } else if (type == 'wholesaler') {
        success = await ManagerService.rejectWholesalerSubscription(id);
      }
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$type rejected successfully!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        _fetchAll(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject $type'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error rejecting $type: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting $type: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildList(List items, String type) {
    print('=== BUILDING LIST FOR $type ===');
    print('Items count: ${items.length}');
    print('Items: $items');
    
    if (items.isEmpty) {
      print('No items for $type, showing empty message');
      return Center(child: Text('No pending $type.'));
    }
    
    // Debug print to see the data structure
    print('Items for $type: $items');
    
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        print('Building item $i for $type: $item');
        
        // For subscription requests, show request details
        String title = 'Subscription Request';
        String subtitle = '';
        
        if (item['companyId'] != null && item['companyId'] != '000000000000000000000000') {
          title = 'Company ID: ${item['companyId']}';
        } else if (item['serviceProviderId'] != null && item['serviceProviderId'] != '000000000000000000000000') {
          title = 'Service Provider ID: ${item['serviceProviderId']}';
        }
        
        subtitle = 'Plan ID: ${item['planId'] ?? 'N/A'} | Status: ${item['status'] ?? 'N/A'}';
        
        final id = item['id'] ?? item['_id'];
        
        print('Rendering item with title: $title, subtitle: $subtitle, id: $id');
        
        return ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: () => _approve(type, id),
                tooltip: 'Approve',
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: () => _deny(type, id),
                tooltip: 'Deny',
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('=== BUILD METHOD ===');
    print('isLoading: $isLoading');
    print('pendingCompanies length: ${pendingCompanies.length}');
    print('pendingServiceProviders length: ${pendingServiceProviders.length}');
    print('pendingWholesalers length: ${pendingWholesalers.length}');
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Manager Approvals'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _fetchAll();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Companies'),
            Tab(text: 'Service Providers'),
            Tab(text: 'Wholesalers'),
          ],
        ),
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildList(pendingCompanies, 'company'),
              _buildList(pendingServiceProviders, 'serviceprovider'),
              _buildList(pendingWholesalers, 'wholesaler'),
            ],
          ),
    );
  }
}
