import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../components/header.dart';
import '../components/sidebar.dart';
import '../services/api_services.dart';
import '../models/admin_wallet_model.dart';

class AdminWalletScreen extends StatefulWidget {
  const AdminWalletScreen({Key? key}) : super(key: key);

  @override
  State<AdminWalletScreen> createState() => _AdminWalletScreenState();
}

class _AdminWalletScreenState extends State<AdminWalletScreen> {
  final String _logoPath = 'assets/logo/logo.png';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  AdminWallet? _walletData;
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedPeriod = 'Month';

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.getAdminWallet();

      if (response.success) {
        setState(() {
          _walletData = AdminWallet.fromJson(response.data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load wallet data: ${e.toString()}';
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Admin Wallet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1C4B),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildWalletContent(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWalletContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
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
              onPressed: _fetchWalletData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_walletData == null) {
      return const Center(
        child: Text('No wallet data available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchWalletData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildIncomeBreakdown(),
            const SizedBox(height: 24),
            _buildCommissionBreakdown(),
            const SizedBox(height: 24),
            _buildLastUpdated(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        // Total Admin Wallet Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Total Admin Wallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '\$${NumberFormat('#,##0.00').format(_walletData!.totalAdminWallet ?? 0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Net Profit and Commissions Row
        Row(
          children: [
            // Net Profit Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Net Profit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\$${NumberFormat('#,##0.00').format(_walletData!.netProfit)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Total Commissions Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.payments,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Commissions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\$${NumberFormat('#,##0.00').format(_walletData!.totalCommissions)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Admin Wallet Breakdown Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Wallet Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1C4B),
                ),
              ),
              const SizedBox(height: 16),
              _buildWalletBreakdownItem(
                'Total Income',
                _walletData!.totalIncome ?? 0,
                const Color(0xFF4CAF50),
                Icons.trending_up,
              ),
              const SizedBox(height: 12),
              _buildWalletBreakdownItem(
                'Admin Wallet Income',
                (_walletData!.totalAdminWallet ?? 0) - (_walletData!.totalIncome ?? 0),
                const Color(0xFF2196F3),
                Icons.account_balance,
              ),
              const SizedBox(height: 12),
              _buildWalletBreakdownItem(
                'Total Commissions',
                -(_walletData!.totalCommissions ?? 0),
                const Color(0xFFFF9800),
                Icons.payments,
                isNegative: true,
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Admin Wallet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1C4B),
                    ),
                  ),
                  Text(
                    '\$${NumberFormat('#,##0.00').format(_walletData!.totalAdminWallet ?? 0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWalletBreakdownItem(String title, double amount, Color color, IconData icon, {bool isNegative = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0D1C4B),
            ),
          ),
        ),
        Text(
          '${isNegative ? '' : '+'}\$${NumberFormat('#,##0.00').format(amount.abs())}',
          style: TextStyle(
            fontSize: 14,
            color: isNegative ? Colors.red.shade600 : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeBreakdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Income Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1C4B),
                ),
              ),
              _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 20),
          
          // Income Chart
          SizedBox(
            height: 200,
            child: _buildIncomeChart(),
          ),
          
          const SizedBox(height: 20),
          
          // Income Details
          _buildIncomeDetails(),
        ],
      ),
    );
  }

  Widget _buildIncomeChart() {
    final incomeData = _walletData!.incomeBreakdown;
    final companyIncome = (incomeData['company']?['income'] ?? 0).toDouble();
    final wholesalerIncome = (incomeData['wholesaler']?['income'] ?? 0).toDouble();
    final serviceProviderIncome = (incomeData['serviceProvider']?['income'] ?? 0).toDouble();
    final sponsorshipIncome = (incomeData['sponsorship']?['income'] ?? 0).toDouble();

    if (companyIncome == 0 && wholesalerIncome == 0 && serviceProviderIncome == 0 && sponsorshipIncome == 0) {
      return const Center(
        child: Text(
          'No income data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: [
          if (companyIncome > 0)
            PieChartSectionData(
              color: const Color(0xFF4CAF50),
              value: companyIncome,
              title: 'Company\n${((companyIncome / _walletData!.totalIncome) * 100).toStringAsFixed(1)}%',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (wholesalerIncome > 0)
            PieChartSectionData(
              color: const Color(0xFF2196F3),
              value: wholesalerIncome,
              title: 'Wholesaler\n${((wholesalerIncome / _walletData!.totalIncome) * 100).toStringAsFixed(1)}%',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (serviceProviderIncome > 0)
            PieChartSectionData(
              color: const Color(0xFFFF9800),
              value: serviceProviderIncome,
              title: 'Service\n${((serviceProviderIncome / _walletData!.totalIncome) * 100).toStringAsFixed(1)}%',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (sponsorshipIncome > 0)
            PieChartSectionData(
              color: const Color(0xFF9C27B0),
              value: sponsorshipIncome,
              title: 'Sponsorship\n${((sponsorshipIncome / _walletData!.totalIncome) * 100).toStringAsFixed(1)}%',
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildIncomeDetails() {
    final incomeData = _walletData!.incomeBreakdown;
    
    return Column(
      children: [
        _buildIncomeDetailItem(
          'Company Subscriptions',
          (incomeData['company']?['income'] ?? 0).toDouble(),
          const Color(0xFF4CAF50),
          incomeData['company']?['error'],
        ),
        const SizedBox(height: 12),
        _buildIncomeDetailItem(
          'Wholesaler Subscriptions',
          (incomeData['wholesaler']?['income'] ?? 0).toDouble(),
          const Color(0xFF2196F3),
          incomeData['wholesaler']?['error'],
        ),
        const SizedBox(height: 12),
        _buildIncomeDetailItem(
          'Service Provider Subscriptions',
          (incomeData['serviceProvider']?['income'] ?? 0).toDouble(),
          const Color(0xFFFF9800),
          incomeData['serviceProvider']?['error'],
        ),
        const SizedBox(height: 12),
        _buildIncomeDetailItem(
          'Sponsorship',
          (incomeData['sponsorship']?['income'] ?? 0).toDouble(),
          const Color(0xFF9C27B0),
          incomeData['sponsorship']?['error'],
        ),
      ],
    );
  }

  Widget _buildIncomeDetailItem(String title, double amount, Color color, String? error) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0D1C4B),
            ),
          ),
        ),
        if (error != null)
          Text(
            'Error',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Text(
            '\$${NumberFormat('#,##0.00').format(amount)}',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildCommissionBreakdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Commission Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1C4B),
            ),
          ),
          const SizedBox(height: 20),
          
          // Commission Chart
          SizedBox(
            height: 200,
            child: _buildCommissionChart(),
          ),
          
          const SizedBox(height: 20),
          
          // Commission Details
          _buildCommissionDetails(),
        ],
      ),
    );
  }

  Widget _buildCommissionChart() {
    final commissionData = _walletData!.commissionBreakdown;
    final salespersonCommission = (commissionData['salesperson']?['commission'] ?? 0).toDouble();
    final salesManagerCommission = (commissionData['salesManager']?['commission'] ?? 0).toDouble();

    if (salespersonCommission == 0 && salesManagerCommission == 0) {
      return const Center(
        child: Text(
          'No commission data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (_walletData!.totalCommissions ?? 0) > 0 ? (_walletData!.totalCommissions ?? 0) * 1.2 : 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text('Salesperson', style: TextStyle(fontSize: 12));
                  case 1:
                    return const Text('Sales Manager', style: TextStyle(fontSize: 12));
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${NumberFormat('#,##0').format(value)}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: salespersonCommission,
                color: const Color(0xFF4CAF50),
                width: 40,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: salesManagerCommission,
                color: const Color(0xFF2196F3),
                width: 40,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        ],
        gridData: FlGridData(
          show: true,
          horizontalInterval: (_walletData!.totalCommissions ?? 0) > 0 ? (_walletData!.totalCommissions ?? 0) / 4 : 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCommissionDetails() {
    final commissionData = _walletData!.commissionBreakdown;
    
    return Column(
      children: [
        _buildCommissionDetailItem(
          'Salesperson Commissions',
          (commissionData['salesperson']?['commission'] ?? 0).toDouble(),
          (commissionData['salesperson']?['percentage'] ?? 0).toDouble(),
          const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 12),
        _buildCommissionDetailItem(
          'Sales Manager Commissions',
          (commissionData['salesManager']?['commission'] ?? 0).toDouble(),
          (commissionData['salesManager']?['percentage'] ?? 0).toDouble(),
          const Color(0xFF2196F3),
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Commissions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1C4B),
              ),
            ),
            Text(
              '\$${NumberFormat('#,##0.00').format(_walletData!.totalCommissions)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommissionDetailItem(String title, double amount, double percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0D1C4B),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${NumberFormat('#,##0.00').format(amount)}',
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (percentage > 0)
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        _buildPeriodButton('Day'),
        const SizedBox(width: 8),
        _buildPeriodButton('Month'),
      ],
    );
  }

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

  Widget _buildLastUpdated() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Last updated: ${DateFormat('MMM dd, yyyy HH:mm').format(_walletData!.lastUpdated)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          IconButton(
            onPressed: _fetchWalletData,
            icon: Icon(
              Icons.refresh,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
