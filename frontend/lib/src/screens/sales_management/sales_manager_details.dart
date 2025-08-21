import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/api_constant.dart';
import '../../components/header.dart';

class SalesManagerDetailsScreen extends StatefulWidget {
  final String salesManagerId;
  final String salesManagerName;

  const SalesManagerDetailsScreen({
    super.key,
    required this.salesManagerId,
    required this.salesManagerName,
  });

  @override
  State<SalesManagerDetailsScreen> createState() => _SalesManagerDetailsScreenState();
}

class _SalesManagerDetailsScreenState extends State<SalesManagerDetailsScreen> {
  final AdminService _adminService = AdminService(baseUrl: ApiConstants.baseUrl);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  String? _error;
  
  // Data from the API
  List<Map<String, dynamic>> _salespersons = [];
  
  // Filtering and sorting state
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'commission', 'companies', 'wholesalers', 'serviceProviders'
  bool _sortAscending = true;

  // Getter for filtered and sorted salespersons
  List<Map<String, dynamic>> get _filteredAndSortedSalespersons {
    List<Map<String, dynamic>> filtered = _salespersons.where((salesperson) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final fullName = (salesperson['fullName'] as String? ?? '').toLowerCase();
        final email = (salesperson['email'] as String? ?? '').toLowerCase();
        final phone = (salesperson['phoneNumber'] as String? ?? '').toLowerCase();
        final searchLower = _searchQuery.toLowerCase();
        
        if (!fullName.contains(searchLower) && 
            !email.contains(searchLower) && 
            !phone.contains(searchLower)) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'name':
          final nameA = (a['fullName'] as String? ?? '').toLowerCase();
          final nameB = (b['fullName'] as String? ?? '').toLowerCase();
          comparison = nameA.compareTo(nameB);
          break;
        case 'commission':
          final commissionA = (a['totalCommission'] ?? 0.0) as double;
          final commissionB = (b['totalCommission'] ?? 0.0) as double;
          comparison = commissionA.compareTo(commissionB);
          break;
        case 'companies':
          final companiesA = a['companyCount'] ?? 0;
          final companiesB = b['companyCount'] ?? 0;
          comparison = companiesA.compareTo(companiesB);
          break;
        case 'wholesalers':
          final wholesalersA = a['wholesalerCount'] ?? 0;
          final wholesalersB = b['wholesalerCount'] ?? 0;
          comparison = wholesalersA.compareTo(wholesalersB);
          break;
        case 'serviceProviders':
          final serviceProvidersA = a['serviceProviderCount'] ?? 0;
          final serviceProvidersB = b['serviceProviderCount'] ?? 0;
          comparison = serviceProvidersA.compareTo(serviceProvidersB);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadSalesManagerDetails();
  }

  Future<void> _loadSalesManagerDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _adminService.getSalesManager(widget.salesManagerId);
      
      // Debug logging to help troubleshoot
      debugPrint('Full response: $response');
      
      if (response['success'] == true) {
        final data = response['data'];
        
        // Add null safety checks and debug logging
        debugPrint('Response data: $data');
        
        try {
          // Safely parse salespersons data
          if (data['salespersons'] != null) {
            if (data['salespersons'] is List) {
              _salespersons = List<Map<String, dynamic>>.from(data['salespersons']);
            } else {
              _salespersons = [];
              debugPrint('Warning: salespersons is not a List, got: ${data['salespersons'].runtimeType}');
            }
          } else {
            _salespersons = [];
            debugPrint('Warning: salespersons data is null');
          }
          
          setState(() {
            _isLoading = false;
          });
        } catch (parseError) {
          debugPrint('Error parsing response data: $parseError');
          setState(() {
            _error = 'Failed to parse response data: $parseError\n\nResponse: ${response.toString()}';
            _isLoading = false;
          });
          return;
        }
      } else {
        final errorMessage = response['message'] ?? 'Unknown error occurred';
        debugPrint('API returned error: $errorMessage');
        setState(() {
          _error = 'API Error: $errorMessage';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Exception during API call: $e');
      setState(() {
        _error = 'Network Error: $e';
        _isLoading = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _sortBy = 'name';
      _sortAscending = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header Component
            HeaderComponent(
              logoPath: 'assets/logo/logo.png',
              scaffoldKey: _scaffoldKey,
            ),
            const SizedBox(height: 20),
            
            // Back Button and Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    '${widget.salesManagerName} - Details',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorWidget()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(fontSize: 16, color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSalesManagerDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filter Section
          _buildSearchAndFilterSection(),
          const SizedBox(height: 16),
          // Salespersons List
          _buildSalespersonsSection(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search salespersons...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Sort Controls Row
            Row(
              children: [
                // Sort Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: const InputDecoration(
                      labelText: 'Sort by',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('Name')),
                      DropdownMenuItem(value: 'commission', child: Text('Commission')),
                      DropdownMenuItem(value: 'companies', child: Text('Companies')),
                      DropdownMenuItem(value: 'wholesalers', child: Text('Wholesalers')),
                      DropdownMenuItem(value: 'serviceProviders', child: Text('Service Providers')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // Sort Direction Toggle
                Container(
                  height: 56, // Match the height of the dropdown
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                    },
                    icon: Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.blue[700],
                    ),
                    tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Results Summary and Reset Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Showing ${_filteredAndSortedSalespersons.length} of ${_salespersons.length} salespersons',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty || _sortBy != 'name' || !_sortAscending)
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalespersonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Salespersons (${_filteredAndSortedSalespersons.length})',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            if (_filteredAndSortedSalespersons.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  // Could add export functionality here
                },
                icon: const Icon(Icons.download),
                label: const Text('Export'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_filteredAndSortedSalespersons.isEmpty)
          _buildEmptySalespersonsState()
        else
          _buildSalespersonsList(),
      ],
    );
  }

  Widget _buildEmptySalespersonsState() {
    String message = 'No salespersons found';
    String subtitle = 'This sales manager hasn\'t created any salespersons yet.';
    
    if (_searchQuery.isNotEmpty) {
      message = 'No salespersons match your search';
      subtitle = 'Try adjusting your search criteria.';
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: _resetFilters,
                  child: const Text('Clear Search'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalespersonsList() {
    if (_filteredAndSortedSalespersons.isEmpty) return const SizedBox.shrink();
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredAndSortedSalespersons.length,
      itemBuilder: (context, index) {
        final salesperson = _filteredAndSortedSalespersons[index];
        
        // Add safety checks for required fields
        final fullName = salesperson['fullName'] as String? ?? 'Unknown';
        final email = salesperson['email'] as String? ?? 'No email';
        final phoneNumber = salesperson['phoneNumber'] as String? ?? 'No phone';
        final companyCount = salesperson['companyCount'] ?? 0;
        final wholesalerCount = salesperson['wholesalerCount'] ?? 0;
        final serviceProviderCount = salesperson['serviceProviderCount'] ?? 0;
        final totalCommission = (salesperson['totalCommission'] ?? 0.0) as double;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              radius: 18,
              child: Text(
                fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            title: Text(
              fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  phoneNumber,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _buildMetricChip(
                      'Companies',
                      companyCount.toString(),
                      Colors.green,
                    ),
                    _buildMetricChip(
                      'Wholesalers',
                      wholesalerCount.toString(),
                      Colors.orange,
                    ),
                    _buildMetricChip(
                      'Service Providers',
                      serviceProviderCount.toString(),
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Commission',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${totalCommission.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
