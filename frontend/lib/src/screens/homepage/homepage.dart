import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import '../../components/header.dart';
import '../../components/sidebar.dart';
import '../../services/api_services.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../models/salesperson_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedTabIndex = 0;
  final String _logoPath = 'assets/logo/logo.png';
  // Add a key to control the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Selected time period for analytics
  String _selectedPeriod = 'Month';

  // State variables for active users
  List<ActiveUser> _activeUsers = [];
  List<ActiveUser> _filteredUsers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedFilter = 'all';
  String _searchQuery = '';
  
  // State variables for salespersons
  List<Salesperson> _salespersons = [];
  List<Salesperson> _filteredSalespersons = [];
  bool _isLoadingSalespersons = false;
  String _errorMessageSalespersons = '';
  String _selectedSalespersonFilter = 'all';
  String _salespersonSearchQuery = '';
  
  // Enhanced search functionality
  late TextEditingController _searchController;
  late TextEditingController _salespersonSearchController;
  List<String> _searchHistory = [];
  List<String> _searchSuggestions = [];
  bool _showSearchSuggestions = false;
  bool _isSearchFocused = false;
  String _selectedSearchCategory = 'all';
  
  // Search categories
  final List<Map<String, dynamic>> _searchCategories = [
    {'key': 'all', 'label': 'All', 'icon': Icons.search},
    {'key': 'name', 'label': 'Name', 'icon': Icons.person},
    {'key': 'email', 'label': 'Email', 'icon': Icons.email},
    {'key': 'type', 'label': 'User Type', 'icon': Icons.category},
  ];

  // Salesperson search categories
  final List<Map<String, dynamic>> _salespersonSearchCategories = [
    {'key': 'all', 'label': 'All', 'icon': Icons.search},
    {'key': 'name', 'label': 'Name', 'icon': Icons.person},
    {'key': 'email', 'label': 'Email', 'icon': Icons.email},
    {'key': 'status', 'label': 'Status', 'icon': Icons.info},
    {'key': 'region', 'label': 'Region', 'icon': Icons.location_on},
  ];

  // Services
  late AdminService _adminService;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _searchQuery);
    _salespersonSearchController = TextEditingController(text: _salespersonSearchQuery);
    _searchController.addListener(_onSearchChanged);
    _salespersonSearchController.addListener(_onSalespersonSearchChanged);
    _adminService = AdminService(baseUrl: 'https://barrim.online');
    _fetchActiveUsers();
    _fetchSalespersons();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _salespersonSearchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  // Load search history from local storage
  void _loadSearchHistory() {
    // In a real app, you'd load this from SharedPreferences or similar
    _searchHistory = ['admin', 'manager', 'salesperson', 'worker'];
  }

  // Save search query to history
  void _saveToSearchHistory(String query) {
    if (query.trim().isNotEmpty && !_searchHistory.contains(query.trim())) {
      setState(() {
        _searchHistory.insert(0, query.trim());
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      });
    }
  }

  // Generate search suggestions based on current query and history
  void _generateSearchSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = _searchHistory.take(5).toList();
        _showSearchSuggestions = _searchSuggestions.isNotEmpty;
      });
      return;
    }

    List<String> suggestions = [];
    
    // Add history matches
    suggestions.addAll(_searchHistory.where((item) => 
        item.toLowerCase().contains(query.toLowerCase())));
    
    // Add user data matches
    suggestions.addAll(_activeUsers
        .where((user) => 
            user.fullName.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase()))
        .map((user) => user.fullName)
        .take(3));
    
    // Add user type matches
    suggestions.addAll(_activeUsers
        .map((user) => user.userType)
        .where((type) => type.toLowerCase().contains(query.toLowerCase()))
        .toSet()
        .take(2));
    
    setState(() {
      _searchSuggestions = suggestions.take(8).toList();
      _showSearchSuggestions = _searchSuggestions.isNotEmpty;
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _generateSearchSuggestions(_searchQuery);
    _applyFilters();
  }

  // Handle search suggestion selection
  void _onSuggestionSelected(String suggestion) {
    setState(() {
      _searchQuery = suggestion;
      _searchController.text = suggestion;
      _showSearchSuggestions = false;
    });
    _saveToSearchHistory(suggestion);
    _applyFilters();
  }

  // Clear search and suggestions
  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _showSearchSuggestions = false;
    });
    _applyFilters();
  }

  // Apply search category filter
  void _onSearchCategoryChanged(String category) {
    setState(() {
      _selectedSearchCategory = category;
    });
    _applyFilters();
  }

  // Highlight search terms in text
  Widget _highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);
    
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;
    
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
    }
    
    return RichText(text: TextSpan(children: spans));
  }



  // Handle search submission
  void _onSearchSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      _saveToSearchHistory(value.trim());
      setState(() {
        _showSearchSuggestions = false;
        _isSearchFocused = false;
      });
      _applyFilters();
    }
  }

  // Handle keyboard shortcuts
  void _handleKeyboardShortcuts(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          _showSearchSuggestions = false;
          _isSearchFocused = false;
        });
        FocusScope.of(context).unfocus();
      } else if (event.logicalKey == LogicalKeyboardKey.enter && _isSearchFocused) {
        _onSearchSubmitted(_searchQuery);
      }
    }
  }

  // Add search analytics
  void _logSearchAnalytics(String query, String category) {
    // In a real app, you'd send this to analytics service
    print('Search performed: "$query" in category: $category');
  }

  // Show search tips
  void _showSearchTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Tips'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchTip('Use categories to narrow your search', Icons.category),
            _buildSearchTip('Search by name, email, or user type', Icons.search),
            _buildSearchTip('Use quotes for exact matches', Icons.format_quote),
            _buildSearchTip('Press Enter to search, Esc to close', Icons.keyboard),
            _buildSearchTip('Recent searches are saved automatically', Icons.history),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTip(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Fetch active users from API
  Future<void> _fetchActiveUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.getActiveUsers();

      if (response.success) {
        setState(() {
          _activeUsers = (response.data['users'] as List).cast<ActiveUser>();
          _filteredUsers = List.from(_activeUsers);
          _isLoading = false;
        });
        _applyFilters(); // Apply current filters to the new data
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load active users: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Fetch salespersons from API
  Future<void> _fetchSalespersons() async {
    setState(() {
      _isLoadingSalespersons = true;
      _errorMessageSalespersons = '';
    });

    try {
      final response = await _adminService.GetAdminSalespersons();

      if (response['success']) {
        setState(() {
          _salespersons = (response['data'] as List).cast<Salesperson>();
          _filteredSalespersons = List.from(_salespersons);
          _isLoadingSalespersons = false;
        });
        _applySalespersonFilters(); // Apply current filters to the new data
      } else {
        setState(() {
          _errorMessageSalespersons = response['message'];
          _isLoadingSalespersons = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessageSalespersons = 'Failed to load salespersons: ${e.toString()}';
        _isLoadingSalespersons = false;
      });
    }
  }

  // Salesperson search functionality
  void _onSalespersonSearchChanged() {
    setState(() {
      _salespersonSearchQuery = _salespersonSearchController.text;
    });
    _applySalespersonFilters();
  }

  // Apply salesperson filters
  void _applySalespersonFilters() {
    List<Salesperson> filtered = List.from(_salespersons);
    
    // Apply status filter
    if (_selectedSalespersonFilter != 'all') {
      filtered = filtered
          .where((salesperson) => salesperson.status?.toLowerCase() == _selectedSalespersonFilter.toLowerCase())
          .toList();
    }
    
    // Apply search filter based on selected category
    if (_salespersonSearchQuery.isNotEmpty) {
      switch (_selectedSearchCategory) {
        case 'name':
          filtered = filtered
              .where((salesperson) => salesperson.fullName.toLowerCase().contains(_salespersonSearchQuery.toLowerCase()))
              .toList();
          break;
        case 'email':
          filtered = filtered
              .where((salesperson) => salesperson.email.toLowerCase().contains(_salespersonSearchQuery.toLowerCase()))
              .toList();
          break;
        case 'status':
          filtered = filtered
              .where((salesperson) => (salesperson.status ?? '').toLowerCase().contains(_salespersonSearchQuery.toLowerCase()))
              .toList();
          break;
        case 'region':
          filtered = filtered
              .where((salesperson) => (salesperson.region ?? '').toLowerCase().contains(_salespersonSearchQuery.toLowerCase()))
              .toList();
          break;
        default: // 'all'
          filtered = filtered
              .where((salesperson) => 
                  salesperson.fullName.toLowerCase().contains(_salespersonSearchQuery.toLowerCase()) ||
                  salesperson.email.toLowerCase().contains(_salespersonSearchQuery.toLowerCase()) ||
                  (salesperson.status ?? '').toLowerCase().contains(_salespersonSearchQuery.toLowerCase()) ||
                  (salesperson.region ?? '').toLowerCase().contains(_salespersonSearchQuery.toLowerCase()))
              .toList();
      }
    }
    
    setState(() {
      _filteredSalespersons = filtered;
    });
  }

  // Handle salesperson search category change
  void _onSalespersonSearchCategoryChanged(String category) {
    setState(() {
      _selectedSearchCategory = category;
    });
    _applySalespersonFilters();
  }

  // Clear salesperson search
  void _clearSalespersonSearch() {
    setState(() {
      _salespersonSearchQuery = '';
      _salespersonSearchController.clear();
    });
    _applySalespersonFilters();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Force mobile view regardless of screen size
        return Container(
          width: 390, // Standard mobile width
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Scaffold(
            key: _scaffoldKey, // Add scaffold key
            backgroundColor: Colors.grey.shade100,
            // Add the drawer with our Sidebar widget
            endDrawer: Sidebar(
              onCollapse: () {
                // Close the drawer when requested by sidebar
                _scaffoldKey.currentState?.closeEndDrawer();
              },
              parentContext: context,
            ),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add 50px of empty space before the header
                  SizedBox(height: 30),
                  // Use the new HeaderComponent instead of _buildHeader()
                  HeaderComponent(
                    logoPath: _logoPath,
                    scaffoldKey: _scaffoldKey,
                    onMenuPressed: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Text(
                      'Homepage',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1C4B),
                      ),
                    ),
                  ),
                  _selectedTabIndex == 0 ? _buildSearchBar() : _selectedTabIndex == 1 ? _buildSalespersonSearchBar() : const SizedBox.shrink(),
                  
                  // Search statistics
                  
                  // Add summary section
                  // _buildSummarySection(),
                  // Add filter section
                  // Directly display content based on selected tab
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _selectedTabIndex == 0 ? _fetchActiveUsers : _fetchSalespersons,
                      child: _selectedTabIndex == 0 
                          ? _buildActiveUsersList()
                          : _selectedTabIndex == 1 
                              ? _buildSalespersonsList()
                              : _buildGeneralAnalytics(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        // Search categories
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _searchCategories.map((category) {
                final isSelected = _selectedSearchCategory == category['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _onSearchCategoryChanged(category['key']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0D1C4B) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0D1C4B) : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category['icon'],
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category['label'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // Enhanced search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                                 // Main search input
                 TextField(
                   controller: _searchController,
                   style: const TextStyle(
                     color: Color(0xFF0D1C4B),
                     fontSize: 16,
                   ),
                   decoration: InputDecoration(
                     hintText: 'Search users, emails, or user types...',
                     hintStyle: TextStyle(
                       color: Colors.grey.shade500,
                       fontSize: 14,
                     ),
                     prefixIcon: Icon(
                       Icons.search,
                       color: _isSearchFocused ? const Color(0xFF0D1C4B) : Colors.grey.shade400,
                       size: 24,
                     ),
                     suffixIcon: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         if (_searchQuery.isNotEmpty)
                           IconButton(
                             icon: Icon(
                               Icons.clear,
                               color: Colors.grey.shade400,
                               size: 20,
                             ),
                             onPressed: _clearSearch,
                             tooltip: 'Clear search',
                           ),
                         IconButton(
                           icon: Icon(
                             Icons.help_outline,
                             color: Colors.grey.shade400,
                             size: 20,
                           ),
                           onPressed: _showSearchTips,
                           tooltip: 'Search tips',
                         ),
                       ],
                     ),
                     border: InputBorder.none,
                     contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                   ),
                   onChanged: (value) {
                     _debouncedSearch(value);
                   },
                   onSubmitted: _onSearchSubmitted,
                   onTap: () {
                     setState(() {
                       _isSearchFocused = true;
                       _showSearchSuggestions = true;
                     });
                   },
                   onEditingComplete: () {
                     setState(() {
                       _isSearchFocused = false;
                       _showSearchSuggestions = false;
                     });
                   },
                 ),
                 
                 
                
                // Search suggestions dropdown
                if (_showSearchSuggestions && _searchSuggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _searchSuggestions[index];
                        final isHistory = _searchHistory.contains(suggestion);
                        
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            isHistory ? Icons.history : Icons.search,
                            size: 18,
                            color: isHistory ? Colors.blue.shade600 : Colors.grey.shade600,
                          ),
                          title: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF0D1C4B),
                            ),
                          ),
                          subtitle: isHistory ? Text(
                            'Recent search',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ) : null,
                          onTap: () => _onSuggestionSelected(suggestion),
                          tileColor: Colors.transparent,
                          hoverColor: Colors.grey.shade100,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Method to reset all filters and search
  void _resetAllFilters() {
    setState(() {
      _selectedFilter = 'all';
      _searchQuery = '';
      _searchController.clear();
      _showSearchSuggestions = false;
      _isSearchFocused = false;
    });
  }

  // Enhanced search with debouncing
  Timer? _searchDebounceTimer;
  void _debouncedSearch(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
        _generateSearchSuggestions(query);
        _applyFilters();
      }
    });
  }

  // Method to apply both search and filter
  void _applyFilters() {
    List<ActiveUser> filtered = List.from(_activeUsers);
    
    // Apply type filter
    if (_selectedFilter != 'all') {
      filtered = filtered
          .where((user) => user.userType.toLowerCase() == _selectedFilter.toLowerCase())
          .toList();
    }
    
    // Apply search filter based on selected category
    if (_searchQuery.isNotEmpty) {
      switch (_selectedSearchCategory) {
        case 'name':
          filtered = filtered
              .where((user) => user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          break;
        case 'email':
          filtered = filtered
              .where((user) => user.email.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          break;
        case 'type':
          filtered = filtered
              .where((user) => user.userType.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          break;
        default: // 'all'
          filtered = filtered
              .where((user) => 
                  user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  user.userType.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
      }
    }
    
    setState(() {
      _filteredUsers = filtered;
    });
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTab('Active Users', 0, _activeUsers.length.toString()),
          const SizedBox(width: 16),
          _buildTab('Salespersons', 1, _salespersons.length.toString()),
          const SizedBox(width: 16),
          _buildTab('General Analytics', 2, null),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index, String? badge) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _selectedTabIndex == index
                      ? const Color(0xFF0D1C4B)
                      : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 100,
            color: _selectedTabIndex == index
                ? const Color(0xFF0D1C4B)
                : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1C4B),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((day) {
                final isSelected = day == 'Thu';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF2F4FF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF0D1C4B) : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: false,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              String text = '';
                              if (value == 0) {
                                text = '0';
                              } else if (value == 50000) {
                                text = '50k';
                              } else if (value == 100000) {
                                text = '100k';
                              } else if (value == 500000) {
                                text = '500k';
                              }
                              return Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              );
                            },
                            reservedSize: 28,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              String text = '';
                              if (value == 0) {
                                text = '12am';
                              } else if (value == 3) {
                                text = '3am';
                              } else if (value == 6) {
                                text = '6am';
                              } else if (value == 9) {
                                text = '9am';
                              } else if (value == 12) {
                                text = '12pm';
                              } else if (value == 15) {
                                text = '3pm';
                              } else if (value == 18) {
                                text = '6pm';
                              } else if (value == 21) {
                                text = '9pm';
                              }
                              return Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              );
                            },
                            reservedSize: 22,
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            const FlSpot(0, 80000),
                            const FlSpot(3, 60000),
                            const FlSpot(6, 50000),
                            const FlSpot(9, 70000),
                            const FlSpot(12, 80000),
                            const FlSpot(15, 120000),
                            const FlSpot(18, 100000),
                            const FlSpot(21, 70000),
                          ],
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.red.shade300,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              // Only show dot at 3pm (peak)
                              if (index == 5) {
                                return FlDotCirclePainter(
                                  radius: 6,
                                  color: Colors.red.shade300,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              }
                              return FlDotCirclePainter(
                                radius: 0,
                                color: Colors.transparent,
                                strokeWidth: 0,
                                strokeColor: Colors.transparent,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.red.shade100.withOpacity(0.2),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(enabled: false),
                    ),
                  ),
                  // Dashed vertical line
                  Positioned(
                    top: 0,
                    bottom: 20,
                    right: 100,
                    child: VerticalDivider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                      width: 1,
                      indent: 20,
                      endIndent: 0,
                    ),
                  ),
                  // 290k bubble on peak
                  Positioned(
                    top: 15,
                    right: 85,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1C4B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '290k',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveUsersList() {
    // Show loading indicator if data is being loaded
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error message if loading failed
    if (_errorMessage.isNotEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchActiveUsers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state if no active users
    if (_filteredUsers.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, color: Colors.grey.shade400, size: 48),
              const SizedBox(height: 16),
              Text(
                _activeUsers.isEmpty 
                    ? 'No active users at the moment'
                    : 'No users match the selected filter',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      );
    }

    // Show list of active users
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView.builder(
          itemCount: _filteredUsers.length,
          itemBuilder: (context, index) {
            final user = _filteredUsers[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User header with avatar and status
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _getUserTypeColor(user.userType),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getUserTypeIcon(user.userType),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: user.isActive ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  color: Color(0xFF0D1C4B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getUserTypeColor(user.userType).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatUserType(user.userType),
                                      style: TextStyle(
                                        color: _getUserTypeColor(user.userType),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: user.isActive 
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        color: user.isActive ? Colors.green : Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // User details section
                    _buildUserDetails(user),
                    
                    const SizedBox(height: 12),
                    
                    // Time connected
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last Activity: ${user.lastActivity != null ? _formatLastActivity(user.lastActivity) : 'Never'}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              if (user.timeConnected != 'unknown')
                                Text(
                                  'Connected: ${user.timeConnected}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Add expand/collapse button for more details
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          onPressed: () {
                            _showUserDetailsDialog(user);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSalespersonsList() {
    // Show loading indicator if data is being loaded
    if (_isLoadingSalespersons) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error message if loading failed
    if (_errorMessageSalespersons.isNotEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessageSalespersons,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchSalespersons,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state if no salespersons
    if (_filteredSalespersons.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, color: Colors.grey.shade400, size: 48),
              const SizedBox(height: 16),
              Text(
                _salespersons.isEmpty 
                    ? 'No salespersons at the moment'
                    : 'No salespersons match the selected filter',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      );
    }

    // Show list of salespersons
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView.builder(
          itemCount: _filteredSalespersons.length,
          itemBuilder: (context, index) {
            final salesperson = _filteredSalespersons[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Salesperson header with avatar and status
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _getSalespersonStatusColor(salesperson.status),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: (salesperson.status ?? 'inactive') == 'active' ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                salesperson.fullName,
                                style: const TextStyle(
                                  color: Color(0xFF0D1C4B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                salesperson.email,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getSalespersonStatusColor(salesperson.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatSalespersonStatus(salesperson.status),
                                      style: TextStyle(
                                        color: _getSalespersonStatusColor(salesperson.status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (salesperson.region != null && salesperson.region!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        salesperson.region!,
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Salesperson details section
                    _buildSalespersonDetails(salesperson),
                    
                    const SizedBox(height: 12),
                    
                    // Additional info
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          salesperson.phoneNumber,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        if (salesperson.commissionPercent > 0) ...[
                          Icon(
                            Icons.percent,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${salesperson.commissionPercent.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(width: 16),
                        // Add expand/collapse button for more details
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          onPressed: () {
                            _showSalespersonDetailsDialog(salesperson);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSalespersonSearchBar() {
    return Column(
      children: [
        // Search categories
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _salespersonSearchCategories.map((category) {
                final isSelected = _selectedSearchCategory == category['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _onSalespersonSearchCategoryChanged(category['key']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0D1C4B) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0D1C4B) : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category['icon'],
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category['label'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // Enhanced search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _salespersonSearchController,
              style: const TextStyle(
                color: Color(0xFF0D1C4B),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search salespersons by name, email, status, or region...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
                suffixIcon: _salespersonSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        onPressed: _clearSalespersonSearch,
                        tooltip: 'Clear search',
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalespersonDetails(Salesperson salesperson) {
    final List<Widget> details = [];
    
    // Add commission information
    if (salesperson.commissionPercent > 0) {
      details.add(_buildDetailRow('Commission', '${salesperson.commissionPercent.toStringAsFixed(1)}%'));
    }
    
    if (salesperson.region != null && salesperson.region!.isNotEmpty) {
      details.add(_buildDetailRow('Region', salesperson.region!));
    }
    
    if (salesperson.createdAt != null) {
      details.add(_buildDetailRow('Created', _formatDate(salesperson.createdAt!)));
    }
    
    if (details.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: details,
    );
  }

  Widget _buildUserDetails(ActiveUser user) {
    final List<Widget> details = [];
    
    // Add status information based on user type
    if (user.status != null) {
      details.add(_buildDetailRow('Status', user.status!));
    }
    
    if (user.branchStatus != null) {
      details.add(_buildDetailRow('Branch Status', user.branchStatus!));
    }
    
    if (user.salespersonEmail != null) {
      details.add(_buildDetailRow('Salesperson', user.salespersonEmail!));
    }
    
    if (details.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: details,
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'company':
        return Colors.blue;
      case 'wholesaler':
        return Colors.orange;
      case 'service_provider':
        return Colors.purple;
      case 'salesperson':
        return Colors.green;
      case 'sales_manager':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getUserTypeIcon(String userType) {
    switch (userType.toLowerCase()) {
      case 'company':
        return Icons.business;
      case 'wholesaler':
        return Icons.store;
      case 'service_provider':
        return Icons.build;
      case 'salesperson':
        return Icons.person;
      case 'sales_manager':
        return Icons.manage_accounts;
      default:
        return Icons.person;
    }
  }

  String _formatUserType(String userType) {
    switch (userType.toLowerCase()) {
      case 'company':
        return 'Company';
      case 'wholesaler':
        return 'Wholesaler';
      case 'service_provider':
        return 'Service Provider';
      case 'salesperson':
        return 'Salesperson';
      case 'sales_manager':
        return 'Sales Manager';
      default:
        return userType;
    }
  }

  Color _getSalespersonStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _formatSalespersonStatus(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    return status.substring(0, 1).toUpperCase() + status.substring(1).toLowerCase();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // New method for General Analytics tab content
  Widget _buildGeneralAnalytics() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalyticsChart('Users', '+10%'),
            const SizedBox(height: 16),
            _buildAnalyticsChart('Company Subscriptions', '+10%'),
          ],
        ),
      ),
    );
  }

  // Method to build analytics chart cards
  Widget _buildAnalyticsChart(String title, String percentageChange) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1C4B),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 18,
                      color: Colors.grey.shade700
                  ),
                  const SizedBox(width: 4),
                  _buildPeriodSelector(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 100,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            String text = '';
                            if (value == 0) {
                              text = '0';
                            } else if (value == 100) {
                              text = '100k';
                            } else if (value == 200) {
                              text = '200k';
                            } else if (value == 300) {
                              text = '300k';
                            } else if (value == 400) {
                              text = '400k';
                            }
                            return Text(
                              text,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                              ),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            String text = '';
                            if (value >= 1 && value <= 12) {
                              text = value.toInt().toString();
                            }
                            return Text(
                              text,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                              ),
                            );
                          },
                          reservedSize: 22,
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          const FlSpot(1, 220),
                          const FlSpot(2, 200),
                          const FlSpot(3, 240),
                          const FlSpot(4, 250),
                          const FlSpot(5, 230),
                          const FlSpot(6, 220),
                          const FlSpot(7, 290),
                          const FlSpot(8, 200),
                          const FlSpot(9, 120),
                          const FlSpot(10, 180),
                          const FlSpot(11, 220),
                          const FlSpot(12, 300),
                        ],
                        isCurved: true,
                        barWidth: 3,
                        color: const Color(0xFF5B87EA),
                        dotData: FlDotData(
                          show: false,
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF5B87EA).withOpacity(0.2),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(enabled: false),
                  ),
                ),
                // Percentage change bubble
                Positioned(
                  top: 15,
                  right: 75,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      percentageChange,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to build period selector
  Widget _buildPeriodSelector() {
    return Row(
      children: [
        _buildPeriodButton('Day'),
        const SizedBox(width: 8),
        _buildPeriodButton('Month'),
      ],
    );
  }

  // Method to build period button
  Widget _buildPeriodButton(String period) {
    final bool isSelected = _selectedPeriod == period;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D1C4B) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: Colors.grey.shade400),
        ),
        child: Text(
          period,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  


  
  // Method to format last activity date
  String _formatLastActivity(DateTime? lastActivity) {
    if (lastActivity == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastActivity);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // Method to show user details dialog
  void _showUserDetailsDialog(ActiveUser user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(user.fullName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', user.email),
                _buildDetailRow('User Type', _formatUserType(user.userType)),
                _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
                if (user.status != null) _buildDetailRow('Status', user.status!),
                if (user.branchStatus != null) _buildDetailRow('Branch Status', user.branchStatus!),
                if (user.salesManagerEmail != null) _buildDetailRow('Sales Manager', user.salesManagerEmail!),
                if (user.salespersonEmail != null) _buildDetailRow('Salesperson', user.salespersonEmail!),
                if (user.lastActivity != null) _buildDetailRow('Last Activity', _formatLastActivity(user.lastActivity)),
                _buildDetailRow('Time Connected', user.timeConnected),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0D1C4B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to show salesperson details dialog
  void _showSalespersonDetailsDialog(Salesperson salesperson) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(salesperson.fullName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', salesperson.email),
                _buildDetailRow('Phone', salesperson.phoneNumber),
                _buildDetailRow('Status', _formatSalespersonStatus(salesperson.status)),
                if (salesperson.region != null && salesperson.region!.isNotEmpty) 
                  _buildDetailRow('Region', salesperson.region!),
                if (salesperson.commissionPercent > 0)
                  _buildDetailRow('Commission', '${salesperson.commissionPercent.toStringAsFixed(1)}%'),
                if (salesperson.createdAt != null)
                  _buildDetailRow('Created', _formatDate(salesperson.createdAt!)),
                if (salesperson.updatedAt != null)
                  _buildDetailRow('Updated', _formatDate(salesperson.updatedAt!)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}