// sidebar.dart
import 'package:flutter/material.dart';
import '../../main.dart';
import '../screens/business_management/business_management.dart';
import '../screens/company_management/addbranch_request.dart';
import '../screens/referral_program_monitoring/gifts_redeemed.dart';
import '../screens/referral_program_monitoring/referral_program.dart';
import '../screens/sales_management/sales_admin_dashboard.dart';
import '../screens/referral_program_monitoring/membership_plans_screen.dart';
import '../utils/auth_manager.dart';
import '../screens/homepage/homepage.dart';
import '../screens/sales_management/sales_manager/sales_manager_dashboard.dart';
import '../screens/sales_management/sales_manager/salesmanager_requests.dart';
import '../screens/sales_management/salesperson/salesperson_dashboard.dart';
import '../screens/worker_management/worker_management.dart';
import '../screens/financial_dashboard/financial_dashboard.dart';
import '../screens/user_management/user_management_screen.dart';
import '../screens/admin_withdraws.dart';
import '../screens/admin_wallet.dart';
import '../screens/admin/requests.dart';
import '../screens/admin_sponsorship.dart';
import '../screens/bookings_and_reviews.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/voucher/voucher_screen.dart';
import '../screens/advertisement_page.dart';




class Sidebar extends StatelessWidget {
  final VoidCallback onCollapse;
  final BuildContext parentContext;

  const Sidebar({super.key, required this.onCollapse, required this.parentContext});

  // Method to handle logout
  Future<void> _handleLogout(BuildContext context) async {
    // Call AuthManager's logout method
    await AuthManager.logout();

    // Close sidebar
    onCollapse();

    // Navigate to LoginPage
    Navigator.of(parentContext).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Important: Use the Navigator.of(context) for most navigation
    // and Navigator.of(parentContext) only when needed to prevent overlap issues
    return Container(
      width:199,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2079C2),
            Color(0xFF1F4889),
            Color(0xFF10105D),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(5, 0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align content to left
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.only(top: 10),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),

                ),
                SizedBox(height: 20),
                _buildMenuItem(Icons.home, 'Home',
                  onTap: () {
                      onCollapse();
                      Future.delayed(const Duration(milliseconds: 300), () {
                        Navigator.of(parentContext).pushReplacement(
MaterialPageRoute(builder: (context) => const DashboardPage()),                        );
                      });

                    },
                  ),
                _buildMenuItem(
                  Icons.category,
                  'Categories',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                      );
                    });
                  },
                ),


                // _buildMenuItem(
                //   Icons.people,
                //   'User Management',
                //   onTap: () {
                //     onCollapse();
                //     Future.delayed(const Duration(milliseconds: 300), () {
                //       Navigator.of(parentContext).pushReplacement(
                //         MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                //       );
                //     });
                //   },
                // ),



                _buildMenuItem(
                  Icons.book_online,
                  'Sales Management',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SalesAdminDashboard()),
                      );
                    });

                  },
                ),
                _buildMenuItem(
                  Icons.book_online,
                  'Business Management',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const RestaurantListScreen()),
                      );
                    });

                  },
                ),
                // _buildMenuItem(
                //   Icons.share,
                //   'Location',
                //   onTap: () {

                //   },
                // ),

                // _buildMenuItem(
                //   Icons.people,
                //   'Workers',
                //   onTap: () {
                //     onCollapse();
                //     Future.delayed(const Duration(milliseconds: 300), () {
                //       Navigator.of(parentContext).pushReplacement(
                //         MaterialPageRoute(builder: (context) => WorkerManagementScreen()),
                //       );
                //     });
                //   },
                // ),

                // _buildMenuItem(
                //   Icons.settings,
                //   'Bookings',
                //   onTap: () {

                //   },
                // ),

                _buildMenuItem(
                  Icons.settings,
                  'Subs requests',
                  onTap: () {
                      onCollapse();
                      Future.delayed(const Duration(milliseconds: 300), () {
                        Navigator.of(parentContext).pushReplacement(
                          MaterialPageRoute(builder: (context) => const RequireApprovalPage()),
                        );
                      });

                  },
                ),

                _buildMenuItem(
                  Icons.pending_actions,
                  'Pending Requests',
                  onTap: () {
                      onCollapse();
                      Future.delayed(const Duration(milliseconds: 300), () {
                        Navigator.of(parentContext).pushReplacement(
                          MaterialPageRoute(builder: (context) => const AdminRequestsScreen()),
                        );
                      });

                  },
                ),

                _buildMenuItem(
                  Icons.settings,
                  'Plans',
                  onTap: () {
                    onCollapse();
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const MembershipPlansScreen()),
                      );

                  },
                ),

                _buildMenuItem(
                  Icons.card_giftcard,
                  'Sponsorships',
                  onTap: () {
                    onCollapse();
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const AdminSponsorshipScreen()),
                      );

                  },
                ),

                _buildMenuItem(
                  Icons.star,
                  'Bookings & Reviews',
                  onTap: () {
                    onCollapse();
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const BookingsAndReviewsScreen()),
                      );

                  },
                ),

                _buildMenuItem(
                  Icons.card_giftcard,
                  'Vouchers',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const VoucherScreen()),
                      );
                    });
                  },
                ),

                _buildMenuItem(
                  Icons.campaign,
                  'Advertisements',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const AdvertisementPage()),
                      );
                    });
                  },
                ),

                _buildMenuItem(
                  Icons.account_balance_wallet,
                  'Withdrawals',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const AdminWithdrawsScreen()),
                      );
                    });
                  },
                ),

                _buildMenuItem(
                  Icons.account_balance,
                  'Admin Wallet',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const AdminWalletScreen()),
                      );
                    });
                  },
                ),
                

                // _buildMenuItem(
                //   Icons.settings,
                //   'Settings',
                //   onTap: () {

                //   },
                // ),

                // Add divider before logout button
                Divider(color: Colors.white.withOpacity(0.3), height: 32),
                
                // Logout button
                _buildMenuItem(
                  Icons.logout,
                  'Logout',
                  onTap: () => _handleLogout(context),
                  textColor: Colors.white,
                  iconColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap, Color textColor = Colors.white, Color iconColor = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      onTap: onTap,
    );
  }
}

class ManagerSidebar extends StatelessWidget {
  final VoidCallback onCollapse;
  final BuildContext parentContext;

  const ManagerSidebar({super.key, required this.onCollapse, required this.parentContext});

  Future<void> _handleLogout(BuildContext context) async {
    await AuthManager.logout();
    onCollapse();
    Navigator.of(parentContext).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 199,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2079C2),
            Color(0xFF1F4889),
            Color(0xFF10105D),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(5, 0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(top: 10),
              children: [
                SizedBox(height: 20),
                _buildMenuItem(Icons.home, 'Home',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SalesManagerDashboard()),
                      );
                    });
                  },
                ),
                _buildMenuItem(Icons.request_page, 'Request',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SalesManagerRequestsPage()),
                      );
                    });
                    // Placeholder for request action
                  },
                ),
                
                Divider(color: Colors.white.withOpacity(0.3), height: 32),
                _buildMenuItem(
                  Icons.logout,
                  'Logout',
                  onTap: () => _handleLogout(context),
                  textColor: Colors.white,
                  iconColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap, Color textColor = Colors.white, Color iconColor = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      onTap: onTap,
    );
  }
}

class SalesManagerSidebar extends StatelessWidget {
  final VoidCallback onCollapse;
  final BuildContext parentContext;

  const SalesManagerSidebar({super.key, required this.onCollapse, required this.parentContext});

  Future<void> _handleLogout(BuildContext context) async {
    await AuthManager.logout();
    onCollapse();
    Navigator.of(parentContext).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 199,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2079C2),
            Color(0xFF1F4889),
            Color(0xFF10105D),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(5, 0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(top: 10),
              children: [
                SizedBox(height: 20),
                _buildMenuItem(Icons.home, 'Home',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SalesManagerDashboard()),
                      );
                    });
                  },
                ),
                _buildMenuItem(Icons.request_page, 'Request',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SalesManagerRequestsPage()),
                      );
                    });
                  },
                ),
                // _buildMenuItem(Icons.request_page, 'subs',
                //   onTap: () {
                //     onCollapse();
                //     Future.delayed(const Duration(milliseconds: 300), () {
                //       Navigator.of(parentContext).pushReplacement(
                //         MaterialPageRoute(builder: (context) => const SalesManagerRequestsPage()),
                //       );
                //     });
                //   },
                // ),
                // _buildMenuItem(Icons.request_page, 'Commissions',
                //   onTap: () {
                //     onCollapse();
                //     Future.delayed(const Duration(milliseconds: 300), () {
                //       Navigator.of(parentContext).pushReplacement(
                //         MaterialPageRoute(builder: (context) => const SalesManagerRequestsPage()),
                //       );
                //     });
                //     // Placeholder for request action
                //   },
                // ),
                Divider(color: Colors.white.withOpacity(0.3), height: 32),
                _buildMenuItem(
                  Icons.logout,
                  'Logout',
                  onTap: () => _handleLogout(context),
                  textColor: Colors.white,
                  iconColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap, Color textColor = Colors.white, Color iconColor = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      onTap: onTap,
    );
  }
}

class SalespersonSidebar extends StatelessWidget {
  final VoidCallback onCollapse;
  final BuildContext parentContext;

  const SalespersonSidebar({super.key, required this.onCollapse, required this.parentContext});

  Future<void> _handleLogout(BuildContext context) async {
    await AuthManager.logout();
    onCollapse();
    Navigator.of(parentContext).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 199,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2079C2),
            Color(0xFF1F4889),
            Color(0xFF10105D),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(5, 0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(top: 10),
              children: [
                SizedBox(height: 20),
                _buildMenuItem(Icons.home, 'Home',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SalespersonDashboard()),
                      );
                    });
                  },
                ),
                _buildMenuItem(Icons.list_alt, 'Listings',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SalespersonDashboard()),
                      );
                    });
                  },
                ),
                _buildMenuItem(Icons.account_balance_wallet, 'Wallet',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SalespersonDashboard()),
                      );
                    });
                  },
                ),
                _buildMenuItem(Icons.add_business, 'Add New',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SalespersonDashboard()),
                      );
                    });
                  },
                ),
                _buildMenuItem(Icons.history, 'History',
                  onTap: () {
                    onCollapse();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (context) => const SalespersonDashboard()),
                      );
                    });
                  },
                ),
                Divider(color: Colors.white.withOpacity(0.3), height: 32),
                _buildMenuItem(
                  Icons.logout,
                  'Logout',
                  onTap: () => _handleLogout(context),
                  textColor: Colors.white,
                  iconColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap, Color textColor = Colors.white, Color iconColor = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      onTap: onTap,
    );
  }
}