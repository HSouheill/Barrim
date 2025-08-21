import 'package:flutter/material.dart';
import '../../screens/homepage/homepage.dart';

// Gifts Redeemed Page
class GiftsRedeemedPage extends StatelessWidget {
  const GiftsRedeemedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
          },
        ),
        title: const Text(
          'Referral Program',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header with tabs
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Text(
                        'Numbers of Referral',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Gifts Redeemed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // Navigate to Membership Plans page
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => const MembershipPlansPage(),
                    //   ),
                    // );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.indigo[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Add Voucher',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'All',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Voucher list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildVoucherItem('Basic', Colors.blue),
                _buildVoucherItem('Gold', Colors.orange),
                _buildVoucherItem('Premium', Colors.indigo[900]!),
                _buildVoucherItem('Basic', Colors.blue),
                _buildVoucherItem('Gold', Colors.orange),
                _buildVoucherItem('Premium', Colors.indigo[900]!),
                _buildVoucherItem('Premium', Colors.indigo[900]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherItem(String type, Color typeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Profile avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: Colors.blue[600],
              size: 30,
            ),
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jad Fikri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Jadfikri123@gmail.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '1 Month Subscription',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Type badge and arrow
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.grey[600],
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

