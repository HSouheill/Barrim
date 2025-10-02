import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../components/header.dart';
import '../../components/sidebar.dart';
import '../../services/api_services.dart';
import '../../models/user_model.dart';
import '../../models/company_model.dart' as company_model;
import '../../models/pending_request_models.dart';
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

  // State variables for all entities
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  List<company_model.Company> _allCompanies = [];
  List<company_model.Company> _filteredCompanies = [];
  List<Wholesaler> _allWholesalers = [];
  List<Wholesaler> _filteredWholesalers = [];
  List<User> _allServiceProviders = [];
  List<User> _filteredServiceProviders = [];
  List<Salesperson> _allSalespersons = [];
  List<Salesperson> _filteredSalespersons = [];
  
  // Track expanded companies for branch display
  Set<String> _expandedCompanies = <String>{};
  
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedFilter = 'all';
  String _searchQuery = '';
  
  // Enhanced search functionality
  late TextEditingController _searchController;
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
    {'key': 'region', 'label': 'Region', 'icon': Icons.location_on},
  ];



  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _searchQuery);
    _searchController.addListener(_onSearchChanged);
    _fetchAllEntities();
    _fetchAllSalespersons();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    if (_allUsers.isNotEmpty) {
      suggestions.addAll(_allUsers
          .where((user) => 
              user.fullName.toLowerCase().contains(query.toLowerCase()) ||
              user.email.toLowerCase().contains(query.toLowerCase()))
          .map((user) => user.fullName)
          .take(3));
    }
    
    // Add user type matches
    if (_allUsers.isNotEmpty) {
      suggestions.addAll(_allUsers
          .map((user) => user.userType)
          .where((type) => type.toLowerCase().contains(query.toLowerCase()))
          .toSet()
          .take(2));
    }
    
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


  // Fetch all entities from API
  Future<void> _fetchAllEntities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.getAllEntities();

      if (response.success && response.data != null) {
        setState(() {
          // Parse users
          final usersList = response.data['users'] as List?;
          if (usersList != null) {
            _allUsers = usersList.map((json) => User.fromJson(json)).toList();
            _filteredUsers = List.from(_allUsers);
          } else {
            _allUsers = [];
            _filteredUsers = [];
          }

          // Parse companies
          final companiesList = response.data['companies'] as List?;
          if (companiesList != null) {
            _allCompanies = companiesList.map((json) => company_model.Company.fromJson(json)).toList();
            _filteredCompanies = List.from(_allCompanies);
          } else {
            _allCompanies = [];
            _filteredCompanies = [];
          }

          // Parse wholesalers
          final wholesalersList = response.data['wholesalers'] as List?;
          if (wholesalersList != null) {
            _allWholesalers = wholesalersList.map((json) => Wholesaler.fromJson(json)).toList();
            _filteredWholesalers = List.from(_allWholesalers);
          } else {
            _allWholesalers = [];
            _filteredWholesalers = [];
          }

          // Parse service providers
          final serviceProvidersList = response.data['serviceProviders'] as List?;
          if (serviceProvidersList != null) {
            _allServiceProviders = serviceProvidersList.map((json) => User.fromJson(json)).toList();
            _filteredServiceProviders = List.from(_allServiceProviders);
          } else {
            _allServiceProviders = [];
            _filteredServiceProviders = [];
          }

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
        _errorMessage = 'Failed to load entities: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Fetch all salespersons from API
  Future<void> _fetchAllSalespersons() async {
    try {
      final response = await ApiService.getAllSalespersons();

      if (response.success && response.data != null) {
        setState(() {
          final salespersonsList = response.data['salespersons'] as List?;
          if (salespersonsList != null) {
            _allSalespersons = salespersonsList.map((json) => Salesperson.fromJson(json)).toList();
            _filteredSalespersons = List.from(_allSalespersons);
          } else {
            _allSalespersons = [];
            _filteredSalespersons = [];
          }
        });
        _applyFilters(); // Apply current filters to the new data
      }
    } catch (e) {
      print('Error fetching salespersons: $e');
    }
  }




  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Force mobile view regardless of screen size
        return Center(
          child: Container(
            width: 390, // Standard mobile width
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width,
            ),
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
                  // Add tabs
                  _buildTabs(),
                  
                  // Show search bar based on selected tab
                  _selectedTabIndex == 0 ? _buildSearchBar() : 
                  _selectedTabIndex == 1 ? _buildCompanySearchBar() :
                  _selectedTabIndex == 2 ? _buildWholesalerSearchBar() :
                  _selectedTabIndex == 3 ? _buildServiceProviderSearchBar() :
                  _selectedTabIndex == 4 ? _buildSalespersonSearchBar() :
                  const SizedBox.shrink(),
                  
                  // Display content based on selected tab
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _selectedTabIndex == 0 ? _fetchAllEntities : 
                                _selectedTabIndex == 1 ? _fetchAllEntities :
                                _selectedTabIndex == 2 ? _fetchAllEntities :
                                _selectedTabIndex == 3 ? _fetchAllEntities :
                                _selectedTabIndex == 4 ? _fetchAllSalespersons :
                                _fetchAllEntities,
                      child: _selectedTabIndex == 0 
                          ? _buildAllUsersList()
                          : _selectedTabIndex == 1 
                              ? _buildCompaniesList()
                              : _selectedTabIndex == 2
                                  ? _buildWholesalersList()
                                  : _selectedTabIndex == 3
                                      ? _buildServiceProvidersList()
                                      : _buildSalespersonsList(),
                    ),
                  ),
                ],
              ),
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
                     hintText: 'Search all users, emails, or user types...',
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
    // Apply filters based on selected tab
    switch (_selectedTabIndex) {
      case 0: // Users
        _applyUserFilters();
        break;
      case 1: // Companies
        _applyCompanyFilters();
        break;
      case 2: // Wholesalers
        _applyWholesalerFilters();
        break;
      case 3: // Service Providers
        _applyServiceProviderFilters();
        break;
      case 4: // Salespersons
        _applySalespersonFilters();
        break;
      default:
        _applyUserFilters();
    }
  }

  void _applyUserFilters() {
    List<User> filtered = List.from(_allUsers);
    
    // Filter to show only users with userType "user"
    filtered = filtered
        .where((user) => user.userType.toLowerCase() == 'user')
        .toList();
    
    // Apply type filter (if needed for additional filtering)
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

  void _applyCompanyFilters() {
    List<company_model.Company> filtered = List.from(_allCompanies);
    
    // Apply search filter based on selected category
    if (_searchQuery.isNotEmpty) {
      switch (_selectedSearchCategory) {
        case 'name':
          filtered = filtered
              .where((company) => company.businessName.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          break;
        case 'email':
          filtered = filtered
              .where((company) => company.email.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          break;
        case 'category':
          filtered = filtered
              .where((company) => company.category.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          break;
        default: // 'all'
          filtered = filtered
              .where((company) => 
                  company.businessName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  company.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  company.category.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
      }
    }
    
    setState(() {
      _filteredCompanies = filtered;
    });
  }

  void _applyWholesalerFilters() {
    List<Wholesaler> filtered = List.from(_allWholesalers);
    
    // Apply search filter based on selected category
    if (_searchQuery.isNotEmpty) {
      switch (_selectedSearchCategory) {
        case 'name':
          filtered = filtered
              .where((wholesaler) => wholesaler.businessName.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          break;
        case 'email':
          filtered = filtered
              .where((wholesaler) => wholesaler.email.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          break;
        case 'category':
          filtered = filtered
              .where((wholesaler) => wholesaler.category.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          break;
        default: // 'all'
          filtered = filtered
              .where((wholesaler) => 
                  wholesaler.businessName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  wholesaler.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  wholesaler.category.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
      }
    }
    
    setState(() {
      _filteredWholesalers = filtered;
    });
  }

  void _applyServiceProviderFilters() {
    List<User> filtered = List.from(_allServiceProviders);
    
    // Apply search filter based on selected category
    if (_searchQuery.isNotEmpty) {
      switch (_selectedSearchCategory) {
        case 'name':
          filtered = filtered
              .where((sp) => sp.fullName.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          break;
        case 'email':
          filtered = filtered
              .where((sp) => sp.email.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          break;
        case 'service':
          filtered = filtered
              .where((sp) => sp.serviceProviderInfo?.serviceType.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
              .toList();
          break;
        default: // 'all'
          filtered = filtered
              .where((sp) => 
                  sp.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  sp.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (sp.serviceProviderInfo?.serviceType.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
              .toList();
      }
    }
    
    setState(() {
      _filteredServiceProviders = filtered;
    });
  }

  void _applySalespersonFilters() {
    List<Salesperson> filtered = List.from(_allSalespersons);
    
    // Apply search filter based on selected category
    if (_searchQuery.isNotEmpty) {
      switch (_selectedSearchCategory) {
        case 'name':
          filtered = filtered
              .where((sp) => sp.fullName.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          break;
        case 'email':
          filtered = filtered
              .where((sp) => sp.email.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          break;
        case 'region':
          filtered = filtered
              .where((sp) => (sp.region ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
          break;
        default: // 'all'
          filtered = filtered
              .where((sp) => 
                  sp.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  sp.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (sp.region ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
      }
    }
    
    setState(() {
      _filteredSalespersons = filtered;
    });
  }

  Widget _buildTabs() {
    // Count only regular users (userType == "user")
    final regularUsersCount = _allUsers.where((user) => user.userType.toLowerCase() == 'user').length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTab('Users', 0, regularUsersCount.toString()),
            const SizedBox(width: 12),
            _buildTab('Companies', 1, _allCompanies.length.toString()),
            const SizedBox(width: 12),
            _buildTab('Wholesalers', 2, _allWholesalers.length.toString()),
            const SizedBox(width: 12),
            _buildTab('Service Providers', 3, _allServiceProviders.length.toString()),
            const SizedBox(width: 12),
            _buildTab('Salespersons', 4, _allSalespersons.length.toString()),
          ],
        ),
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


  Widget _buildAllUsersList() {
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
                onPressed: _fetchAllEntities,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state if no active users
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 16),
            Text(
              _allUsers.isEmpty 
                  ? 'No users at the moment'
                  : 'No users match the selected filter',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    // Show list of all users
    return Padding(
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
                    
                    // User info
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (user.phone != null && user.phone!.isNotEmpty)
                                Text(
                                  'Phone: ${user.phone!}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
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
      );
    
  }


  Widget _buildCompanySearchBar() {
    return Column(
      children: [
        // Search categories
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSearchCategoryChip('all', 'All', Icons.search),
                _buildSearchCategoryChip('name', 'Name', Icons.business),
                _buildSearchCategoryChip('email', 'Email', Icons.email),
                _buildSearchCategoryChip('category', 'Category', Icons.category),
              ],
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
              controller: _searchController,
              style: const TextStyle(
                color: Color(0xFF0D1C4B),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search companies by name, email, or category...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        onPressed: _clearSearch,
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

  Widget _buildWholesalerSearchBar() {
    return Column(
      children: [
        // Search categories
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSearchCategoryChip('all', 'All', Icons.search),
                _buildSearchCategoryChip('name', 'Name', Icons.store),
                _buildSearchCategoryChip('email', 'Email', Icons.email),
                _buildSearchCategoryChip('category', 'Category', Icons.category),
              ],
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
              controller: _searchController,
              style: const TextStyle(
                color: Color(0xFF0D1C4B),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search wholesalers by name, email, or category...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        onPressed: _clearSearch,
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

  Widget _buildServiceProviderSearchBar() {
    return Column(
      children: [
        // Search categories
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSearchCategoryChip('all', 'All', Icons.search),
                _buildSearchCategoryChip('name', 'Name', Icons.build),
                _buildSearchCategoryChip('email', 'Email', Icons.email),
                _buildSearchCategoryChip('service', 'Service', Icons.category),
              ],
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
              controller: _searchController,
              style: const TextStyle(
                color: Color(0xFF0D1C4B),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search service providers by name, email, or service type...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        onPressed: _clearSearch,
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
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: Color(0xFF0D1C4B),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search salespersons by name, email, or region...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        onPressed: _clearSearch,
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


  Widget _buildSearchCategoryChip(String key, String label, IconData icon) {
    final isSelected = _selectedSearchCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _onSearchCategoryChanged(key),
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
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
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
  }

  Widget _buildCompaniesList() {
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
                onPressed: _fetchAllEntities,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state if no companies
    if (_filteredCompanies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 16),
            Text(
              _allCompanies.isEmpty 
                  ? 'No companies at the moment'
                  : 'No companies match the selected filter',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    // Show list of companies
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
          itemCount: _filteredCompanies.length,
          itemBuilder: (context, index) {
            final company = _filteredCompanies[index];
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
                    // Company header with avatar and status
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.business,
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
                                  color: Colors.green,
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
                                company.businessName,
                                style: const TextStyle(
                                  color: Color(0xFF0D1C4B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                company.email,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
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
                                      company.category,
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  // Branch count indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${company.branches?.length ?? 0} branches',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
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
                    
                    // Company details section
                    _buildCompanyDetails(company),
                    
                    // Branches section (expandable)
                    if (company.branches != null && company.branches!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildBranchesSection(company),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // Company info
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Phone: ${company.contactInfo.phone}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
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
                            _showCompanyDetailsDialog(company);
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
      );
    
  }

  Widget _buildWholesalersList() {
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
                onPressed: _fetchAllEntities,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state if no wholesalers
    if (_filteredWholesalers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 16),
            Text(
              _allWholesalers.isEmpty 
                  ? 'No wholesalers at the moment'
                  : 'No wholesalers match the selected filter',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    // Show list of wholesalers
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
          itemCount: _filteredWholesalers.length,
          itemBuilder: (context, index) {
            final wholesaler = _filteredWholesalers[index];
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
                    // Wholesaler header with avatar and status
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.store,
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
                                  color: Colors.green,
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
                                wholesaler.businessName,
                                style: const TextStyle(
                                  color: Color(0xFF0D1C4B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                wholesaler.email,
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
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      wholesaler.category,
                                      style: TextStyle(
                                        color: Colors.orange,
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
                    
                    // Wholesaler details section
                    _buildWholesalerDetails(wholesaler),
                    
                    const SizedBox(height: 12),
                    
                    // Wholesaler info
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Phone: ${wholesaler.contactInfo.phone}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
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
                            _showWholesalerDetailsDialog(wholesaler);
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
      );
    
  }

  Widget _buildServiceProvidersList() {
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
                onPressed: _fetchAllEntities,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state if no service providers
    if (_filteredServiceProviders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_outlined, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 16),
            Text(
              _allServiceProviders.isEmpty 
                  ? 'No service providers at the moment'
                  : 'No service providers match the selected filter',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    // Show list of service providers
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
          itemCount: _filteredServiceProviders.length,
          itemBuilder: (context, index) {
            final serviceProvider = _filteredServiceProviders[index];
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
                    // Service provider header with avatar and status
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.build,
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
                                  color: serviceProvider.isActive ? Colors.green : Colors.grey,
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
                                serviceProvider.fullName,
                                style: const TextStyle(
                                  color: Color(0xFF0D1C4B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                serviceProvider.email,
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
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      serviceProvider.serviceProviderInfo?.serviceType ?? 'Service Provider',
                                      style: TextStyle(
                                        color: Colors.purple,
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
                    
                    // Service provider details section
                    _buildServiceProviderDetails(serviceProvider),
                    
                    const SizedBox(height: 12),
                    
                    // Service provider info
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (serviceProvider.phone != null && serviceProvider.phone!.isNotEmpty)
                                Text(
                                  'Phone: ${serviceProvider.phone!}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
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
                            _showServiceProviderDetailsDialog(serviceProvider);
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
      );
    
  }

  Widget _buildSalespersonsList() {
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
                onPressed: _fetchAllSalespersons,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state if no salespersons
    if (_filteredSalespersons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 16),
            Text(
              _allSalespersons.isEmpty 
                  ? 'No salespersons at the moment'
                  : 'No salespersons match the selected filter',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    // Show list of salespersons
    return Padding(
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
                                color: Colors.green,
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
                                  color: (salesperson.status == 'active') ? Colors.green : Colors.grey,
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
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Salesperson',
                                      style: TextStyle(
                                        color: Colors.green,
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
                    
                    // Salesperson info
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Phone: ${salesperson.phoneNumber}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
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
      );
    
  }


  Widget _buildCompanyDetails(company_model.Company company) {
    final List<Widget> details = [];
    
    // Add company information
    if (company.points > 0) {
      details.add(_buildDetailRow('Points', company.points.toString()));
    }
    
    if (company.balance > 0) {
      details.add(_buildDetailRow('Balance', '\$${company.balance.toStringAsFixed(2)}'));
    }
    
    if (company.subCategory != null && company.subCategory!.isNotEmpty) {
      details.add(_buildDetailRow('Sub Category', company.subCategory!));
    }
    
    if (details.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: details,
    );
  }

  Widget _buildWholesalerDetails(Wholesaler wholesaler) {
    final List<Widget> details = [];
    
    // Add wholesaler information
    if (wholesaler.subCategory != null && wholesaler.subCategory!.isNotEmpty) {
      details.add(_buildDetailRow('Sub Category', wholesaler.subCategory!));
    }
    
    if (details.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: details,
    );
  }

  Widget _buildServiceProviderDetails(User serviceProvider) {
    final List<Widget> details = [];
    
    // Add service provider information
    if (serviceProvider.points > 0) {
      details.add(_buildDetailRow('Points', serviceProvider.points.toString()));
    }
    
    if (serviceProvider.serviceProviderInfo?.rating != null && serviceProvider.serviceProviderInfo!.rating > 0) {
      details.add(_buildDetailRow('Rating', '${serviceProvider.serviceProviderInfo!.rating}/5'));
    }
    
    if (serviceProvider.serviceProviderInfo?.description != null && serviceProvider.serviceProviderInfo!.description!.isNotEmpty) {
      details.add(_buildDetailRow('Description', serviceProvider.serviceProviderInfo!.description!));
    }
    
    if (details.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: details,
    );
  }

  Widget _buildSalespersonDetails(Salesperson salesperson) {
    final List<Widget> details = [];
    
    // Add salesperson information
    if (salesperson.commissionPercent > 0) {
      details.add(_buildDetailRow('Commission', '${salesperson.commissionPercent}%'));
    }
    
    if (salesperson.status != null && salesperson.status!.isNotEmpty) {
      details.add(_buildDetailRow('Status', salesperson.status!));
    }
    
    if (details.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: details,
    );
  }

  Widget _buildUserDetails(User user) {
    final List<Widget> details = [];
    
    // Add user information
    if (user.points > 0) {
      details.add(_buildDetailRow('Points', user.points.toString()));
    }
    
    if (user.location != null) {
      details.add(_buildDetailRow('Location', '${user.location!.city}, ${user.location!.country}'));
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


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }




  


  

  // Method to show user details dialog
  void _showUserDetailsDialog(User user) {
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
                if (user.phone != null && user.phone!.isNotEmpty) _buildDetailRow('Phone', user.phone!),
                if (user.points > 0) _buildDetailRow('Points', user.points.toString()),
                if (user.location != null) _buildDetailRow('Location', '${user.location!.city}, ${user.location!.country}'),
                _buildDetailRow('Created', _formatDate(user.createdAt)),
                _buildDetailRow('Updated', _formatDate(user.updatedAt)),
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

  // Method to build expandable branches section for company cards
  Widget _buildBranchesSection(company_model.Company company) {
    final isExpanded = _expandedCompanies.contains(company.id);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Branches header with expand/collapse button
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCompanies.remove(company.id);
                } else {
                  _expandedCompanies.add(company.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Branches (${company.branches!.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0D1C4B),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          
          // Branches list (shown when expanded)
          if (isExpanded) ...[
            const Divider(height: 1),
            ...company.branches!.map((branch) => _buildBranchListItem(branch)).toList(),
          ],
        ],
      ),
    );
  }

  // Method to build individual branch item in the expandable list
  Widget _buildBranchListItem(company_model.Branch branch) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.store,
                size: 14,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  branch.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF0D1C4B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${branch.location.street}, ${branch.location.city}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            children: [
              Text(
                branch.category,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (branch.subCategory != null && branch.subCategory!.isNotEmpty)
                Text(
                  '• ${branch.subCategory!}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Method to build branch card for display in dialogs
  Widget _buildBranchCard(company_model.Branch branch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  branch.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0D1C4B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Phone', branch.phone),
          _buildDetailRow('Category', branch.category),
          if (branch.subCategory != null && branch.subCategory!.isNotEmpty)
            _buildDetailRow('Sub Category', branch.subCategory!),
          if (branch.description != null && branch.description!.isNotEmpty)
            _buildDetailRow('Description', branch.description!),
          if (branch.costPerCustomer != null)
            _buildDetailRow('Cost per Customer', '\$${branch.costPerCustomer!.toStringAsFixed(2)}'),
          _buildDetailRow('Address', '${branch.location.street}, ${branch.location.city}, ${branch.location.district}'),
          if (branch.images.isNotEmpty)
            _buildDetailRow('Images', '${branch.images.length} image(s)'),
          if (branch.videos != null && branch.videos!.isNotEmpty)
            _buildDetailRow('Videos', '${branch.videos!.length} video(s)'),
        ],
      ),
    );
  }

  // Method to show company details dialog
  void _showCompanyDetailsDialog(company_model.Company company) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(company.businessName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', company.email),
                _buildDetailRow('Full Name', company.fullname),
                _buildDetailRow('Category', company.category),
                if (company.subCategory != null && company.subCategory!.isNotEmpty)
                  _buildDetailRow('Sub Category', company.subCategory!),
                _buildDetailRow('Phone', company.contactInfo.phone),
                if (company.contactInfo.whatsApp != null && company.contactInfo.whatsApp!.isNotEmpty)
                  _buildDetailRow('WhatsApp', company.contactInfo.whatsApp!),
                if (company.contactInfo.website != null && company.contactInfo.website!.isNotEmpty)
                  _buildDetailRow('Website', company.contactInfo.website!),
                _buildDetailRow('Points', company.points.toString()),
                _buildDetailRow('Balance', '\$${company.balance.toStringAsFixed(2)}'),
                _buildDetailRow('Created', _formatDate(company.createdAt)),
                _buildDetailRow('Updated', _formatDate(company.updatedAt)),
                
                // Branches section
                if (company.branches != null && company.branches!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Branches (${company.branches!.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1C4B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...company.branches!.map((branch) => _buildBranchCard(branch)).toList(),
                ],
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

  // Method to show wholesaler details dialog
  void _showWholesalerDetailsDialog(Wholesaler wholesaler) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(wholesaler.businessName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', wholesaler.email),
                _buildDetailRow('Full Name', wholesaler.fullname),
                _buildDetailRow('Category', wholesaler.category),
                if (wholesaler.subCategory != null && wholesaler.subCategory!.isNotEmpty)
                  _buildDetailRow('Sub Category', wholesaler.subCategory!),
                _buildDetailRow('Phone', wholesaler.contactInfo.phone),
                if (wholesaler.contactInfo.whatsApp != null && wholesaler.contactInfo.whatsApp!.isNotEmpty)
                  _buildDetailRow('WhatsApp', wholesaler.contactInfo.whatsApp!),
                if (wholesaler.contactInfo.website != null && wholesaler.contactInfo.website!.isNotEmpty)
                  _buildDetailRow('Website', wholesaler.contactInfo.website!),
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

  // Method to show service provider details dialog
  void _showServiceProviderDetailsDialog(User serviceProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(serviceProvider.fullName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', serviceProvider.email),
                _buildDetailRow('User Type', _formatUserType(serviceProvider.userType)),
                if (serviceProvider.phone != null && serviceProvider.phone!.isNotEmpty)
                  _buildDetailRow('Phone', serviceProvider.phone!),
                if (serviceProvider.serviceProviderInfo != null) ...[
                  _buildDetailRow('Service Type', serviceProvider.serviceProviderInfo!.serviceType),
                  if (serviceProvider.serviceProviderInfo!.customServiceType != null && serviceProvider.serviceProviderInfo!.customServiceType!.isNotEmpty)
                    _buildDetailRow('Custom Service Type', serviceProvider.serviceProviderInfo!.customServiceType!),
                  if (serviceProvider.serviceProviderInfo!.description != null && serviceProvider.serviceProviderInfo!.description!.isNotEmpty)
                    _buildDetailRow('Description', serviceProvider.serviceProviderInfo!.description!),
                  _buildDetailRow('Rating', '${serviceProvider.serviceProviderInfo!.rating}/5'),
                  _buildDetailRow('Points', serviceProvider.serviceProviderInfo!.points.toString()),
                ],
                _buildDetailRow('Points', serviceProvider.points.toString()),
                _buildDetailRow('Created', _formatDate(serviceProvider.createdAt)),
                _buildDetailRow('Updated', _formatDate(serviceProvider.updatedAt)),
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
                if (salesperson.region != null && salesperson.region!.isNotEmpty)
                  _buildDetailRow('Region', salesperson.region!),
                _buildDetailRow('Commission', '${salesperson.commissionPercent}%'),
                if (salesperson.status != null && salesperson.status!.isNotEmpty)
                  _buildDetailRow('Status', salesperson.status!),
                if (salesperson.image != null && salesperson.image!.isNotEmpty)
                  _buildDetailRow('Image', salesperson.image!),
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