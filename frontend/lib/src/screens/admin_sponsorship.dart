import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:admin_dashboard/src/components/add_sponsorship_popup.dart';
import 'package:admin_dashboard/src/components/sponsorship_card.dart';
import 'package:admin_dashboard/src/components/sponsorship_subscription_request_card.dart';
import 'package:admin_dashboard/src/services/sponsorship_service.dart';
import 'package:admin_dashboard/src/services/sponsorship_subscription_service.dart';
import 'package:admin_dashboard/src/models/sponsorship.dart';
import 'package:admin_dashboard/src/utils/api_response.dart';
import 'package:admin_dashboard/src/screens/homepage/homepage.dart';
import 'package:admin_dashboard/src/components/header.dart';
import 'package:admin_dashboard/src/components/sidebar.dart';

class AdminSponsorshipScreen extends StatefulWidget {
  const AdminSponsorshipScreen({Key? key}) : super(key: key);

  @override
  _AdminSponsorshipScreenState createState() => _AdminSponsorshipScreenState();
}

class _AdminSponsorshipScreenState extends State<AdminSponsorshipScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final SponsorshipApiService _sponsorshipService = SponsorshipApiService();
  final SponsorshipSubscriptionApiService _subscriptionService = SponsorshipSubscriptionApiService();
  
  final String _logoPath = 'assets/logo/logo.png';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<Sponsorship> _serviceProviderSponsorships = [];
  List<Sponsorship> _companyWholesalerSponsorships = [];
  List<SponsorshipSubscriptionRequest> _pendingRequests = [];
  List<SponsorshipSubscriptionRequest> _activeSubscriptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Refresh data when switching tabs
        _loadDataForCurrentTab();
      }
    });
    _loadDataForCurrentTab();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDataForCurrentTab() async {
    switch (_tabController.index) {
      case 0:
      case 1:
        await _loadSponsorships();
        break;
      case 2:
        await _loadPendingRequests();
        break;
      case 3:
        await _loadActiveSubscriptions();
        break;
    }
  }

  Future<void> _loadSponsorships() async {
    print('Loading sponsorships...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _sponsorshipService.getSponsorships();
      print('Sponsorships loaded. Status: ${response.status}');
      if (response.status == Status.completed) {
        final allSponsorships = response.data?.sponsorships ?? [];
        
        setState(() {
          // Filter sponsorships by type field instead of title prefix
          _serviceProviderSponsorships = allSponsorships
              .where((sponsorship) => sponsorship.type == 'serviceProvider')
              .toList();
          
          _companyWholesalerSponsorships = allSponsorships
              .where((sponsorship) => sponsorship.type == 'companyWholesaler')
              .toList();
        });
        
        // Debug: Print all sponsorships with their types
        print('=== DEBUG: All Sponsorships ===');
        for (var sponsorship in allSponsorships) {
          print('Title: "${sponsorship.title}" | Type: "${sponsorship.type}" | ID: ${sponsorship.id}');
        }
        print('=== END DEBUG ===');
        
        // Debug: Print filtered results
        print('=== DEBUG: Service Provider Sponsorships ===');
        for (var sponsorship in _serviceProviderSponsorships) {
          print('Service Provider: "${sponsorship.title}" | Type: "${sponsorship.type}"');
        }
        print('=== DEBUG: Company/Wholesaler Sponsorships ===');
        for (var sponsorship in _companyWholesalerSponsorships) {
          print('Company/Wholesaler: "${sponsorship.title}" | Type: "${sponsorship.type}"');
        }
        
        print('Filtered sponsorships - Service Providers: ${_serviceProviderSponsorships.length}, Company/Wholesaler: ${_companyWholesalerSponsorships.length}');
      } else {
        print('Error loading sponsorships: ${response.message}');
        setState(() {
          _error = response.message;
        });
      }
    } catch (e) {
      print('Exception while loading sponsorships: $e');
      setState(() {
        _error = 'Failed to load sponsorships: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPendingRequests() async {
    print('Loading pending requests...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _subscriptionService.getPendingSponsorshipSubscriptionRequests();
      print('Pending requests loaded. Status: ${response.status}');
      if (response.status == Status.completed) {
        setState(() {
          _pendingRequests = response.data?.requests ?? [];
        });
        print('Pending requests loaded: ${_pendingRequests.length}');
        
        // Debug: Print the first request to see its structure
        if (_pendingRequests.isNotEmpty) {
          print('First request structure:');
          print('ID: ${_pendingRequests.first.id}');
          print('Entity Type: ${_pendingRequests.first.entityType}');
          print('Entity ID: ${_pendingRequests.first.entityId}');
          print('Sponsorship ID: ${_pendingRequests.first.sponsorshipId}');
          print('Status: ${_pendingRequests.first.status}');
          print('Requested At: ${_pendingRequests.first.requestedAt}');
          print('Entity: ${_pendingRequests.first.entity}');
        }
      } else {
        print('Error loading pending requests: ${response.message}');
        setState(() {
          _error = response.message;
        });
      }
    } catch (e) {
      print('Exception while loading pending requests: $e');
      setState(() {
        _error = 'Failed to load pending requests: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActiveSubscriptions() async {
    print('Loading active subscriptions...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _subscriptionService.getActiveSponsorshipSubscriptions();
      print('Active subscriptions loaded. Status: ${response.status}');
      if (response.status == Status.completed) {
        setState(() {
          _activeSubscriptions = response.data?.requests ?? [];
        });
        print('Active subscriptions loaded: ${_activeSubscriptions.length}');
      } else {
        print('Error loading active subscriptions: ${response.message}');
        setState(() {
          _error = response.message;
        });
      }
    } catch (e) {
      print('Exception while loading active subscriptions: $e');
      setState(() {
        _error = 'Failed to load active subscriptions: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddSponsorshipPopup() async {
    final type = _tabController.index == 0 ? 'serviceProvider' : 'companyWholesaler';
    print('Opening add sponsorship popup for type: $type');
    
    final newSponsorship = await showDialog<SponsorshipRequest>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: AddSponsorshipPopupForm(type: type),
          ),
        );
      },
    );

    if (newSponsorship != null) {
      try {
        setState(() => _isLoading = true);
        
        print('Creating new sponsorship with data:');
        print('Type: ${newSponsorship.type}');
        print('Title: ${newSponsorship.title}');
        print('Price: ${newSponsorship.price}');
        print('Duration: ${newSponsorship.duration} days');
        print('Discount: ${newSponsorship.discount ?? 'No discount'}');
        print('Start Date: ${newSponsorship.startDate}');
        print('End Date: ${newSponsorship.endDate}');
        print('Start Date ISO: ${newSponsorship.startDate.toIso8601String()}');
        print('End Date ISO: ${newSponsorship.endDate.toIso8601String()}');
        
        // Debug: Print the actual JSON being sent
        final requestJson = newSponsorship.toJson();
        print('Request JSON being sent:');
        print(requestJson);
        print('Request JSON stringified:');
        print(requestJson.toString());
        print('Request JSON encoded:');
        print(jsonEncode(requestJson));
        
        // Debug: Check if dates are valid
        print('Start Date is valid: ${newSponsorship.startDate.isUtc}');
        print('End Date is valid: ${newSponsorship.endDate.isUtc}');
        print('Start Date timezone: ${newSponsorship.startDate.timeZoneName}');
        print('End Date timezone: ${newSponsorship.endDate.timeZoneName}');
        
        final response = type == 'serviceProvider' 
            ? await _sponsorshipService.createServiceProviderSponsorship(newSponsorship)
            : await _sponsorshipService.createCompanyWholesalerSponsorship(newSponsorship);
        
        print('Raw API Response Details:');
        print('Status: ${response.status}');
        print('Message: ${response.message}');
        print('Raw Data: ${response.data}');

        if (response.status == Status.completed) {
          await _loadSponsorships();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sponsorship created successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          print('Error creating sponsorship:');
          print('Status: ${response.status}');
          print('Message: ${response.message}');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create sponsorship: ${response.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        print('Exception details:');
        print('Error: $e');
        print('Stack trace:\n$stackTrace');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating sponsorship: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      print('Add sponsorship popup cancelled');
    }
  }

  Future<void> _handleDeleteSponsorship(Sponsorship sponsorship) async {
    print('Attempting to delete sponsorship: ${sponsorship.title} (ID: ${sponsorship.id})');
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sponsorship'),
        content: Text('Are you sure you want to delete "${sponsorship.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && sponsorship.id != null) {
      print('Delete confirmed for sponsorship ID: ${sponsorship.id}');
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _sponsorshipService.deleteSponsorship(sponsorship.id!);
        print('Delete sponsorship response status: ${response.status}');
        if (response.status == Status.completed) {
          print('Sponsorship deleted successfully');
          await _loadSponsorships();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sponsorship deleted successfully')),
            );
          }
        } else {
          print('Failed to delete sponsorship: ${response.message}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete sponsorship: ${response.message}')),
            );
          }
        }
      } catch (e) {
        print('Exception while deleting sponsorship: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting sponsorship: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('Delete cancelled or invalid sponsorship ID');
    }
  }

  Future<void> _handleApproveRequest(SponsorshipSubscriptionRequest request) async {
    print('Approving request: ${request.id}');
    
    // Check if request ID is null
    if (request.id == null || request.id!.isEmpty) {
      print('Error: Request ID is null or empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Request ID is missing. Cannot approve request.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final approvalRequest = SponsorshipSubscriptionApprovalRequest(
        status: 'approved',
      );

      final response = await _subscriptionService.processSponsorshipSubscriptionRequest(
        request.id!,
        approvalRequest,
      );

      if (response.status == Status.completed) {
        print('Request approved successfully');
        await _loadPendingRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request approved successfully')),
          );
        }
      } else {
        print('Failed to approve request: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to approve request: ${response.message}')),
          );
        }
      }
    } catch (e) {
      print('Exception while approving request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving request: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRejectRequest(SponsorshipSubscriptionRequest request) async {
    print('Rejecting request: ${request.id}');
    
    // Check if request ID is null
    if (request.id == null || request.id!.isEmpty) {
      print('Error: Request ID is null or empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Request ID is missing. Cannot reject request.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final approvalRequest = SponsorshipSubscriptionApprovalRequest(
        status: 'rejected',
      );

      final response = await _subscriptionService.processSponsorshipSubscriptionRequest(
        request.id!,
        approvalRequest,
      );

      if (response.status == Status.completed) {
        print('Request rejected successfully');
        await _loadPendingRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request rejected successfully')),
          );
        }
      } else {
        print('Failed to reject request: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reject request: ${response.message}')),
          );
        }
      }
    } catch (e) {
      print('Exception while rejecting request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting request: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
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
                    onMenuPressed: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
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
                        const Text(
                          'Sponsorship Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1C4B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[600],
                      indicator: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      tabs: const [
                        Tab(text: 'Service Providers'),
                        Tab(text: 'Company & Wholesaler'),
                        Tab(text: 'Requests'),
                        Tab(text: 'Active Subscriptions'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Content Area
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_error!, style: const TextStyle(color: Colors.red)),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadSponsorships,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildSponsorshipsList(_serviceProviderSponsorships, 'Service Provider'),
                                  _buildSponsorshipsList(_companyWholesalerSponsorships, 'Company & Wholesaler'),
                                  _buildRequestsList(),
                                  _buildActiveSubscriptionsList(),
                                ],
                              ),
                  ),
                ],
              ),
            ),
            floatingActionButton: _tabController.index < 2
                ? FloatingActionButton.extended(
                    onPressed: _showAddSponsorshipPopup,
                    icon: const Icon(Icons.add),
                    label: Text(
                      _tabController.index == 0 
                          ? 'Add Service Provider Sponsorship' 
                          : 'Add Company & Wholesaler Sponsorship',
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildSponsorshipsList(List<Sponsorship> sponsorships, String type) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sponsorships.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.card_giftcard,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No $type sponsorships available',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddSponsorshipPopup,
                    icon: const Icon(Icons.add),
                    label: Text('Create First $type Sponsorship'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...sponsorships.map((sponsorship) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: SponsorshipCard(
                            sponsorship: sponsorship,
                            onEdit: () {
                              // TODO: Implement edit functionality
                            },
                            onDelete: () => _handleDeleteSponsorship(sponsorship),
                          ),
                        )),
                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pending Requests (${_pendingRequests.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1C4B),
            ),
          ),
          const SizedBox(height: 16),
          if (_pendingRequests.isEmpty)
            const Center(
              child: Text(
                'No pending requests found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _pendingRequests.length,
                itemBuilder: (context, index) {
                  return SponsorshipSubscriptionRequestCard(
                    request: _pendingRequests[index],
                    onApprove: () => _handleApproveRequest(_pendingRequests[index]),
                    onReject: () => _handleRejectRequest(_pendingRequests[index]),
                    isLoading: _isLoading,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveSubscriptionsList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Active Subscriptions (${_activeSubscriptions.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1C4B),
            ),
          ),
          const SizedBox(height: 16),
          if (_activeSubscriptions.isEmpty)
            const Center(
              child: Text(
                'No active subscriptions found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _activeSubscriptions.length,
                itemBuilder: (context, index) {
                  return SponsorshipSubscriptionRequestCard(
                    request: _activeSubscriptions[index],
                    onApprove: null, // No actions for active subscriptions
                    onReject: null,
                    isLoading: false,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
