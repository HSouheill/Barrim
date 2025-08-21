import 'package:flutter/material.dart';
import '../../models/service_provider_model.dart';
import '../../services/admin_service.dart';
import '../../services/api_services.dart';
import '../../screens/homepage/homepage.dart';

class WorkerManagementScreen extends StatefulWidget {
  @override
  _WorkerManagementScreenState createState() => _WorkerManagementScreenState();
}

class _WorkerManagementScreenState extends State<WorkerManagementScreen> {
  late Future<List<ServiceProvider>> _futureProviders;

  @override
  void initState() {
    super.initState();
    _futureProviders = AdminService(baseUrl: ApiService.baseUrl).getAllServiceProviders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(        
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
            );
          },
        ),
        title: Text('List of Workers', style: TextStyle(color: Color(0xFF151E46), fontWeight: FontWeight.bold)),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<ServiceProvider>>(
        future: _futureProviders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error:  {snapshot.error}'));
          }
          final providers = snapshot.data ?? [];
          final grouped = <String, List<ServiceProvider>>{};
          for (var p in providers) {
            final category = p.serviceProviderInfo?.category ?? 'Others';
            grouped.putIfAbsent(category, () => []).add(p);
          }
          return ListView(
            padding: EdgeInsets.only(bottom: 24),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF151E46),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text(entry.key, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: entry.value.map((provider) => WorkerCard(provider: provider)).toList(),
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class WorkerCard extends StatelessWidget {
  final ServiceProvider provider;
  const WorkerCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final status = provider.serviceProviderInfo?.status ?? '';
    return Card(
      color: Color(0xFF151E46),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 200,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: provider.profileImage != null
                  ? NetworkImage(provider.profileImage!)
                  : AssetImage('assets/images/default_avatar.png') as ImageProvider,
              radius: 32,
            ),
            SizedBox(height: 8),
            Text(provider.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 4),
            if (status == 'paid')
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green, borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Paid', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Expanded(child: Text(provider.email, style: TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
              ],
            ),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Expanded(child: Text(provider.phone, style: TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: Size(70, 32)),
                  onPressed: () {}, // Approve logic
                  child: Text('Approve'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: Size(70, 32)),
                  onPressed: () {}, // Reject logic
                  child: Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
