import 'package:flutter/material.dart';
import '../../services/manager_service.dart';
import '../../services/api_services.dart';

class ManagerSubscriptionsPage extends StatefulWidget {
  @override
  _ManagerSubscriptionsPageState createState() => _ManagerSubscriptionsPageState();
}

class _ManagerSubscriptionsPageState extends State<ManagerSubscriptionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List pendingCompanies = [];
  List pendingServiceProviders = [];
  List pendingWholesalers = [];
  bool isLoading = true;
  bool hasAccess = false;
  bool accessChecked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAccessAndFetch();
  }

  Future<void> _checkAccessAndFetch() async {
    setState(() => isLoading = true);
    
    // First check if user has access
    try {
      hasAccess = await ApiService.hasFinancialDashboardAccess();
      print('Access check result: $hasAccess');
    } catch (e) {
      print('Error checking access: $e');
      hasAccess = false;
    }
    
    setState(() => accessChecked = true);
    
    if (hasAccess) {
      // Only fetch data if user has access
      await _fetchAll();
    } else {
      setState(() => isLoading = false);
    }
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
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading company requests: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
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
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading service provider requests: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
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
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading wholesaler requests: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No pending $type',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
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
        
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(subtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _approve(type, id),
                  tooltip: 'Approve',
                ),
                IconButton(
                  icon: Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _deny(type, id),
                  tooltip: 'Deny',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccessDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.red[400],
          ),
          SizedBox(height: 24),
          Text(
            'Access Denied',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'You don\'t have access to this role',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('=== BUILD METHOD ===');
    print('isLoading: $isLoading');
    print('hasAccess: $hasAccess');
    print('accessChecked: $accessChecked');
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Manager Subscriptions'),
        actions: hasAccess ? [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _fetchAll();
            },
          ),
        ] : null,
        bottom: hasAccess ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Companies'),
            Tab(text: 'Service Providers'),
            Tab(text: 'Wholesalers'),
          ],
        ) : null,
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : !hasAccess && accessChecked
          ? _buildAccessDeniedView()
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
