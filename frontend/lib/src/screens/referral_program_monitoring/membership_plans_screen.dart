import 'package:flutter/material.dart';
import 'package:admin_dashboard/src/components/add_plan_popup.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription.dart';
import '../../utils/api_response.dart';
import '../../screens/homepage/homepage.dart';
import '../../components/header.dart';
import '../../components/sidebar.dart';

class MembershipPlansScreen extends StatefulWidget {
  const MembershipPlansScreen({Key? key}) : super(key: key);

  @override
  _MembershipPlansScreenState createState() => _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends State<MembershipPlansScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final SubscriptionApiService _subscriptionService = SubscriptionApiService();
  
  final String _logoPath = 'assets/logo/logo.png';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<SubscriptionPlan> _companyPlans = [];
  List<SubscriptionPlan> _workerPlans = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Refresh data when switching tabs
        _loadPlans();
      }
    });
    _loadPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    print('Loading subscription plans...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _subscriptionService.getAllSubscriptionPlans();
      print('Plans loaded. Status: ${response.status}');
      if (response.status == Status.completed) {
        setState(() {
          _companyPlans = response.data!
              .where((plan) => plan.type == 'company')
              .toList();
          _workerPlans = response.data!
              .where((plan) => plan.type == 'serviceProvider')
              .toList();
        });
        print('Sorted plans - Company: ${_companyPlans.length}, Workers: ${_workerPlans.length}');
      } else {
        print('Error loading plans: ${response.message}');
        setState(() {
          _error = response.message;
        });
      }
    } catch (e) {
      print('Exception while loading plans: $e');
      setState(() {
        _error = 'Failed to load plans: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  Future<void> _showAddPlanPopup() async {
    final type = _tabController.index == 0 ? 'company' : 'serviceProvider';
    print('Opening add plan popup for type: $type');
    
    // Add logging for plan data
    final newPlan = await showDialog<CreateSubscriptionPlanRequest>(
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
            child: AddPlanPopupForm(type: type),
          ),
        );
      },
    );

    if (newPlan != null) {
      try {
        setState(() => _isLoading = true);
        
        print('Creating new plan with data:');
        print('Title: ${newPlan.title}');
        print('Type: ${newPlan.type}');
        print('Price: ${newPlan.price}');
        print('Duration: ${newPlan.duration}');
        print('Benefits: ${newPlan.benefits.map((b) => b.title).toList()}'); // Print benefit titles
        
        final response = await _subscriptionService.createSubscriptionPlan(newPlan);
        
        print('Raw API Response Details:');
        print('Status: ${response.status}');
        print('Message: ${response.message}');
        print('Raw Data: ${response.data}');

        if (response.status == Status.completed) {
          await _loadPlans();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Plan created successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          print('Error creating plan:');
          print('Status: ${response.status}');
          print('Message: ${response.message}');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create plan: ${response.message}'),
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
              content: Text('Error creating plan: ${e.toString()}'),
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
      print('Add plan popup cancelled');
    }
  }



  Future<void> _handleDeletePlan(SubscriptionPlan plan) async {
    print('Attempting to delete plan: ${plan.title} (ID: ${plan.id})');
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete "${plan.title}"?'),
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

    if (confirmed == true && plan.id != null) {
      print('Delete confirmed for plan ID: ${plan.id}');
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _subscriptionService.deleteSubscriptionPlan(plan.id!);
        print('Delete plan response status: ${response.status}');
        if (response.status == Status.completed) {
          print('Plan deleted successfully');
          await _loadPlans();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Plan deleted successfully')),
            );
          }
        } else {
          print('Failed to delete plan: ${response.message}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete plan: ${response.message}')),
            );
          }
        }
      } catch (e) {
        print('Exception while deleting plan: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting plan: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('Delete cancelled or invalid plan ID');
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
                          'Membership Plans',
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
                        Tab(text: 'Company'),
                        Tab(text: 'Workers'),
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
                                      onPressed: _loadPlans,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildPlansList(_companyPlans, 'company'),
                                  _buildPlansList(_workerPlans, 'serviceProvider'),
                                ],
                              ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _showAddPlanPopup,
              icon: const Icon(Icons.add),
              label: Text(
                _tabController.index == 0 
                    ? 'Add Company Plan' 
                    : 'Add Worker Plan',
              ),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlansList(List<SubscriptionPlan> plans, String type) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plans.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.subscriptions_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    type == 'company'
                        ? 'No company plans available'
                        : 'No worker plans available',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (type == 'company')
                    ElevatedButton.icon(
                      onPressed: _showAddPlanPopup,
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Plan'),
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
                    ...plans.map((plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: MembershipPlanCard(
                            plan: plan,
                            onEdit: () {
                              // TODO: Implement edit functionality
                            },
                            onDelete: () => _handleDeletePlan(plan),
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


}

class MembershipPlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MembershipPlanCard({
    Key? key,
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              'Duration: ${plan.durationText}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: plan.benefits.map((benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                benefit.title,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              if (benefit.description.isNotEmpty)
                                Text(
                                  benefit.description,
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.formattedPrice,
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  plan.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: plan.isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
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