import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/services.dart'; 
import '../../../components/header.dart';
import '../../../utils/auth_manager.dart';
import '../../../services/salesperson_service.dart';
import '../../../services/api_constant.dart';
import '../../../services/location_service.dart';
import '../../../services/category_service.dart';
import 'package:geocoding/geocoding.dart';
import '../../../services/wholesaler_category_service.dart';
import '../../../services/service_provider_category_service.dart';
import '../../../models/salesperson_model.dart';
import '../../../models/withdrawal_model.dart';
import '../../../models/category.dart' as category_model;
import '../../../models/wholesaler_category.dart';
import '../../../models/service_provider_category.dart';
import '../../../components/simple_location_picker.dart';
import '../../../components/request_sent_popup.dart';

class SalespersonDashboard extends StatefulWidget {
  const SalespersonDashboard({Key? key}) : super(key: key);

  @override
  State<SalespersonDashboard> createState() => _SalespersonDashboardState();
}

class _SalespersonDashboardState extends State<SalespersonDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedTabIndex = 0; // 0 for Listings, 1 for Wallet, 2 for Referrals
  final SalespersonService _salespersonService = SalespersonService(baseUrl: ApiConstants.baseUrl);

  // Commission summary state
  bool _isCommissionLoading = false;
  String? _commissionError;
  double _totalCommission = 0.0;
  double _totalWithdrawn = 0.0;
  double _availableBalance = 0.0;

  // Commission/withdrawal history state
  bool _isHistoryLoading = false;
  String? _historyError;
  List<Commission> _commissions = [];
  List<Withdrawal> _withdrawals = [];

  // Referral data state
  bool _isReferralLoading = false;
  String? _referralError;
  String _referralCode = '';
  int _referralCount = 0;
  double _referralBalance = 0.0;
  String _referralLink = '';

  @override
  void initState() {
    super.initState();
    _fetchCommissionSummary();
    _fetchHistory();
    _fetchReferralData();
  }

  Future<void> _fetchCommissionSummary() async {
    setState(() {
      _isCommissionLoading = true;
      _commissionError = null;
    });
    
    try {
      final summary = await _salespersonService.getCommissionSummary();
      
      setState(() {
        _totalCommission = summary['totalCommission'] ?? 0.0;
        _totalWithdrawn = summary['totalWithdrawn'] ?? 0.0;
        _availableBalance = summary['availableBalance'] ?? 0.0;
        _isCommissionLoading = false;
      });
    } catch (e) {
      setState(() {
        _commissionError = e.toString();
        _isCommissionLoading = false;
      });
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isHistoryLoading = true;
      _historyError = null;
    });
    
    try {
      final data = await _salespersonService.getCommissionAndWithdrawalHistory();
      
      setState(() {
        _commissions = (data['commissions'] as List<Commission>?) ?? [];
        _withdrawals = (data['withdrawals'] as List<Withdrawal>?) ?? [];
        _isHistoryLoading = false;
      });
    } catch (e) {
      setState(() {
        _historyError = e.toString();
        _isHistoryLoading = false;
      });
    }
  }

  Future<void> _fetchReferralData() async {
    setState(() {
      _isReferralLoading = true;
      _referralError = null;
    });
    
    try {
      final data = await _salespersonService.getReferralData();
      
      setState(() {
        _referralCode = data['referralCode']?.toString() ?? '';
        _referralCount = (data['referralCount'] ?? 0).toInt();
        _referralBalance = (data['referralBalance'] ?? 0.0).toDouble();
        _referralLink = data['referralLink']?.toString() ?? '';
        _isReferralLoading = false;
      });
    } catch (e) {
      setState(() {
        _referralError = e.toString();
        _isReferralLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      final shouldLogout = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        await AuthManager.logout();
        if (mounted) {
          // Navigate back to the login page by popping all routes
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    
    // Refresh data when switching to wallet tab
    if (index == 1) {
      _fetchCommissionSummary();
      _fetchHistory();
    }
    // Refresh data when switching to referrals tab
    else if (index == 2) {
      _fetchReferralData();
    }
  }

  void _showAddNewDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AddNewDialog(salespersonService: _salespersonService);
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Options'),
          content: const Text('Filter functionality will be implemented here.'),
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

  void _showWithdrawDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => WithdrawDialog(
        availableBalance: _availableBalance,
        onWithdraw: (amount) async {
          try {
            final result = await _salespersonService.requestCommissionWithdrawal(amount);
            if (mounted) {
              _showRequestSentPopup(result);
              _fetchCommissionSummary();
              _fetchHistory(); // Refresh history after withdrawal
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Withdrawal failed: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showRequestSentPopup(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RequestSentPopup(
        title: 'Withdrawal Request Sent',
        message: 'Your withdrawal request for \$${result['amount'].toStringAsFixed(2)} has been sent to admin for approval.',
        withdrawalDetails: result,
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _safeCopyToClipboard(String text, String successMessage) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              logoPath: 'assets/logo/logo.png', // Update with your logo path
              scaffoldKey: _scaffoldKey,
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_selectedTabIndex == 0) ...[
                    GestureDetector(
                      onTap: _showAddNewDialog,
                      child: _buildActionButton(Icons.add, const Color(0xFF1E40AF)),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _showFilterDialog,
                      child: _buildActionButton(Icons.filter_alt_outlined, Colors.grey),
                    ),
                    const SizedBox(width: 12),
                  ],
                  GestureDetector(
                    onTap: _handleLogout,
                    child: _buildActionButton(Icons.logout, Colors.red),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Navigation Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _selectTab(0),
                    child: _buildTabButton('Listings', isActive: _selectedTabIndex == 0),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _selectTab(1),
                    child: _buildTabButton('Wallet', isActive: _selectedTabIndex == 1),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _selectTab(2),
                    child: _buildTabButton('Referrals', isActive: _selectedTabIndex == 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Content based on selected tab
            Expanded(
              child: _selectedTabIndex == 0 
                  ? _buildListingsContent() 
                  : _selectedTabIndex == 1 
                      ? _buildWalletContent() 
                      : _buildReferralsContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsContent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchListingsWithSubscription(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading listings...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading listings',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // This will trigger a rebuild and refetch
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.business_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No listings found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'There are no companies, wholesalers, or service providers available at the moment.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final listing = snapshot.data![index];
            
            // Debug: Print the listing data to see what's available
            print('Listing $index: $listing');
            print('Contact Person: ${listing['contactPerson']}');
            print('Contact Phone: ${listing['contactPhone']}');
            print('Email: ${listing['email']}');
            print('Business Name: ${listing['businessName']}');
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildListingCard(
                listing['businessName'] ?? '',
                listing['planTitle'] ?? '',
                listing['contactPhone'] ?? '',
                listing['contactPerson'] ?? '',
                listing['planPrice'] ?? 0.0,
                listing['logoUrl'],
                listing['type'] ?? '',
                listing['email'] ?? '',
              ),
            );
          },
        );
      },
    );
  }

  // Fetch raw companies data from API
  Future<List<Map<String, dynamic>>> _fetchRawCompanies() async {
    try {
      // Use the new raw method to get contactPerson and contactPhone fields
      final companiesData = await _salespersonService.getRawCompanies();
      
      print('Raw companies data received: ${companiesData.length} companies');
      if (companiesData.isNotEmpty) {
        print('First company data: ${companiesData.first}');
      }
      
      final List<Map<String, dynamic>> rawData = [];
      
      for (var companyData in companiesData) {
        if (companyData != null && companyData is Map<String, dynamic>) {
          final mappedData = {
            'id': companyData['id'] ?? '',
            'businessName': companyData['businessName'] ?? '',
            'category': companyData['category'] ?? '',
            'contactPerson': companyData['contactPerson'] ?? '',
            'contactPhone': companyData['contactPhone'] ?? '',
            'email': companyData['email'] ?? '',
            'logoURL': companyData['logoURL'] ?? '',
            'subscription': companyData['subscription'] ?? {
              'planTitle': '',
              'planPrice': 0,
              'hasActiveSubscription': false,
            },
          };
          
          print('Mapped company data: $mappedData');
          rawData.add(mappedData);
        }
      }
      
      print('Total mapped companies: ${rawData.length}');
      return rawData;
    } catch (e) {
      print('Error fetching raw companies: $e');
      return [];
    }
  }

  // Fetch raw wholesalers data from API
  Future<List<Map<String, dynamic>>> _fetchRawWholesalers() async {
    try {
      // Use the new raw method to get contactPerson and contactPhone fields
      final wholesalersData = await _salespersonService.getRawWholesalers();
      
      print('Raw wholesalers data received: ${wholesalersData.length} wholesalers');
      if (wholesalersData.isNotEmpty) {
        print('First wholesaler data: ${wholesalersData.first}');
      }
      
      final List<Map<String, dynamic>> rawData = [];
      
      for (var wholesalerData in wholesalersData) {
        if (wholesalerData != null && wholesalerData is Map<String, dynamic>) {
          rawData.add({
            'id': wholesalerData['id'] ?? '',
            'businessName': wholesalerData['businessName'] ?? '',
            'category': wholesalerData['category'] ?? '',
            'contactPerson': wholesalerData['contactPerson'] ?? '',
            'contactPhone': wholesalerData['contactPhone'] ?? '',
            'email': wholesalerData['email'] ?? '',
            'logoURL': wholesalerData['logoURL'] ?? '',
            'subscription': wholesalerData['subscription'] ?? {
              'planTitle': '',
              'planPrice': 0,
              'hasActiveSubscription': false,
            },
          });
        }
      }
      
      print('Total mapped wholesalers: ${rawData.length}');
      return rawData;
    } catch (e) {
      print('Error fetching raw wholesalers: $e');
      return [];
    }
  }

  // Fetch raw service providers data from API
  Future<List<Map<String, dynamic>>> _fetchRawServiceProviders() async {
    try {
      // Use the new raw method to get contactPerson and contactPhone fields
      final serviceProvidersData = await _salespersonService.getServiceProviders();
      
      print('Raw service providers data received: ${serviceProvidersData.length} service providers');
      if (serviceProvidersData.isNotEmpty) {
        print('First service provider data: ${serviceProvidersData.first}');
      }
      
      final List<Map<String, dynamic>> rawData = [];
      for (var sp in serviceProvidersData) {
        try {
          // Map the service provider data to match the expected format
          final mappedData = {
            'id': sp['id']?.toString() ?? '',
            'businessName': sp['businessName']?.toString() ?? '',
            'category': sp['category']?.toString() ?? '',
            'logoURL': sp['logoURL']?.toString() ?? '',
            'contactPerson': sp['contactPerson']?.toString() ?? '',
            'contactPhone': sp['contactPhone']?.toString() ?? '',
            'phone': sp['phone']?.toString() ?? '',
            'email': sp['email']?.toString() ?? '',
            'address': sp['address'] ?? {},
            'createdAt': sp['createdAt'],
            'status': sp['status']?.toString() ?? '',
            'user': sp['user'] ?? {},
            'subscription': sp['subscription'] ?? {},
          };
          rawData.add(mappedData);
        } catch (e) {
          print('Error mapping service provider data: $e');
          print('Problematic data: $sp');
        }
      }
      
      print('Total mapped service providers: ${rawData.length}');
      return rawData;
    } catch (e) {
      print('Error fetching raw service providers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchListingsWithSubscription() async {
    try {
      // Fetch raw API responses to get the actual data structure
      final companiesResponse = await _fetchRawCompanies();
      final wholesalersResponse = await _fetchRawWholesalers();
      final serviceProvidersResponse = await _fetchRawServiceProviders();
      
      print('Fetched ${companiesResponse.length} companies, ${wholesalersResponse.length} wholesalers, and ${serviceProvidersResponse.length} service providers');
      
      final List<Map<String, dynamic>> allListings = [];
      
      // Process companies from raw API response
      for (var companyData in companiesResponse) {
        // Validate company data
        if (companyData['businessName']?.toString().isEmpty ?? true) {
          print('Warning: Company has empty business name: ${companyData['id']}');
          continue;
        }
        
        // Extract subscription data if available
        String planTitle = '';
        double planPrice = 0.0;
        
        if (companyData['subscription'] != null) {
          final subscription = companyData['subscription'] as Map<String, dynamic>;
          print('Company subscription data: $subscription');
          
          planTitle = subscription['planTitle']?.toString().isNotEmpty == true 
              ? subscription['planTitle'] 
              : '${companyData['category']} Plan';
          planPrice = (subscription['planPrice'] ?? 0).toDouble();
          
          print('Extracted planTitle: $planTitle, planPrice: $planPrice');
        } else {
          print('No subscription data found for company: ${companyData['businessName']}');
        }
        
        final listingData = {
          'businessName': companyData['businessName'] ?? '',
          'contactPerson': companyData['contactPerson'] ?? 'N/A',
          'contactPhone': companyData['contactPhone'] ?? 'N/A',
          'email': companyData['email'] ?? 'N/A',
          'category': companyData['category'] ?? '',
          'logoUrl': companyData['logoURL'] ?? '',
          'planTitle': planTitle,
          'planPrice': planPrice,
          'type': 'company',
        };
        
        // Debug: Print company data
        print('Company data: $listingData');
        
        allListings.add(listingData);
      }
      
      // Process wholesalers from raw API response
      for (var wholesalerData in wholesalersResponse) {
        // Validate wholesaler data
        if (wholesalerData['businessName']?.toString().isEmpty ?? true) {
          print('Warning: Wholesaler has empty business name: ${wholesalerData['id']}');
          continue;
        }
        
        // Extract subscription data if available
        String planTitle = '';
        double planPrice = 0.0;
        
        if (wholesalerData['subscription'] != null) {
          final subscription = wholesalerData['subscription'] as Map<String, dynamic>;
          print('Wholesaler subscription data: $subscription');
          
          planTitle = subscription['planTitle']?.toString().isNotEmpty == true 
              ? subscription['planTitle'] 
              : '${wholesalerData['category']} Plan';
          planPrice = (subscription['planPrice'] ?? 0).toDouble();
          
          print('Extracted planTitle: $planTitle, planPrice: $planPrice');
        } else {
          print('No subscription data found for wholesaler: ${wholesalerData['businessName']}');
        }
        
        final listingData = {
          'businessName': wholesalerData['businessName'] ?? '',
          'contactPerson': wholesalerData['contactPerson'] ?? 'N/A',
          'contactPhone': wholesalerData['contactPhone'] ?? 'N/A',
          'email': wholesalerData['email'] ?? 'N/A',
          'category': wholesalerData['category'] ?? '',
          'logoUrl': wholesalerData['logoURL'] ?? '',
          'planTitle': planTitle,
          'planPrice': planPrice,
          'type': 'wholesaler',
        };
        
        // Debug: Print wholesaler data
        print('Wholesaler data: $listingData');
        
        allListings.add(listingData);
      }
      
      // Process service providers from raw API response
      for (var serviceProviderData in serviceProvidersResponse) {
        // Validate service provider data
        if (serviceProviderData['businessName']?.toString().isEmpty ?? true) {
          print('Warning: Service provider has empty business name: ${serviceProviderData['id']}');
          continue;
        }
        
        // Extract subscription data if available
        String planTitle = '';
        double planPrice = 0.0;
        
        if (serviceProviderData['subscription'] != null) {
          final subscription = serviceProviderData['subscription'] as Map<String, dynamic>;
          print('Service provider subscription data: $subscription');
          
          planTitle = subscription['planTitle']?.toString().isNotEmpty == true 
              ? subscription['planTitle'] 
              : '${serviceProviderData['category']} Plan';
          planPrice = (subscription['planPrice'] ?? 0).toDouble();
          
          print('Extracted planTitle: $planTitle, planPrice: $planPrice');
        } else {
          print('No subscription data found for service provider: ${serviceProviderData['businessName']}');
        }
        
        final listingData = {
          'businessName': serviceProviderData['businessName'] ?? '',
          'contactPerson': serviceProviderData['contactPerson'] ?? 'N/A',
          'contactPhone': serviceProviderData['contactPhone'] ?? 'N/A',
          'email': serviceProviderData['email'] ?? 'N/A',
          'category': serviceProviderData['category'] ?? '',
          'logoUrl': serviceProviderData['logoURL'] ?? '',
          'planTitle': planTitle,
          'planPrice': planPrice,
          'type': 'service_provider',
        };
        
        // Debug: Print service provider data
        print('Service provider data: $listingData');
        
        allListings.add(listingData);
      }
      
      print('Total listings created: ${allListings.length}');
      return allListings;
    } catch (e) {
      print('Error fetching listings: $e');
      rethrow;
    }
  }

  Widget _buildWalletContent() {
    if (_isCommissionLoading || _isHistoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_commissionError != null) {
      return Center(
        child: Text(
          'Error: $_commissionError',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_historyError != null) {
      return Center(
        child: Text(
          'Error: $_historyError',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchCommissionSummary();
        await _fetchHistory();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
        
        // Total Commission Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1E90FF), Color(0xFF1E40AF)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Commission',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _totalCommission.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Balance and Withdraws Row
        Row(
          children: [
            // Balance Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4169E1), Color(0xFF1E40AF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Balance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
_availableBalance.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Total Withdraws Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E90FF), Color(0xFF4169E1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.call_made,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Total Withdraws',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
'-${_totalWithdrawn.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Withdraw Button
        Center(
          child: SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _showWithdrawDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Withdraw',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // History Section
        const Text(
          'History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 16),

        if (_commissions.isEmpty && _withdrawals.isEmpty)
          const Center(child: Text('No history found'))
        else
          ..._buildHistoryItems(),
      ],
    ),
  );
  }

  Widget _buildReferralsContent() {
    if (_isReferralLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_referralError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $_referralError',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchReferralData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchReferralData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Referral Code Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.share,
                        color: Color(0xFF1E40AF),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Your Referral Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E40AF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1E40AF).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _referralCode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                              letterSpacing: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _safeCopyToClipboard(
                            _referralCode,
                            'Referral code copied to clipboard!',
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E40AF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.copy,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Referral Link Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.link,
                        color: Color(0xFF059669),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Referral Link',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF059669).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _referralLink,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF059669),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _safeCopyToClipboard(
                            _referralLink,
                            'Referral link copied to clipboard!',
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.copy,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Referral Stats Section
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.people,
                          color: Color(0xFFDC2626),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_referralCount',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const Text(
                          'Referrals',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFF7C3AED),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${_referralBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const Text(
                          'Referral Balance',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // How it works section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.help_outline,
                        color: Color(0xFF6B7280),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'How Referrals Work',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '1. Share your referral code or link with potential customers\n'
                    '2. When they register using your code, you earn a commission\n'
                    '3. Track your referrals and earnings in this dashboard\n'
                    '4. Referral balance can be withdrawn to your wallet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.5,
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

  List<Widget> _buildHistoryItems() {
    final List<Map<String, dynamic>> allItems = [];
    
    // Add commissions
    for (final commission in _commissions) {
      allItems.add({
        'type': 'Deposit',
        'date': commission.createdAt,
        'amount': commission.amount,
        'isWithdraw': false,
      });
    }
    
    // Add withdrawals
    for (final withdrawal in _withdrawals) {
      allItems.add({
        'type': 'Withdrawn',
        'date': withdrawal.createdAt,
        'amount': withdrawal.amount,
        'isWithdraw': true,
      });
    }
    
    // Sort by date descending
    allItems.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    
    return allItems.map((item) {
      final type = item['type'] as String;
      final date = item['date'] as DateTime;
      final amount = item['amount'] as double;
      final isWithdraw = item['isWithdraw'] as bool;
      final color = isWithdraw ? Colors.red : Colors.green;
      final amountStr = (isWithdraw ? '-' : '+') + ' \$ ' + amount.abs().toStringAsFixed(2);
      
      // Format date
      final displayDate = '${date.day} ${_getMonthName(date.month)} ${date.year}';
      
      return _buildHistoryItem(type, displayDate, amountStr, color);
    }).toList();
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildHistoryItem(String type, String date, String amount, Color amountColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: type == 'Withdrawn' ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, {required bool isActive}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E40AF) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color == Colors.grey ? Colors.grey.withOpacity(0.1) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color == Colors.grey ? Colors.grey.withOpacity(0.3) : color.withOpacity(0.3),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildListingCard(
      String businessName,
      String planTitle,
      String contactPhone,
      String contactPerson,
      double planPrice,
      String? logoUrl,
      String type,
      String email,
      ) {
    // Construct the full image URL
    final fullImageUrl = logoUrl != null && logoUrl.isNotEmpty
        ? '${ApiConstants.baseUrl}/$logoUrl'
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Business Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: fullImageUrl != null
                  ? Image.network(
                      fullImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E40AF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: Color(0xFF1E40AF),
                            size: 30,
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E40AF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Color(0xFF1E40AF),
                        size: 30,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 16),

          // Business Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business Name and Type
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        businessName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _getTypeColor(type).withOpacity(0.3)),
                      ),
                      child: Text(
                        _getTypeLabel(type),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _getTypeColor(type),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),

                // Subscription Plan Title and Price
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E40AF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF1E40AF).withOpacity(0.3)),
                        ),
                        child: Text(
                          planTitle.isNotEmpty ? planTitle : 'No Plan',
                          style: const TextStyle(
                            color: Color(0xFF1E40AF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: Text(
                        '\$${planPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: const Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

               


                // Contact Person
                if (contactPerson.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          contactPerson,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 4),

                // Contact Phone
                if (contactPhone.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          contactPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                // Email
                if (email.isNotEmpty && email != 'N/A')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Show "Contact information not available" only if all contact fields are empty
                if (contactPerson.isEmpty && contactPhone.isEmpty && (email.isEmpty || email == 'N/A'))
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Contact information not available',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            fontStyle: FontStyle.italic,
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
    );
  }

  // Helper method to get type color
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'company':
        return const Color(0xFF1E40AF); // Blue
      case 'wholesaler':
        return const Color(0xFF059669); // Green
      case 'service_provider':
        return const Color(0xFFDC2626); // Red
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  // Helper method to get type label
  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'company':
        return 'Company';
      case 'wholesaler':
        return 'Wholesaler';
      case 'service_provider':
        return 'Service Provider';
      default:
        return 'Unknown';
    }
  }
}

class AddNewDialog extends StatefulWidget {
  final SalespersonService salespersonService;
  
  const AddNewDialog({
    Key? key,
    required this.salespersonService,
  }) : super(key: key);

  @override
  State<AddNewDialog> createState() => _AddNewDialogState();
}

class _AddNewDialogState extends State<AddNewDialog> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _locationAddressController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _additionalPhoneController = TextEditingController();
  final TextEditingController _additionalEmailController = TextEditingController();

  String _selectedType = 'Company';
  String _selectedIndustry = '';
  String _selectedSubcategory = '';
  String _selectedCountryCode = '+961';
  String? _selectedCountry;
  String? _selectedDistrict;
  String? _selectedCity;
  String? _selectedGovernorate;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _hasAdditionalPhone = false;
  bool _hasAdditionalEmail = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _emailErrorMessage;
  String? _phoneErrorMessage;
  File? _logoFile;
  Uint8List? _logoBytes;

  // Category-related state
  final CategoryApiService _categoryService = CategoryApiService();
  final WholesalerCategoryService _wholesalerCategoryService = WholesalerCategoryService();
  final ServiceProviderCategoryService _serviceProviderCategoryService = ServiceProviderCategoryService();
  List<category_model.Category> _categories = [];
  List<WholesalerCategory> _wholesalerCategories = [];
  List<ServiceProviderCategory> _serviceProviderCategories = [];
  bool _isCategoriesLoading = false;
  String? _categoriesError;

  final ImagePicker _picker = ImagePicker();
  
  // Debounce timers for existence checking
  Timer? _emailCheckTimer;
  Timer? _phoneCheckTimer;

  final List<String> _countryCodes = [
    '+961',
    '+1',
    '+44',
    '+971',
    '+966',
  ];

  @override
  void initState() {
    super.initState();
    _checkExistence();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isCategoriesLoading = true;
      _categoriesError = null;
    });

    try {
      if (_selectedType == 'Wholesaler') {
        // Fetch wholesaler categories
        final response = await _wholesalerCategoryService.getAllWholesalerCategories();
        if (response.status == 200 && response.categories.isNotEmpty) {
          setState(() {
            _wholesalerCategories = response.categories;
            _categories = []; // Clear regular categories
            _selectedIndustry = response.categories.first.name;
            _selectedSubcategory = response.categories.first.subcategories.isNotEmpty 
                ? response.categories.first.subcategories.first 
                : '';
            _isCategoriesLoading = false;
          });
        } else {
          setState(() {
            _wholesalerCategories = response.categories; // Even if empty, set the list
            _categories = []; // Clear regular categories
            _wholesalerCategories = []; // Clear wholesaler categories
            _serviceProviderCategories = []; // Clear service provider categories
            _selectedIndustry = ''; // No category selected
            _selectedSubcategory = ''; // No subcategory
            _isCategoriesLoading = false;
            _categoriesError = null; // No error, just empty categories
          });
        }
              } else if (_selectedType == 'Service Provider') {
          // Fetch service provider categories
          final response = await _serviceProviderCategoryService.getAllServiceProviderCategories();
          if (response.status == 200 && response.categories.isNotEmpty) {
            setState(() {
              _serviceProviderCategories = response.categories;
              _categories = []; // Clear regular categories
              _wholesalerCategories = []; // Clear wholesaler categories
              _selectedIndustry = response.categories.first.name;
              _selectedSubcategory = ''; // Service providers don't have subcategories
              _isCategoriesLoading = false;
            });
          } else {
            setState(() {
              _serviceProviderCategories = response.categories; // Even if empty, set the list
              _categories = []; // Clear regular categories
              _wholesalerCategories = []; // Clear wholesaler categories
              _selectedIndustry = ''; // No category selected
              _selectedSubcategory = ''; // No subcategory
              _isCategoriesLoading = false;
              _categoriesError = null; // No error, just empty categories
            });
          }
              } else {
          // Fetch regular categories for Company
          final response = await _categoryService.getAllCategories();
          if (response.status == 200 && response.categories.isNotEmpty) {
            setState(() {
              _categories = response.categories;
              _wholesalerCategories = []; // Clear wholesaler categories
              _serviceProviderCategories = []; // Clear service provider categories
              _selectedIndustry = response.categories.first.name;
              _selectedSubcategory = response.categories.first.subcategories.isNotEmpty 
                  ? response.categories.first.subcategories.first 
                  : '';
              _isCategoriesLoading = false;
            });
          } else {
            setState(() {
              _categories = response.categories; // Even if empty, set the list
              _wholesalerCategories = []; // Clear wholesaler categories
              _serviceProviderCategories = []; // Clear service provider categories
              _selectedIndustry = ''; // No category selected
              _selectedSubcategory = ''; // No subcategory
              _isCategoriesLoading = false;
              _categoriesError = null; // No error, just empty categories
            });
          }
        }
    } catch (e) {
      setState(() {
        _categoriesError = 'Failed to load categories: $e';
        _isCategoriesLoading = false;
      });
    }
  }

  // Get subcategories for the selected category based on business type
  List<String> getSubcategoriesForCategory(String categoryName) {
    if (_selectedType == 'Wholesaler') {
      final category = _wholesalerCategories.firstWhere(
        (cat) => cat.name == categoryName,
        orElse: () => WholesalerCategory(name: '', subcategories: []),
      );
      return category.subcategories;
    } else if (_selectedType == 'Service Provider') {
      // Service providers don't have subcategories
      return [];
    } else {
      final category = _categories.firstWhere(
        (cat) => cat.name == categoryName,
        orElse: () => category_model.Category(name: '', subcategories: []),
      );
      return category.subcategories;
    }
  }

  // Get all available categories for the current business type
  List<dynamic> getAvailableCategories() {
    if (_selectedType == 'Wholesaler') {
      return _wholesalerCategories;
    } else if (_selectedType == 'Service Provider') {
      return _serviceProviderCategories;
    } else {
      return _categories;
    }
  }

  // Get category names for the current business type
  List<String> getCategoryNames() {
    if (_selectedType == 'Wholesaler') {
      return _wholesalerCategories.map((cat) => cat.name).toList();
    } else if (_selectedType == 'Service Provider') {
      return _serviceProviderCategories.map((cat) => cat.name).toList();
    } else {
      return _categories.map((cat) => cat.name).toList();
    }
  }

  // Update subcategory when category changes
  void _onCategoryChanged(String? newCategory) {
    if (newCategory != null) {
      setState(() {
        _selectedIndustry = newCategory;
        final subcategories = getSubcategoriesForCategory(newCategory);
        _selectedSubcategory = subcategories.isNotEmpty ? subcategories.first : '';
      });
    }
  }

  @override
  void dispose() {
    _emailCheckTimer?.cancel();
    _phoneCheckTimer?.cancel();
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _locationAddressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _additionalPhoneController.dispose();
    _additionalEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _logoBytes = bytes;
            _logoFile = null; // Ensure _logoFile is null on web
          });
        } else {
          setState(() {
            _logoFile = File(image.path);
            _logoBytes = null; // Ensure _logoBytes is null on non-web
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  // Method to find the nearest location from coordinates using reverse geocoding
  Future<Map<String, String?>> _findNearestLocation(double lat, double lng) async {
    try {
      // Use reverse geocoding to get the actual location information
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        final List<String> availableCountries = LocationService.getCountries();
        final String fallbackCountry = availableCountries.isNotEmpty ? availableCountries.first : 'Lebanon';

        final String matchedCountry = _matchLocationValue(place.country, availableCountries) ?? fallbackCountry;
        final bool usesGovernorateStructure = LocationService.usesGovernorateStructure(matchedCountry);

        final List<String> firstLevelOptions = usesGovernorateStructure
            ? LocationService.getGovernorates(matchedCountry)
            : LocationService.getDistricts(matchedCountry);

        String? matchedDistrict;
        for (final candidate in [
          place.administrativeArea,
          place.subAdministrativeArea,
          place.locality,
          place.subLocality,
        ]) {
          matchedDistrict = _matchLocationValue(candidate, firstLevelOptions);
          if (matchedDistrict != null) break;
        }
        matchedDistrict ??= _getDefaultFirstLevel(matchedCountry);

        List<String> secondLevelOptions = [];
        if (matchedDistrict != null) {
          secondLevelOptions = usesGovernorateStructure
              ? LocationService.getDistrictsByGovernorate(matchedCountry, matchedDistrict)
              : LocationService.getCities(matchedCountry, matchedDistrict);
        }

        String? matchedCity;
        for (final candidate in [
          place.locality,
          place.subLocality,
          place.street,
          place.thoroughfare,
          place.name,
        ]) {
          matchedCity = _matchLocationValue(candidate, secondLevelOptions);
          if (matchedCity != null) break;
        }
        if (matchedCity == null && secondLevelOptions.isNotEmpty) {
          matchedCity = secondLevelOptions.first;
        }

        List<String> thirdLevelOptions = [];
        if (matchedCity != null && matchedDistrict != null) {
          thirdLevelOptions = usesGovernorateStructure
              ? LocationService.getStreetsByGovernorate(matchedCountry, matchedDistrict, matchedCity)
              : LocationService.getGovernoratesLegacy(matchedCountry, matchedDistrict, matchedCity);
        }

        String? matchedGovernorate;
        for (final candidate in [
          place.street,
          place.subLocality,
          place.thoroughfare,
          place.name,
        ]) {
          matchedGovernorate = _matchLocationValue(candidate, thirdLevelOptions);
          if (matchedGovernorate != null) break;
        }
        if (matchedGovernorate == null && matchedCity != null && matchedDistrict != null) {
          matchedGovernorate = _getDefaultThirdLevel(matchedCountry, matchedDistrict, matchedCity);
        }
        
        return {
          'country': matchedCountry,
          'district': matchedDistrict ?? _getDefaultFirstLevel(matchedCountry) ?? matchedCountry,
          'city': matchedCity ??
              (matchedDistrict != null
                  ? _getDefaultSecondLevel(matchedCountry, matchedDistrict) ?? matchedDistrict
                  : matchedCountry),
          'governorate': matchedGovernorate,
        };
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
    }
    
    // Fallback to default values if geocoding fails
    return {
      'country': 'Lebanon',
      'district': 'Beirut',
      'city': 'Beirut',
      'governorate': null,
    };
  }

  // Helper method to validate location values against available dropdown items
  Map<String, String?> _validateLocationValues(String? country, String? district, String? city, String? governorate) {
    // Validate country
    final availableCountries = LocationService.getCountries();
    String? validatedCountry = availableCountries.contains(country) ? country : null;
    if (validatedCountry == null && availableCountries.isNotEmpty) {
      validatedCountry = availableCountries.first;
    }

    // Validate district/governorate
    String? validatedDistrict;
    if (validatedCountry != null) {
      final availableDistricts = LocationService.getGovernorates(validatedCountry);
      validatedDistrict = availableDistricts.contains(district) ? district : null;
      if (validatedDistrict == null && availableDistricts.isNotEmpty) {
        validatedDistrict = availableDistricts.first;
      }
    }

    // Validate city
    String? validatedCity;
    if (validatedCountry != null && validatedDistrict != null) {
      final availableCities = LocationService.getDistrictsByGovernorate(validatedCountry, validatedDistrict);
      validatedCity = availableCities.contains(city) ? city : null;
      if (validatedCity == null && availableCities.isNotEmpty) {
        validatedCity = availableCities.first;
      }
    }

    // Validate governorate/street
    String? validatedGovernorate;
    if (validatedCountry != null && validatedDistrict != null && validatedCity != null) {
      final bool usesGovernorateStructure = LocationService.usesGovernorateStructure(validatedCountry);
      final List<String> availableGovernorates = usesGovernorateStructure
          ? LocationService.getStreetsByGovernorate(validatedCountry, validatedDistrict, validatedCity)
          : LocationService.getGovernoratesLegacy(validatedCountry, validatedDistrict, validatedCity);
      if (availableGovernorates.contains(governorate)) {
        validatedGovernorate = governorate;
      } else if (availableGovernorates.isNotEmpty) {
        validatedGovernorate = availableGovernorates.first;
      }
    }

    return {
      'country': validatedCountry,
      'district': validatedDistrict,
      'city': validatedCity,
      'governorate': validatedGovernorate,
    };
  }

  void _clearLocation() {
    setState(() {
      _locationAddressController.clear();
      _latController.clear();
      _lngController.clear();
      _selectedCountry = null;
      _selectedDistrict = null;
      _selectedCity = null;
      _selectedGovernorate = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location cleared! Please select a new location.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String? _matchLocationValue(String? rawValue, List<String> options) {
    if (rawValue == null) return null;
    final normalized = rawValue.toLowerCase().trim();
    if (normalized.isEmpty) return null;

    for (final option in options) {
      if (option.toLowerCase() == normalized) {
        return option;
      }
    }

    for (final option in options) {
      final lower = option.toLowerCase();
      if (normalized.contains(lower) || lower.contains(normalized)) {
        return option;
      }
    }

    return null;
  }

  String? _getDefaultFirstLevel(String country) {
    final bool usesGovernorateStructure = LocationService.usesGovernorateStructure(country);
    final List<String> options = usesGovernorateStructure
        ? LocationService.getGovernorates(country)
        : LocationService.getDistricts(country);
    return options.isNotEmpty ? options.first : null;
  }

  String? _getDefaultSecondLevel(String country, String district) {
    final bool usesGovernorateStructure = LocationService.usesGovernorateStructure(country);
    final List<String> options = usesGovernorateStructure
        ? LocationService.getDistrictsByGovernorate(country, district)
        : LocationService.getCities(country, district);
    return options.isNotEmpty ? options.first : null;
  }

  String? _getDefaultThirdLevel(String country, String district, String city) {
    final bool usesGovernorateStructure = LocationService.usesGovernorateStructure(country);
    final List<String> options = usesGovernorateStructure
        ? LocationService.getStreetsByGovernorate(country, district, city)
        : LocationService.getGovernoratesLegacy(country, district, city);
    return options.isNotEmpty ? options.first : null;
  }

  void _showLocationPicker() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLocationPicker(
          initialLat: _latController.text.isNotEmpty 
              ? double.tryParse(_latController.text) 
              : null,
          initialLng: _lngController.text.isNotEmpty 
              ? double.tryParse(_lngController.text) 
              : null,
          onLocationSelected: (double lat, double lng, String address) async {
            setState(() {
              _latController.text = lat.toString();
              _lngController.text = lng.toString();
              _locationAddressController.text = address;
            });
            
            // Auto-fill the location dropdowns based on coordinates
            final locationInfo = await _findNearestLocation(lat, lng);
            
            // Validate and correct the location values to match available dropdown items
            final validatedLocation = _validateLocationValues(
              locationInfo['country'],
              locationInfo['district'],
              locationInfo['city'],
              locationInfo['governorate'],
            );
            
            setState(() {
              _selectedCountry = validatedLocation['country'];
              _selectedDistrict = validatedLocation['district'];
              _selectedCity = validatedLocation['city'];
              _selectedGovernorate = validatedLocation['governorate'];
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location selected! Address fields have been auto-filled.'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _checkExistence() async {
    // Check when email is entered with debouncing (only if email is provided)
    _emailController.addListener(() {
      _emailCheckTimer?.cancel();
      _emailCheckTimer = Timer(const Duration(milliseconds: 500), () async {
        if (_emailController.text.isNotEmpty && _emailController.text.contains('@')) {
          final existsDetails = await widget.salespersonService.checkEmailOrPhoneExistsDetailed(
            _emailController.text,
            null,
          );
          if (existsDetails['exists'] == true && mounted) {
            List<String> existingTypes = [];
            
            if (existsDetails['userExists'] == true) {
              existingTypes.add('User');
            }
            if (existsDetails['companyExists'] == true) {
              existingTypes.add('Company');
            }
            if (existsDetails['wholesalerExists'] == true) {
              existingTypes.add('Wholesaler');
            }
            if (existsDetails['serviceProviderExists'] == true) {
              existingTypes.add('Service Provider');
            }
            
            setState(() {
              _emailErrorMessage = 'Email is already exists';
            });
          } else if (mounted) {
            setState(() {
              _emailErrorMessage = null;
            });
          }
        } else if (mounted) {
          setState(() {
            _emailErrorMessage = null;
          });
        }
      });
    });

    // Check when phone is entered with debouncing
    _phoneController.addListener(() {
      _phoneCheckTimer?.cancel();
      _phoneCheckTimer = Timer(const Duration(milliseconds: 500), () async {
        if (_phoneController.text.isNotEmpty && _phoneController.text.length >= 8) {
          final existsDetails = await widget.salespersonService.checkEmailOrPhoneExistsDetailed(
            null,
            '$_selectedCountryCode${_phoneController.text}',
          );
          if (existsDetails['exists'] == true && mounted) {
            List<String> existingTypes = [];
            
            if (existsDetails['userExists'] == true) {
              existingTypes.add('User');
            }
            if (existsDetails['companyExists'] == true) {
              existingTypes.add('Company');
            }
            if (existsDetails['wholesalerExists'] == true) {
              existingTypes.add('Wholesaler');
            }
            if (existsDetails['serviceProviderExists'] == true) {
              existingTypes.add('Service Provider');
            }
            
            setState(() {
              _phoneErrorMessage = 'Phone number is already exists';
            });
          } else if (mounted) {
            setState(() {
              _phoneErrorMessage = null;
            });
          }
        } else if (mounted) {
          setState(() {
            _phoneErrorMessage = null;
          });
        }
      });
    });
  }

  Future<void> _handleSubmit() async {
    // Validate form
    if (_businessNameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _contactPersonController.text.isEmpty ||
        _contactPhoneController.text.isEmpty ||
        _selectedIndustry.isEmpty ||
        _selectedCountry == null ||
        _selectedDistrict == null ||
        _selectedCity == null ||
        _selectedGovernorate == null ) {
      setState(() {
        _errorMessage = 'All fields are required including industry category (email is optional)';
        _emailErrorMessage = null;
        _phoneErrorMessage = null;
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _emailErrorMessage = null;
        _phoneErrorMessage = null;
      });
      return;
    }

    // Validate lat and lng if provided
    if (_latController.text.isNotEmpty) {
      final lat = double.tryParse(_latController.text);
      if (lat == null || lat < -90 || lat > 90) {
        setState(() {
          _errorMessage = 'Invalid lat value. Must be between -90 and 90';
          _emailErrorMessage = null;
          _phoneErrorMessage = null;
        });
        return;
      }
    }

    if (_lngController.text.isNotEmpty) {
      final lng = double.tryParse(_lngController.text);
      if (lng == null || lng < -180 || lng > 180) {
        setState(() {
          _errorMessage = 'Invalid lng value. Must be between -180 and 180';
          _emailErrorMessage = null;
          _phoneErrorMessage = null;
        });
        return;
      }
    }

    // Check if email or phone exists before submission (only if email is provided)
    if (_emailController.text.isNotEmpty) {
      final existsDetails = await widget.salespersonService.checkEmailOrPhoneExistsDetailed(
        _emailController.text,
        '$_selectedCountryCode${_phoneController.text}',
      );

      if (existsDetails['exists'] == true) {
        // Build a detailed error message
        List<String> existingTypes = [];
        
        if (existsDetails['userExists'] == true) {
          existingTypes.add('User');
        }
        if (existsDetails['companyExists'] == true) {
          existingTypes.add('Company');
        }
        if (existsDetails['wholesalerExists'] == true) {
          existingTypes.add('Wholesaler');
        }
        if (existsDetails['serviceProviderExists'] == true) {
          existingTypes.add('Service Provider');
        }
        
        String errorMessage = 'Email or phone number is already exists';
        
        setState(() {
          _errorMessage = errorMessage;
          _emailErrorMessage = null;
          _phoneErrorMessage = null;
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emailErrorMessage = null;
      _phoneErrorMessage = null;
    });

    try {
      print('Attempting to create ${_selectedType.toLowerCase()}...');
      print('Business Name: ${_businessNameController.text}');
      print('Category: $_selectedIndustry');
      print('Subcategory: ${_selectedSubcategory.isNotEmpty ? _selectedSubcategory : 'Not provided'}');
      print('Email: ${_emailController.text.isNotEmpty ? _emailController.text : 'Not provided (optional)'}');
      print('Phone: $_selectedCountryCode${_phoneController.text}');
      print('Logo file selected: ${_logoFile != null}');

      // Parse lat and lng
      double? lat;
      double? lng;
      
      if (_latController.text.isNotEmpty) {
        lat = double.tryParse(_latController.text);
      }
      if (_lngController.text.isNotEmpty) {
        lng = double.tryParse(_lngController.text);
      }

      switch (_selectedType) {
        case 'Company':
          // Combine additional email with main email if provided
          String combinedEmail = _emailController.text;
          if (_hasAdditionalEmail && _additionalEmailController.text.isNotEmpty) {
            if (combinedEmail.isNotEmpty) {
              combinedEmail += ', ${_additionalEmailController.text}';
            } else {
              combinedEmail = _additionalEmailController.text;
            }
          }
          
          // Combine additional phone with contact phone if provided
          String combinedContactPhone = _contactPhoneController.text;
          if (_hasAdditionalPhone && _additionalPhoneController.text.isNotEmpty) {
            if (combinedContactPhone.isNotEmpty) {
              combinedContactPhone += ', $_selectedCountryCode${_additionalPhoneController.text}';
            } else {
              combinedContactPhone = '$_selectedCountryCode${_additionalPhoneController.text}';
            }
          }
          
          await widget.salespersonService.createCompany(
            businessName: _businessNameController.text,
            category: _selectedIndustry,
            subcategory: _selectedSubcategory.isNotEmpty ? _selectedSubcategory : null,
            email: combinedEmail,
            phone: '$_selectedCountryCode${_phoneController.text}',
            password: _passwordController.text,
            contactPerson: _contactPersonController.text,
            contactPhone: combinedContactPhone,
            country: _selectedCountry!,
            district: _selectedDistrict!,
            city: _selectedCity!,
            governorate: _selectedGovernorate!,
            lat: lat,
            lng: lng,
            logoFile: _logoFile,
          );
          break;
        case 'Wholesaler':
          // Combine additional email with main email if provided
          String combinedEmail = _emailController.text;
          if (_hasAdditionalEmail && _additionalEmailController.text.isNotEmpty) {
            if (combinedEmail.isNotEmpty) {
              combinedEmail += ', ${_additionalEmailController.text}';
            } else {
              combinedEmail = _additionalEmailController.text;
            }
          }
          
          // Combine additional phone with contact phone if provided
          String combinedContactPhone = _contactPhoneController.text;
          if (_hasAdditionalPhone && _additionalPhoneController.text.isNotEmpty) {
            if (combinedContactPhone.isNotEmpty) {
              combinedContactPhone += ', $_selectedCountryCode${_additionalPhoneController.text}';
            } else {
              combinedContactPhone = '$_selectedCountryCode${_additionalPhoneController.text}';
            }
          }
          
          await widget.salespersonService.createWholesaler(
            businessName: _businessNameController.text,
            category: _selectedIndustry,
            subcategory: _selectedSubcategory.isNotEmpty ? _selectedSubcategory : null,
            email: combinedEmail,
            phone: '$_selectedCountryCode${_phoneController.text}',
            password: _passwordController.text,
            contactPerson: _contactPersonController.text,
            contactPhone: combinedContactPhone,
            country: _selectedCountry!,
            district: _selectedDistrict!,
            city: _selectedCity!,
            governorate: _selectedGovernorate!,
            lat: lat,
            lng: lng,
            logoFile: _logoFile,
          );
          break;
        case 'Service Provider':
          // Combine additional email with main email if provided
          String combinedEmail = _emailController.text;
          if (_hasAdditionalEmail && _additionalEmailController.text.isNotEmpty) {
            if (combinedEmail.isNotEmpty) {
              combinedEmail += ', ${_additionalEmailController.text}';
            } else {
              combinedEmail = _additionalEmailController.text;
            }
          }
          
          // Combine additional phone with contact phone if provided
          String combinedContactPhone = _contactPhoneController.text;
          if (_hasAdditionalPhone && _additionalPhoneController.text.isNotEmpty) {
            if (combinedContactPhone.isNotEmpty) {
              combinedContactPhone += ', $_selectedCountryCode${_additionalPhoneController.text}';
            } else {
              combinedContactPhone = '$_selectedCountryCode${_additionalPhoneController.text}';
            }
          }
          
          await widget.salespersonService.createServiceProvider(
            businessName: _businessNameController.text,
            category: _selectedIndustry,
            email: combinedEmail,
            phone: '$_selectedCountryCode${_phoneController.text}',
            password: _passwordController.text,
            contactPerson: _contactPersonController.text,
            contactPhone: combinedContactPhone,
            country: _selectedCountry!,
            district: _selectedDistrict!,
            city: _selectedCity!,
            governorate: _selectedGovernorate!,
            lat: lat,
            lng: lng,
            logoFile: _logoFile,
          );
          break;
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedType.toLowerCase()} request sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error creating ${_selectedType.toLowerCase()}: $e');
      String errorMessage = e.toString();

      // Handle specific error cases
      if (errorMessage.contains('already exists')) {
        errorMessage = 'The email or phone number is already exists';
      } else if (errorMessage.contains('network')) {
        errorMessage = 'Network error: Please check your internet connection';
      }

      setState(() {
        _errorMessage = errorMessage;
        _emailErrorMessage = null;
        _phoneErrorMessage = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                const Text(
                  'Add New',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 20),

                // Type Selection Tabs
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedType = 'Company');
                          _fetchCategories(); // Refresh categories for company
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedType == 'Company'
                                ? const Color(0xFF1E40AF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Company',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedType == 'Company'
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedType = 'Wholesaler');
                          _fetchCategories(); // Refresh categories for wholesaler
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedType == 'Wholesaler'
                                ? const Color(0xFF1E40AF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Wholesaler',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedType == 'Wholesaler'
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedType = 'Service Provider');
                          _fetchCategories(); // Refresh categories for service provider
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedType == 'Service Provider'
                                ? const Color(0xFF1E40AF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Service Provider',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedType == 'Service Provider'
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Logo Upload
                GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _logoFile != null || _logoBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: kIsWeb && _logoBytes != null
                                ? Image.memory(
                                    _logoBytes!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person_outline,
                                        size: 30,
                                        color: Color(0xFF1E40AF),
                                      );
                                    },
                                  )
                                : (_logoFile != null ? Image.file(
                                    _logoFile!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person_outline,
                                        size: 30,
                                        color: Color(0xFF1E40AF),
                                      );
                                    },
                                  ) : const Icon(
                                        Icons.person_outline,
                                        size: 30,
                                        color: Color(0xFF1E40AF),
                                      )),
                          )
                        : const Icon(
                            Icons.person_outline,
                            size: 30,
                            color: Color(0xFF1E40AF),
                          ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Add Logo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // Business Name Field
                TextField(
                  controller: _businessNameController,
                  decoration: InputDecoration(
                    hintText: 'Business Name',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1E40AF)),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Industry Dropdown
                if (_isCategoriesLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading categories...'),
                      ],
                    ),
                  )
                else if (_categoriesError != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _categoriesError!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: _isCategoriesLoading 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh, color: Color(0xFF1E40AF)),
                          onPressed: _isCategoriesLoading ? null : _fetchCategories,
                          tooltip: 'Refresh categories',
                          iconSize: 20,
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedIndustry.isNotEmpty ? _selectedIndustry : null,
                              decoration: InputDecoration(
                                hintText: 'Select Industry Category',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF1E40AF)),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              items: getCategoryNames().isNotEmpty 
                                  ? getCategoryNames().map((categoryName) {
                                      return DropdownMenuItem(
                                        value: categoryName,
                                        child: Text(categoryName),
                                      );
                                    }).toList()
                                  : [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('No categories available'),
                                        enabled: false,
                                      ),
                                    ],
                              onChanged: getCategoryNames().isNotEmpty ? _onCategoryChanged : null,
                            ),
                          ),
                          // const SizedBox(width: 8),
                          // IconButton(
                          //   icon: const Icon(Icons.refresh, color: Color(0xFF1E40AF)),
                          //   onPressed: _fetchCategories,
                          //   tooltip: 'Refresh categories',
                          //   iconSize: 20,
                          // ),
                        ],
                      ),
                      
                      // Subcategory dropdown (only show if subcategories exist)
                      if (getSubcategoriesForCategory(_selectedIndustry).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedSubcategory.isNotEmpty ? _selectedSubcategory : null,
                                decoration: InputDecoration(
                                  hintText: 'Select Subcategory (Optional)',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF1E40AF)),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                items: getSubcategoriesForCategory(_selectedIndustry).map((subcategory) {
                                  return DropdownMenuItem(
                                    value: subcategory,
                                    child: Text(subcategory),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSubcategory = value ?? '';
                                  });
                                },
                              ),
                            ),
                            // if (_selectedSubcategory.isNotEmpty) ...[
                            //   const SizedBox(width: 8),
                            //   Container(
                            //     padding: const EdgeInsets.all(4),
                            //     decoration: BoxDecoration(
                            //       color: Colors.green.withOpacity(0.1),
                            //       borderRadius: BorderRadius.circular(4),
                            //     ),
                            //     child: const Icon(
                            //       Icons.check_circle,
                            //       color: Colors.green,
                            //       size: 16,
                            //     ),
                            //   ),
                            // ],
                          ],
                        ),
                      ],
                      
                      // const SizedBox(height: 4),
                      // Text(
                      //   '${getAvailableCategories().length} categories available',
                      //   style: TextStyle(
                      //     color: Colors.grey[600],
                      //     fontSize: 12,
                      //     fontStyle: FontStyle.italic,
                      //   ),
                      // ),
                    ],
                  ),

                const SizedBox(height: 20),

                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email Address (Optional)',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1E40AF)),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                
                // Email error message
                if (_emailErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _emailErrorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Phone Number Field
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedCountryCode,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          hintText: 'Phone Number',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF1E40AF)),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Phone error message
                if (_phoneErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _phoneErrorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Additional Phone Number Field
                if (_hasAdditionalPhone) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedCountryCode,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _additionalPhoneController,
                          decoration: InputDecoration(
                            hintText: 'Additional Phone Number',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF1E40AF)),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Additional Email Field
                if (_hasAdditionalEmail) ...[
                  TextField(
                    controller: _additionalEmailController,
                    decoration: InputDecoration(
                      hintText: 'Additional Email Address',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF1E40AF)),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1E40AF)),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons
                            .visibility_off,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Confirm Password Field
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1E40AF)),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons
                            .visibility_off,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Additional Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasAdditionalPhone = !_hasAdditionalPhone;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(
                        Icons.add,
                        color: Color(0xFF1E40AF),
                        size: 16,
                      ),
                      label: const Text(
                        'Phone Number',
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasAdditionalEmail = !_hasAdditionalEmail;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(
                        Icons.add,
                        color: Color(0xFF1E40AF),
                        size: 16,
                      ),
                      label: const Text(
                        'Email Address',
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),

                // Contact Person Field
                TextField(
                  controller: _contactPersonController,
                  decoration: InputDecoration(
                    hintText: 'Contact Person',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1E40AF)),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Contact Phone Field
                TextField(
                  controller: _contactPhoneController,
                  decoration: InputDecoration(
                    hintText: 'Contact Phone',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1E40AF)),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Location Picker Section - Moved to top of address fields
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: const Color(0xFF1E40AF),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Location Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a location on the map to automatically fill in the address fields below',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Location Address Field (Read-only)
                      TextField(
                        controller: _locationAddressController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Select location on map to auto-fill address fields',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF1E40AF)),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          prefixIcon: const Icon(
                            Icons.place,
                            color: Color(0xFF1E40AF),
                            size: 20,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // lat and lng Fields (Read-only)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _latController,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'lat',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF1E40AF)),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _lngController,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'lng',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF1E40AF)),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Location Picker and Clear Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showLocationPicker,
                              icon: const Icon(
                                Icons.map,
                                size: 20,
                              ),
                              label: Text(
                                _locationAddressController.text.isEmpty 
                                    ? 'Select Location on Map' 
                                    : 'Change Location',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E40AF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          if (_locationAddressController.text.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _clearLocation,
                              icon: const Icon(
                                Icons.clear,
                                size: 20,
                              ),
                              label: const Text(
                                'Clear',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Address Fields - Cascading Dropdowns
                // Country Dropdown
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCountry,
                        decoration: InputDecoration(
                          hintText: 'Select Country',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF1E40AF)),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        items: LocationService.getCountries().map((country) {
                          return DropdownMenuItem(
                            value: country,
                            child: Text(country),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCountry = value;
                            _selectedDistrict = null;
                            _selectedCity = null;
                            _selectedGovernorate = null;
                          });
                        },
                      ),
                    ),
                    if (_locationAddressController.text.isNotEmpty && _selectedCountry != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // District Dropdown
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: InputDecoration(
                          hintText: _selectedCountry != null && LocationService.usesGovernorateStructure(_selectedCountry!)
                              ? 'Select Governorate'
                              : 'Select District',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF1E40AF)),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        items: _selectedCountry != null 
                            ? (LocationService.usesGovernorateStructure(_selectedCountry!)
                                ? LocationService.getGovernorates(_selectedCountry!).map((governorate) {
                                    return DropdownMenuItem(
                                      value: governorate,
                                      child: Text(governorate),
                                    );
                                  }).toList()
                                : LocationService.getDistricts(_selectedCountry!).map((district) {
                                    return DropdownMenuItem(
                                      value: district,
                                      child: Text(district),
                                    );
                                  }).toList())
                            : [],
                        onChanged: _selectedCountry != null ? (value) {
                          setState(() {
                            _selectedDistrict = value;
                            _selectedCity = null;
                            _selectedGovernorate = null;
                          });
                        } : null,
                      ),
                    ),
                    if (_locationAddressController.text.isNotEmpty && _selectedDistrict != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // City Dropdown
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: InputDecoration(
                          hintText: _selectedCountry != null && LocationService.usesGovernorateStructure(_selectedCountry!)
                              ? 'Select District'
                              : 'Select City',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF1E40AF)),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        items: (_selectedCountry != null && _selectedDistrict != null)
                            ? (LocationService.usesGovernorateStructure(_selectedCountry!)
                                ? LocationService.getDistrictsByGovernorate(_selectedCountry!, _selectedDistrict!).map((district) {
                                    return DropdownMenuItem(
                                      value: district,
                                      child: Text(district),
                                    );
                                  }).toList()
                                : LocationService.getCities(_selectedCountry!, _selectedDistrict!).map((city) {
                                    return DropdownMenuItem(
                                      value: city,
                                      child: Text(city),
                                    );
                                  }).toList())
                            : [],
                        onChanged: (_selectedCountry != null && _selectedDistrict != null) ? (value) {
                          setState(() {
                            _selectedCity = value;
                            _selectedGovernorate = null;
                          });
                        } : null,
                      ),
                    ),
                    if (_locationAddressController.text.isNotEmpty && _selectedCity != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // Governorate Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedGovernorate,
                  decoration: InputDecoration(
                    hintText: _selectedCountry != null && LocationService.usesGovernorateStructure(_selectedCountry!)
                        ? 'Select Street/Area'
                        : 'Select Governorate',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1E40AF)),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  items: (_selectedCountry != null && _selectedDistrict != null && _selectedCity != null)
                      ? (LocationService.usesGovernorateStructure(_selectedCountry!)
                          ? LocationService.getStreetsByGovernorate(_selectedCountry!, _selectedDistrict!, _selectedCity!).map((street) {
                              return DropdownMenuItem(
                                value: street,
                                child: Text(street),
                              );
                            }).toList()
                          : LocationService.getGovernoratesLegacy(_selectedCountry!, _selectedDistrict!, _selectedCity!).map((governorate) {
                              return DropdownMenuItem(
                                value: governorate,
                                child: Text(governorate),
                              );
                            }).toList())
                      : [],
                  onChanged: (_selectedCountry != null && _selectedDistrict != null && _selectedCity != null) ? (value) {
                    setState(() {
                      _selectedGovernorate = value;
                    });
                  } : null,
                ),


                



                const SizedBox(height: 30),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E40AF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// WithdrawDialog widget
class WithdrawDialog extends StatefulWidget {
  final double availableBalance;
  final Future<void> Function(double amount) onWithdraw;
  const WithdrawDialog({Key? key, required this.availableBalance, required this.onWithdraw}) : super(key: key);

  @override
  State<WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<WithdrawDialog> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setMax() {
    setState(() {
      _amountController.text = widget.availableBalance.toStringAsFixed(2);
    });
  }

  Future<void> _handleWithdraw() async {
    final text = _amountController.text.trim();
    
    // Enhanced validation
    if (text.isEmpty) {
      setState(() {
        _error = 'Please enter an amount';
      });
      return;
    }
    
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      setState(() {
        _error = 'Please enter a valid amount greater than 0';
      });
      return;
    }
    
    if (amount < 10.0) {
      setState(() {
        _error = 'Minimum withdrawal amount is \$10.00';
      });
      return;
    }
    
    if (amount > widget.availableBalance) {
      setState(() {
        _error = 'Amount exceeds available balance (\$${widget.availableBalance.toStringAsFixed(2)})';
      });
      return;
    }
    
    // Check if amount has more than 2 decimal places
    if ((amount * 100).round() != (amount * 100)) {
      setState(() {
        _error = 'Amount can only have up to 2 decimal places';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      await widget.onWithdraw(amount);
      // Close the dialog on success - the popup will be shown by the parent
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 350),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Withdraw From Wallet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E234A),
                ),
              ),
              const SizedBox(height: 24),
              // Amount Input Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${widget.availableBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 18,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              prefixText: '\$ ',
                              prefixStyle: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onChanged: (value) {
                              // Clear error when user starts typing
                              if (_error != null) {
                                setState(() {
                                  _error = null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _setMax,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E40AF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF1E40AF).withOpacity(0.3)),
                            ),
                            child: const Text(
                              'MAX',
                              style: TextStyle(
                                color: Color(0xFF1E40AF),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              
              // Loading State
              if (_isLoading)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Color(0xFF0EA5E9),
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Processing withdrawal request...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0EA5E9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1E234A)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF1E234A),
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleWithdraw,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E234A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Withdraw',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}