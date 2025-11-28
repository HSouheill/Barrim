import 'package:admin_dashboard/src/screens/homepage/homepage.dart';
import 'package:flutter/material.dart';
import 'package:admin_dashboard/src/services/business_management_service.dart';
import 'package:admin_dashboard/src/services/subscription_service.dart';
import 'package:admin_dashboard/src/models/admin_model.dart';
import 'package:admin_dashboard/src/models/company_model.dart';
import 'package:admin_dashboard/src/models/subscription.dart';
import 'package:admin_dashboard/src/utils/api_response.dart';
import 'package:admin_dashboard/src/components/header.dart';
import 'package:admin_dashboard/src/components/sidebar.dart';

enum RequestType { branch, companySubscription }

class RequireApprovalPage extends StatefulWidget {
  const RequireApprovalPage({Key? key}) : super(key: key);

  @override
  State<RequireApprovalPage> createState() => _RequireApprovalPageState();
}

class _RequireApprovalPageState extends State<RequireApprovalPage> {
  List<dynamic> _requests = [];
  List<dynamic> _filteredRequests = [];
  bool _isLoading = true;
  String _search = '';
  Set<String> _selected = {};
  bool _selectAll = false;
  
  // Header and sidebar properties
  final String _logoPath = 'assets/logo/logo.png';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openEndDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    
    try {
      print('=== FETCHING REQUESTS START ===');
      
      // Fetch branch requests
      print('Fetching branch requests...');
      final branchResponse = await BusinessManagementService.getPendingBranchRequests();
      final branchRequests = branchResponse['data']?['requests'] ?? [];
      print('Branch requests fetched: ${branchRequests.length}');
      
      // Fetch all types of subscription requests
      final subscriptionApi = SubscriptionApiService();
      
      // Fetch company subscription requests (wholesaler type from the API)
      print('Fetching wholesaler subscription requests...');
      final wholesalerResponse = await subscriptionApi.getEnrichedPendingWholesalerSubscriptionRequests();
      final wholesalerRequests = wholesalerResponse.data ?? [];
      print('Wholesaler requests fetched: ${wholesalerRequests.length}');
      print('Wholesaler response status: ${wholesalerResponse.status}');
      print('Wholesaler response message: ${wholesalerResponse.message}');
      
      // Fetch service provider subscription requests
      print('Fetching service provider subscription requests...');
      final serviceProviderResponse = await subscriptionApi.getPendingServiceProviderSubscriptionRequests();
      final serviceProviderRequests = serviceProviderResponse.data ?? [];
      print('Service provider requests fetched: ${serviceProviderRequests.length}');
      print('Service provider response status: ${serviceProviderResponse.status}');
      print('Service provider response message: ${serviceProviderResponse.message}');
      

      
      // Fetch enriched branch subscription requests (new endpoint with detailed info)
      print('Fetching enriched branch subscription requests...');
      final enrichedBranchSubscriptionResponse = await subscriptionApi.getEnrichedPendingBranchSubscriptionRequests();
      final enrichedBranchSubscriptionRequests = enrichedBranchSubscriptionResponse.data ?? [];
      print('Enriched branch subscription requests fetched: ${enrichedBranchSubscriptionRequests.length}');
      print('Enriched branch subscription response status: ${enrichedBranchSubscriptionResponse.status}');
      print('Enriched branch subscription response message: ${enrichedBranchSubscriptionResponse.message}');
      
      // Use enriched branch subscription requests directly
      final allBranchSubscriptionRequests = enrichedBranchSubscriptionRequests;
      print('Total branch subscription requests: ${allBranchSubscriptionRequests.length}');
      
      // Fetch wholesaler branch subscription requests
      print('Fetching wholesaler branch subscription requests...');
      final wholesalerBranchSubscriptionResponse = await subscriptionApi.getPendingWholesalerBranchSubscriptionRequests();
      final wholesalerBranchSubscriptionRequests = wholesalerBranchSubscriptionResponse.data ?? [];
      print('Wholesaler branch subscription requests fetched: ${wholesalerBranchSubscriptionRequests.length}');
      print('Wholesaler branch subscription response status: ${wholesalerBranchSubscriptionResponse.status}');
      print('Wholesaler branch subscription response message: ${wholesalerBranchSubscriptionResponse.message}');
      
      // Combine all requests with proper null checks
      final allRequests = <Map<String, dynamic>>[];
      
      print('=== PROCESSING REQUESTS ===');
      
      // Process branch requests
      print('Processing branch requests...');
      for (var req in branchRequests) {
        if (req != null) {
          print('Adding branch request: ${req['_id'] ?? req['id']} - ${req['branchData']?['name'] ?? 'Unknown'}');
          allRequests.add({
            'type': 'branch',
            'data': req,
          });
        }
      }
      
      // Process wholesaler requests
      print('Processing wholesaler requests...');
      for (var req in wholesalerRequests) {
        if (req != null) {
          print('Adding enriched wholesaler request: ${req.id} - ${req.businessName}');
          allRequests.add({
            'type': 'wholesaler',
            'data': req,
          });
        }
      }
      
      // Process service provider requests
      print('Processing service provider requests...');
      for (var req in serviceProviderRequests) {
        if (req != null) {
          print('Adding service provider request: ${req.id} - ${req.businessName ?? 'Unknown'}');
          allRequests.add({
            'type': 'serviceProvider',
            'data': req,
          });
        }
      }
      

      
      // Process branch subscription requests
      print('Processing branch subscription requests...');
      for (var req in allBranchSubscriptionRequests) {
        if (req != null) {
          print('Adding branch subscription request: ${req.id} - Company: ${req.businessName} - Branch: ${req.branchName}');
          allRequests.add({
            'type': 'branchSubscription',
            'data': req,
          });
        }
      }
      
      // Process wholesaler branch subscription requests
      print('Processing wholesaler branch subscription requests...');
      for (var req in wholesalerBranchSubscriptionRequests) {
        if (req != null) {
          print('Adding wholesaler branch subscription request: ${req.id} - Business: ${req.businessName} - Branch: ${req.branchName}');
          allRequests.add({
            'type': 'wholesalerBranchSubscription',
            'data': req,
          });
        }
      }
      
      print('=== FINAL SUMMARY ===');
      print('Total requests loaded: ${allRequests.length}');
      print('Branch requests: ${allRequests.where((req) => req['type'] == 'branch').length}');
      print('Wholesaler requests: ${allRequests.where((req) => req['type'] == 'wholesaler').length}');
      print('Service provider requests: ${allRequests.where((req) => req['type'] == 'serviceProvider').length}');
      print('Branch subscription requests: ${allRequests.where((req) => req['type'] == 'branchSubscription').length}');
      print('Wholesaler branch subscription requests: ${allRequests.where((req) => req['type'] == 'wholesalerBranchSubscription').length}');
      print('=== FETCHING REQUESTS END ===');
      
      setState(() {
        _requests = allRequests;
        _filteredRequests = allRequests;
        _isLoading = false;
      });
    } catch (e) {
      print('=== ERROR FETCHING REQUESTS ===');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _requests = [];
        _filteredRequests = [];
        _isLoading = false;
      });
    }
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _filteredRequests = _requests.where((req) {
        final reqData = req['data'];
        if (req['type'] == 'branch') {
          // Handle JSON map for branch requests
          if (reqData is Map<String, dynamic>) {
            final branchData = reqData['branchData'];
            if (branchData is Map<String, dynamic>) {
              final name = branchData['name']?.toString().toLowerCase() ?? '';
              return name.contains(_search.toLowerCase());
            } else if (branchData is String) {
              return branchData.toLowerCase().contains(_search.toLowerCase());
            }
          }
          return false;
        } else if (req['type'] == 'branchSubscription') {
          // Handle enriched branch subscription requests
          if (reqData is EnrichedBranchSubscriptionRequest) {
            final businessName = reqData.businessName.toLowerCase();
            final branchName = reqData.branchName.toLowerCase();
            final planTitle = reqData.planTitle.toLowerCase();
            final searchTerm = _search.toLowerCase();
            return businessName.contains(searchTerm) || 
                   branchName.contains(searchTerm) || 
                   planTitle.contains(searchTerm);
          } else {
            return false;
          }
        } else if (req['type'] == 'wholesalerBranchSubscription') {
          // Handle wholesaler branch subscription requests
          if (reqData is EnrichedWholesalerBranchSubscriptionRequest) {
            final businessName = reqData.businessName.toLowerCase();
            final branchName = reqData.branchName.toLowerCase();
            final planTitle = reqData.planTitle.toLowerCase();
            final searchTerm = _search.toLowerCase();
            return businessName.contains(searchTerm) || 
                   branchName.contains(searchTerm) || 
                   planTitle.contains(searchTerm);
          } else if (reqData is Map<String, dynamic>) {
            // Handle raw JSON data
            try {
              final businessName = reqData['wholesaler']?['businessName']?.toString().toLowerCase() ?? '';
              final branchName = reqData['branch']?['name']?.toString().toLowerCase() ?? '';
              final planTitle = reqData['plan']?['title']?.toString().toLowerCase() ?? '';
              final searchTerm = _search.toLowerCase();
              return businessName.contains(searchTerm) || 
                     branchName.contains(searchTerm) || 
                     planTitle.contains(searchTerm);
            } catch (e) {
              return false;
            }
          } else {
            return false;
          }
        } else {
          // SubscriptionRequest model for wholesaler and service provider
          if (reqData is SubscriptionRequest) {
            final businessName = reqData.businessName?.toLowerCase() ?? '';
            final plan = reqData.plan?.title?.toLowerCase() ?? '';
            return businessName.contains(_search.toLowerCase()) || plan.contains(_search.toLowerCase());
          } else if (reqData is EnrichedWholesalerSubscriptionRequest) {
            // Handle enriched wholesaler subscription requests
            final businessName = reqData.businessName.toLowerCase();
            final planTitle = reqData.planTitle.toLowerCase();
            final searchTerm = _search.toLowerCase();
            return businessName.contains(searchTerm) || planTitle.contains(searchTerm);
          } else {
            return false;
          }
        }
      }).toList();
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        final selectedIds = <String>{};
        for (var req in _filteredRequests) {
          if (req != null) {
            final reqData = req['data'];
            if (req['type'] == 'branch') {
              // Handle JSON map for branch requests
              if (reqData is Map<String, dynamic>) {
                final id = reqData['_id']?.toString() ?? reqData['id']?.toString() ?? '';
                if (id.isNotEmpty) {
                  selectedIds.add(id);
                }
              }
            } else if (req['type'] == 'branchSubscription') {
              // Handle enriched branch subscription requests
              if (reqData is EnrichedBranchSubscriptionRequest) {
                final id = reqData.id ?? '';
                if (id.isNotEmpty) {
                  selectedIds.add(id);
                }
              }
            } else if (req['type'] == 'wholesaler') {
              // Handle enriched wholesaler subscription requests
              if (reqData is EnrichedWholesalerSubscriptionRequest) {
                final id = reqData.id ?? '';
                if (id.isNotEmpty) {
                  selectedIds.add(id);
                }
              } else if (reqData is SubscriptionRequest) {
                final id = reqData.id ?? '';
                if (id.isNotEmpty) {
                  selectedIds.add(id);
                }
              }
            } else if (req['type'] == 'wholesalerBranchSubscription') {
              if (reqData is EnrichedWholesalerBranchSubscriptionRequest) {
                final id = reqData.id ?? '';
                if (id.isNotEmpty) {
                  selectedIds.add(id);
                }
              } else if (reqData is Map<String, dynamic>) {
                // Handle raw JSON data
                try {
                  final id = reqData['request']?['id']?.toString() ?? 
                            reqData['request']?['_id']?.toString() ?? '';
                  if (id.isNotEmpty) {
                    selectedIds.add(id);
                  }
                } catch (e) {
                  print('Error getting ID from wholesaler branch subscription JSON: $e');
                }
              }
            } else {
              final id = reqData?.id ?? '';
              if (id.isNotEmpty) {
                selectedIds.add(id);
              }
            }
          }
        }
        _selected = selectedIds;
      } else {
        _selected.clear();
      }
    });
  }

  void _toggleSelect(String id, bool? value) {
    setState(() {
      if (value == true) {
        _selected.add(id);
      } else {
        _selected.remove(id);
      }
      _selectAll = _selected.length == _filteredRequests.length;
    });
  }

  Future<void> _processRequest(String id, String status) async {
    print('=== PROCESSING REQUEST START ===');
    print('Request ID: $id');
    print('Status: $status');
    
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                status == 'approved' ? Icons.check_circle : Icons.cancel,
                color: status == 'approved' ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                status == 'approved' ? 'Approve Request' : 'Reject Request',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to ${status == 'approved' ? 'approve' : 'reject'} this request? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'approved' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(status == 'approved' ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      print('User cancelled the request processing');
      return; // User cancelled
    }

    setState(() => _isLoading = true);
    
    try {
      print('Finding request with ID: $id');
      
      // Find the request by ID
      Map<String, dynamic>? req;
      try {
        req = _requests.firstWhere(
          (req) {
            final reqData = req['data'];
            String reqId = '';
            if (req['type'] == 'branch') {
              // Handle JSON map for branch requests
              if (reqData is Map<String, dynamic>) {
                reqId = reqData['_id']?.toString() ?? reqData['id']?.toString() ?? '';
              }
            } else if (req['type'] == 'branchSubscription') {
              // Handle enriched branch subscription requests
              if (reqData is EnrichedBranchSubscriptionRequest) {
                reqId = reqData.id ?? '';
              }
            } else if (req['type'] == 'wholesaler') {
              // Handle enriched wholesaler subscription requests
              if (reqData is EnrichedWholesalerSubscriptionRequest) {
                reqId = reqData.id ?? '';
              } else if (reqData is SubscriptionRequest) {
                reqId = reqData.id ?? '';
              }
            } else if (req['type'] == 'wholesalerBranchSubscription') {
              if (reqData is EnrichedWholesalerBranchSubscriptionRequest) {
                reqId = reqData.id ?? '';
              } else if (reqData is Map<String, dynamic>) {
                // Handle raw JSON data
                try {
                  reqId = reqData['request']?['id']?.toString() ?? 
                          reqData['request']?['_id']?.toString() ?? '';
                } catch (e) {
                  print('Error getting ID from wholesaler branch subscription JSON: $e');
                }
              }
            } else {
              reqId = reqData?.id ?? '';
            }
            return reqId == id;
          },
        ) as Map<String, dynamic>;
        print('Request found successfully');
        print('Request type: ${req['type']}');
        print('Request data: ${req['data']}');
      } catch (e) {
        print('ERROR: Request not found with ID: $id');
        print('Error details: $e');
        print('Available request IDs: ${_requests.map((req) {
          final reqData = req['data'];
          if (req['type'] == 'branch') {
            if (reqData is Map<String, dynamic>) {
              return reqData['_id']?.toString() ?? reqData['id']?.toString() ?? '';
            }
            return 'unknown';
          } else {
            return reqData?.id ?? '';
          }
        }).toList()}');
        setState(() => _isLoading = false);
        return;
      }
      
      if (req == null) {
        print('ERROR: Request is null after finding with ID: $id');
        setState(() => _isLoading = false);
        return;
      }
      
      print('Processing request - Type: ${req['type']}, ID: $id, Status: $status');
      
      final subscriptionApi = SubscriptionApiService();
      bool success = false;
      
      if (req['type'] == 'branch') {
        print('Processing branch request...');
        await BusinessManagementService.processBranchRequest(id: id, status: status);
        success = true;
        print('Branch request processed successfully');
      } else if (req['type'] == 'wholesaler') {
        print('Processing wholesaler subscription request...');
        print('Request ID: $id, Status: $status');
        final response = await subscriptionApi.processWholesalerSubscriptionRequest(
          requestId: id,
          status: status,
        );
        print('Wholesaler API response:');
        print('  Status: ${response.status}');
        print('  Message: ${response.message}');
        print('  Data: ${response.data}');
        success = response.status == Status.completed;
        print('Wholesaler request processing ${success ? 'SUCCESS' : 'FAILED'}');
      } else if (req['type'] == 'serviceProvider') {
        print('Processing service provider subscription request...');
        print('Request ID: $id, Status: $status');
        final response = await subscriptionApi.processServiceProviderSubscriptionRequest(
          requestId: id,
          status: status,
        );
        print('Service provider API response:');
        print('  Status: ${response.status}');
        print('  Message: ${response.message}');
        print('  Data: ${response.data}');
        success = response.status == Status.completed;
        print('Service provider request processing ${success ? 'SUCCESS' : 'FAILED'}');
      } else if (req['type'] == 'branchSubscription') {
        print('Processing branch subscription request...');
        print('Request ID: $id, Status: $status');
        final response = await subscriptionApi.processBranchSubscriptionRequest(
          requestId: id,
          status: status,
        );
        print('Branch subscription API response:');
        print('  Status: ${response.status}');
        print('  Message: ${response.message}');
        print('  Data: ${response.data}');
        success = response.status == Status.completed;
        print('Branch subscription request processing ${success ? 'SUCCESS' : 'FAILED'}');
      } else if (req['type'] == 'wholesalerBranchSubscription') {
        print('Processing wholesaler branch subscription request...');
        print('Request ID: $id, Status: $status');
        final response = await subscriptionApi.processWholesalerBranchSubscriptionRequest(
          requestId: id,
          status: status,
        );
        print('Wholesaler branch subscription API response:');
        print('  Status: ${response.status}');
        print('  Message: ${response.message}');
        print('  Data: ${response.data}');
        success = response.status == Status.completed;
        print('Wholesaler branch subscription request processing ${success ? 'SUCCESS' : 'FAILED'}');
      }
      
      if (success) {
        print('Request processing successful - updating UI');
        
        // Remove the processed request from the lists
        setState(() {
          _requests.removeWhere((req) {
            final reqData = req['data'];
            String reqId = '';
            if (req['type'] == 'branch') {
              // Handle JSON map for branch requests
              if (reqData is Map<String, dynamic>) {
                reqId = reqData['_id']?.toString() ?? reqData['id']?.toString() ?? '';
              }
            } else if (req['type'] == 'branchSubscription') {
              if (reqData is EnrichedBranchSubscriptionRequest) {
                reqId = reqData.id ?? '';
              }
            } else if (req['type'] == 'wholesaler') {
              if (reqData is EnrichedWholesalerSubscriptionRequest) {
                reqId = reqData.id ?? '';
              } else if (reqData is SubscriptionRequest) {
                reqId = reqData.id ?? '';
              }
            } else if (req['type'] == 'wholesalerBranchSubscription') {
              if (reqData is EnrichedWholesalerBranchSubscriptionRequest) {
                reqId = reqData.id ?? '';
              } else if (reqData is Map<String, dynamic>) {
                // Handle raw JSON data
                try {
                  reqId = reqData['request']?['id']?.toString() ?? 
                          reqData['request']?['_id']?.toString() ?? '';
                } catch (e) {
                  print('Error getting ID from wholesaler branch subscription JSON: $e');
                }
              }
            } else {
              reqId = reqData?.id ?? '';
            }
            return reqId == id;
          });
          _filteredRequests.removeWhere((req) {
            final reqData = req['data'];
            String reqId = '';
            if (req['type'] == 'branch') {
              // Handle JSON map for branch requests
              if (reqData is Map<String, dynamic>) {
                reqId = reqData['_id']?.toString() ?? reqData['id']?.toString() ?? '';
              }
            } else if (req['type'] == 'branchSubscription') {
              if (reqData is EnrichedBranchSubscriptionRequest) {
                reqId = reqData.id ?? '';
              }
            } else if (req['type'] == 'wholesaler') {
              if (reqData is EnrichedWholesalerSubscriptionRequest) {
                reqId = reqData.id ?? '';
              } else if (reqData is SubscriptionRequest) {
                reqId = reqData.id ?? '';
              }
            } else if (req['type'] == 'wholesalerBranchSubscription') {
              if (reqData is EnrichedWholesalerBranchSubscriptionRequest) {
                reqId = reqData.id ?? '';
              } else if (reqData is Map<String, dynamic>) {
                // Handle raw JSON data
                try {
                  reqId = reqData['request']?['id']?.toString() ?? 
                          reqData['request']?['_id']?.toString() ?? '';
                } catch (e) {
                  print('Error getting ID from wholesaler branch subscription JSON: $e');
                }
              }
            } else {
              reqId = reqData?.id ?? '';
            }
            return reqId == id;
          });
          _selected.remove(id);
        });
        
        print('Request removed from lists. Remaining requests: ${_requests.length}');
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    status == 'approved' ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Request ${status == 'approved' ? 'approved' : 'rejected'} successfully',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: status == 'approved' ? Colors.green : Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        print('Request processing failed - showing error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to ${status == 'approved' ? 'approve' : 'reject'} request',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('=== ERROR PROCESSING REQUEST ===');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'An error occurred: ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      print('=== PROCESSING REQUEST END ===');
      setState(() => _isLoading = false);
    }
  }

  /// Builds the paginated / grid responsive list of requests
  Widget _buildRequestList(bool isSmallScreen) {
    // Treat screens wider than 900px as wide
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;
    if (isWideScreen) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3.6,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: _filteredRequests.length,
        itemBuilder: (context, index) {
          return _buildListTile(_filteredRequests[index], true);
        },
      );
    }
    // Default to list view for compact screens
    return ListView.builder(
      itemCount: _filteredRequests.length,
      itemBuilder: (context, index) {
        return _buildListTile(_filteredRequests[index], false);
      },
    );
  }

  Widget _buildBadge(String type) {
    Color color;
    String label = type;
    IconData? iconData;
    
    switch (type.toLowerCase()) {
      case 'visa':
        color = Colors.green;
        iconData = Icons.credit_card;
        break;
      case 'omt pay':
        color = Colors.amber;
        iconData = Icons.payment;
        break;
      case 'whish':
        color = Colors.red;
        iconData = Icons.account_balance_wallet;
        break;
      case 'construction & building':
        color = Colors.blue;
        iconData = Icons.build;
        break;
      case 'wholesaler':
        color = Colors.purple;
        iconData = Icons.inventory;
        break;
      case 'service provider':
        color = Colors.orange;
        iconData = Icons.build;
        break;
      case 'retail':
        color = Colors.teal;
        iconData = Icons.shopping_cart;
        break;
      case 'food & beverage':
        color = Colors.brown;
        iconData = Icons.restaurant;
        break;
      case 'healthcare':
        color = Colors.pink;
        iconData = Icons.local_hospital;
        break;
      case 'technology':
        color = Colors.indigo;
        iconData = Icons.computer;
        break;
      default:
        color = Colors.grey;
        iconData = Icons.category;
        label = type.length > 15 ? '${type.substring(0, 15)}...' : type;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconData != null) ...[
            Icon(iconData, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label, 
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(dynamic req, bool isWideScreen) {
    final reqData = req['data'];
    String id = '';
    
    if (req['type'] == 'branch') {
      if (reqData is Map<String, dynamic>) {
        id = reqData['_id']?.toString() ?? reqData['id']?.toString() ?? '';
      }
    } else if (req['type'] == 'wholesalerBranchSubscription') {
      if (reqData is EnrichedWholesalerBranchSubscriptionRequest) {
        id = reqData.id ?? '';
      } else if (reqData is Map<String, dynamic>) {
        // Handle raw JSON data
        try {
          id = reqData['request']?['id']?.toString() ?? 
               reqData['request']?['_id']?.toString() ?? '';
        } catch (e) {
          print('Error getting ID from wholesaler branch subscription JSON: $e');
          id = '';
        }
      }
    } else if (req['type'] == 'branchSubscription') {
      if (reqData is EnrichedBranchSubscriptionRequest) {
        id = reqData.id ?? '';
      } else if (reqData is Map<String, dynamic>) {
        try {
          id = reqData['request']?['id']?.toString() ?? 
               reqData['request']?['_id']?.toString() ?? '';
        } catch (e) {
          print('Error getting ID from branch subscription JSON: $e');
          id = '';
        }
      }
    } else if (req['type'] == 'wholesaler') {
      if (reqData is EnrichedWholesalerSubscriptionRequest) {
        id = reqData.id ?? '';
      } else if (reqData is SubscriptionRequest) {
        id = reqData.id ?? '';
      } else if (reqData is Map<String, dynamic>) {
        try {
          id = reqData['id']?.toString() ?? reqData['_id']?.toString() ?? '';
        } catch (e) {
          print('Error getting ID from wholesaler JSON: $e');
          id = '';
        }
      }
    } else if (req['type'] == 'serviceProvider') {
      if (reqData is SubscriptionRequest) {
        id = reqData.id ?? '';
      } else if (reqData is Map<String, dynamic>) {
        try {
          id = reqData['id']?.toString() ?? reqData['_id']?.toString() ?? '';
        } catch (e) {
          print('Error getting ID from service provider JSON: $e');
          id = '';
        }
      }
    } else {
      // Fallback for other types
      if (reqData is Map<String, dynamic>) {
        id = reqData['id']?.toString() ?? reqData['_id']?.toString() ?? '';
      } else {
        id = reqData?.id ?? '';
      }
    }

    if (req['type'] == 'branch') {
      if (reqData is! Map<String, dynamic>) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text('Invalid branch request data type: ${reqData.runtimeType}'),
            subtitle: Text('Data: $reqData'),
          ),
        );
      }
      
      final branchData = reqData['branchData'];
      Map<String, dynamic> branch = {};
      if (branchData is Map<String, dynamic>) {
        branch = branchData;
      }
      
      final name = branch['name']?.toString() ?? 'Unknown';
      final amount = branch['costPerCustomer'] ?? 0;
      final paymentType = branch['category']?.toString() ?? 'Visa';
      final address = branch['address']?.toString() ?? '';
      final phone = branch['phone']?.toString() ?? '';
      
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Checkbox(
            value: _selected.contains(id),
            onChanged: (val) => _toggleSelect(id, val),
          ),
          title: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Icon(Icons.store, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (address.isNotEmpty)
                      Text(
                        address,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_money, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        ' ${amount.toString()}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  Flexible(child: _buildBadge(paymentType)),
                ],
              ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        phone,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _processRequest(id, 'rejected'),
                tooltip: 'Reject',
              ),
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _processRequest(id, 'approved'),
                tooltip: 'Approve',
              ),
            ],
          ),
        ),
      );
    } else if (req['type'] == 'branchSubscription') {
      // Handle enriched branch subscription requests
      if (reqData is! EnrichedBranchSubscriptionRequest) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text('Invalid enriched branch subscription request type: ${reqData.runtimeType}'),
            subtitle: Text('Data: $reqData'),
          ),
        );
      }
      
      final EnrichedBranchSubscriptionRequest enrichedReq = reqData as EnrichedBranchSubscriptionRequest;
      final businessName = enrichedReq.businessName;
      final branchName = enrichedReq.branchName;
      final planTitle = enrichedReq.planTitle;
      final amount = enrichedReq.plan.price;
      final duration = enrichedReq.plan.duration;
      final branchLocation = enrichedReq.branch.locationDisplay;
      final branchPhone = enrichedReq.branch.phone;
      final companyPhone = enrichedReq.company.phone;
      final requestedAt = enrichedReq.request.requestedAt;
      
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Checkbox(
            value: _selected.contains(id),
            onChanged: (val) => _toggleSelect(id, val),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.indigo.withOpacity(0.2),
                child: Icon(Icons.store, size: 18, color: Colors.indigo),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branchName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Branch Subscription',
                            style: TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            businessName,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Plan and pricing info
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    planTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.attach_money, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Location and duration
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      branchLocation,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${duration} month${duration > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Contact info and request date
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      branchPhone.isNotEmpty ? branchPhone : companyPhone,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(requestedAt ?? DateTime.now()),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _processRequest(id, 'rejected'),
                tooltip: 'Reject',
              ),
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _processRequest(id, 'approved'),
                tooltip: 'Approve',
              ),
            ],
          ),
        ),
      );
    } else if (req['type'] == 'wholesalerBranchSubscription') {
      // Handle wholesaler branch subscription requests
      String businessName = 'Unknown';
      String branchName = 'Unknown';
      String planTitle = 'Unknown';
      double amount = 0.0;
      int duration = 0;
      String category = 'Unknown';
      String location = '';
      String phone = '';
      DateTime? requestedAt;
      
      if (reqData is EnrichedWholesalerBranchSubscriptionRequest) {
        // Handle properly parsed model
        final enrichedReq = reqData;
        businessName = enrichedReq.businessName;
        branchName = enrichedReq.branchName;
        planTitle = enrichedReq.planTitle;
        amount = enrichedReq.plan.price;
        duration = enrichedReq.plan.duration;
        category = enrichedReq.category;
        location = enrichedReq.location;
        phone = enrichedReq.phone;
        requestedAt = enrichedReq.createdAt;
      } else if (reqData is Map<String, dynamic>) {
        // Handle raw JSON data
        try {
          businessName = reqData['wholesaler']?['businessName']?.toString() ?? 'Unknown';
          branchName = reqData['branch']?['name']?.toString() ?? 'Unknown';
          planTitle = reqData['plan']?['title']?.toString() ?? 'Unknown';
          amount = (reqData['plan']?['price'] ?? 0.0).toDouble();
          duration = reqData['plan']?['duration'] ?? 0;
          category = reqData['wholesaler']?['category']?.toString() ?? 'Unknown';
          location = reqData['branch']?['location']?.toString() ?? '';
          phone = reqData['branch']?['phone']?.toString() ?? '';
          if (reqData['request']?['createdAt'] != null) {
            requestedAt = DateTime.tryParse(reqData['request']['createdAt'].toString());
          }
        } catch (e) {
          print('Error parsing wholesaler branch subscription JSON: $e');
        }
      } else {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text('Invalid wholesaler branch subscription request type: ${reqData.runtimeType}'),
            subtitle: Text('Data: $reqData'),
          ),
        );
      }
      
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Checkbox(
            value: _selected.contains(id),
            onChanged: (val) => _toggleSelect(id, val),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.teal.withOpacity(0.2),
                child: Icon(Icons.storefront, size: 18, color: Colors.teal),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branchName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Wholesaler Branch',
                            style: TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            businessName,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Plan and pricing info
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    planTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.attach_money, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Category and duration
              Row(
                children: [
                  Icon(Icons.category, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${duration} month${duration > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Location and phone
              if (location.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (phone.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        phone,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      requestedAt != null ? _formatDate(requestedAt) : 'N/A',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _processRequest(id, 'rejected'),
                tooltip: 'Reject',
              ),
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _processRequest(id, 'approved'),
                tooltip: 'Approve',
              ),
            ],
          ),
        ),
      );
    }
    
    // Handle other subscription requests (wholesaler, service provider)
    if (reqData is! SubscriptionRequest && reqData is! EnrichedWholesalerSubscriptionRequest) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          title: Text('Invalid request type: ${reqData.runtimeType}'),
          subtitle: Text('Data: $reqData'),
        ),
      );
    }
    
    // Handle enriched wholesaler subscription requests
    if (reqData is EnrichedWholesalerSubscriptionRequest) {
      final enrichedReq = reqData as EnrichedWholesalerSubscriptionRequest;
      final businessName = enrichedReq.businessName;
      final planTitle = enrichedReq.planTitle;
      final amount = enrichedReq.planPrice;
      final duration = enrichedReq.planDuration;
      final category = enrichedReq.category;
      final phone = enrichedReq.phone;
      final requestedAt = enrichedReq.requestedAt;
      
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Checkbox(
            value: _selected.contains(id),
            onChanged: (val) => _toggleSelect(id, val),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.purple.withOpacity(0.2),
                child: Icon(Icons.inventory, size: 18, color: Colors.purple),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Wholesaler',
                            style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Plan: $planTitle',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Plan and pricing info
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    planTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.attach_money, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Category and duration
              Row(
                children: [
                  Icon(Icons.category, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${duration} month${duration > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Contact info and request date
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      phone ?? 'N/A',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(requestedAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _processRequest(id, 'rejected'),
                tooltip: 'Reject',
              ),
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _processRequest(id, 'approved'),
                tooltip: 'Approve',
              ),
            ],
          ),
        ),
      );
    }
    
    // Handle standard subscription requests
    final SubscriptionRequest reqModel = reqData as SubscriptionRequest;
    final businessName = reqModel.businessName ?? 'Unknown';
    final plan = reqModel.plan?.title ?? 'Unknown';
    final amount = reqModel.plan?.price ?? 0;
    final paymentType = reqModel.category ?? 'Visa';
    final duration = reqModel.plan?.duration ?? 0;
    final planType = reqModel.plan?.type ?? '';
    final requestedAt = reqModel.requestedAt;
    
    // Determine icon and type label based on request type
    IconData iconData;
    String typeLabel;
    Color typeColor;
    
    switch (req['type']) {
      case 'wholesaler':
        iconData = Icons.inventory;
        typeLabel = 'Wholesaler';
        typeColor = Colors.purple;
        break;
      case 'serviceProvider':
        iconData = Icons.build;
        typeLabel = 'Service Provider';
        typeColor = Colors.orange;
        break;
      case 'company':
        iconData = Icons.business;
        typeLabel = 'Company';
        typeColor = Colors.blue;
        break;
      case 'branchSubscription':
        iconData = Icons.store;
        typeLabel = 'Branch Subscription';
        typeColor = Colors.indigo;
        break;
      case 'wholesalerBranchSubscription':
        iconData = Icons.storefront;
        typeLabel = 'Wholesaler Branch';
        typeColor = Colors.teal;
        break;
      default:
        iconData = Icons.category;
        typeLabel = 'Unknown';
        typeColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Checkbox(
          value: _selected.contains(id),
          onChanged: (val) => _toggleSelect(id, val),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: typeColor.withOpacity(0.2),
              child: Icon(iconData, size: 18, color: typeColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    req['type'] == 'branchSubscription' ? 'Branch Subscription Request' : businessName, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeLabel, 
                          style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Plan: $plan',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Fixed: Use Column with proper constraints instead of Wrap
            if (req['type'] != 'branchSubscription') ...[
              // First row of info
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '${amount.toString()}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${duration} month${duration > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Second row - payment badge
              Row(
                children: [
                  Flexible(child: _buildBadge(paymentType)),
                ],
              ),
            ] else ...[
              // For branch subscription requests, show different info in separate rows
              Row(
                children: [
                  Icon(Icons.store, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Branch ID: ${reqModel.companyId ?? 'N/A'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    amount.toString(),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${duration} month${duration > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            // Third row - date and optional plan type
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Requested: ${_formatDate(requestedAt ?? DateTime.now())}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (planType.isNotEmpty && req['type'] != 'branchSubscription') ...[
                  const SizedBox(width: 8),
                  Icon(Icons.category, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      planType,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _processRequest(id, 'rejected'),
              tooltip: 'Reject',
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _processRequest(id, 'approved'),
              tooltip: 'Approve',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: 390, // Standard mobile width
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.grey.shade100,
            endDrawer: Sidebar(
              onCollapse: () {
                _scaffoldKey.currentState?.closeEndDrawer();
              },
              parentContext: context,
            ),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  HeaderComponent(
                    logoPath: _logoPath,
                    scaffoldKey: _scaffoldKey,
                    onMenuPressed: _openEndDrawer,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const DashboardPage()),
                            );
                          },
                          tooltip: 'Back to Dashboard',
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Subscriptions Requests',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 22, 
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D1C4B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Search Keyword',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.blue[900],
                        hintStyle: const TextStyle(color: Colors.white70),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _selectAll,
                          onChanged: _toggleSelectAll,
                        ),
                        const Text('Select All'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredRequests.isEmpty
                            ? const Center(child: Text('No pending requests'))
                            : _buildRequestList(isSmallScreen),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
