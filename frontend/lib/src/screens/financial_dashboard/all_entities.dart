import 'package:flutter/material.dart';
import '../../services/api_services.dart';

class AllEntitiesPage extends StatefulWidget {
  const AllEntitiesPage({Key? key}) : super(key: key);

  @override
  State<AllEntitiesPage> createState() => _AllEntitiesPageState();
}

class _AllEntitiesPageState extends State<AllEntitiesPage> {
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> entities = [];
  List<Map<String, dynamic>> filteredEntities = [];

  // Filters
  String searchQuery = '';
  String? selectedUserType;
  String? selectedActiveStatus;

  @override
  void initState() {
    super.initState();
    _fetchEntities();
  }

  Future<void> _fetchEntities() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final result = await ApiService.getAllEntities();
      if (result.success && result.data != null) {
        // Flatten all entities from different collections into a single list
        final List<Map<String, dynamic>> allEntities = [];
        
        // Add users
        if (result.data['users'] is List) {
          allEntities.addAll((result.data['users'] as List).cast<Map<String, dynamic>>());
        }
        
        // Add companies
        if (result.data['companies'] is List) {
          allEntities.addAll((result.data['companies'] as List).cast<Map<String, dynamic>>());
        }
        
        // Add wholesalers
        if (result.data['wholesalers'] is List) {
          allEntities.addAll((result.data['wholesalers'] as List).cast<Map<String, dynamic>>());
        }
        
        // Add service providers
        if (result.data['serviceProviders'] is List) {
          allEntities.addAll((result.data['serviceProviders'] as List).cast<Map<String, dynamic>>());
        }
        
        setState(() {
          entities = allEntities;
          filteredEntities = allEntities;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result.message;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      filteredEntities = entities.where((entity) {
        final matchesSearch = searchQuery.isEmpty ||
            (entity['fullName']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (entity['email']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (entity['userType']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
        final matchesUserType = selectedUserType == null || selectedUserType == '' || entity['userType'] == selectedUserType;
        final matchesActive = selectedActiveStatus == null || selectedActiveStatus == '' ||
            (selectedActiveStatus == 'Active' && entity['isActive'] == true) ||
            (selectedActiveStatus == 'Inactive' && entity['isActive'] == false);
        return matchesSearch && matchesUserType && matchesActive;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      searchQuery = '';
      selectedUserType = null;
      selectedActiveStatus = null;
      filteredEntities = List.from(entities);
    });
  }

  List<String> get _userTypes {
    final types = entities.map((e) => e['userType']?.toString() ?? '').toSet().toList();
    types.removeWhere((t) => t.isEmpty);
    types.sort();
    return types;
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search by name, email, or type',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (val) {
                searchQuery = val;
                _applyFilters();
              },
              controller: TextEditingController(text: searchQuery),
            ),
          ),
          DropdownButton<String>(
            value: selectedUserType,
            hint: Text('User Type'),
            items: [
              const DropdownMenuItem(value: '', child: Text('All Types')),
              ..._userTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))),
            ],
            onChanged: (val) {
              selectedUserType = val == '' ? null : val;
              _applyFilters();
            },
          ),
          DropdownButton<String>(
            value: selectedActiveStatus,
            hint: Text('Status'),
            items: const [
              DropdownMenuItem(value: '', child: Text('All Statuses')),
              DropdownMenuItem(value: 'Active', child: Text('Active')),
              DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
            ],
            onChanged: (val) {
              selectedActiveStatus = val == '' ? null : val;
              _applyFilters();
            },
          ),
          ElevatedButton.icon(
            onPressed: _clearFilters,
            icon: Icon(Icons.clear),
            label: Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    final columns = [
      'ID',
      'Full Name',
      'Email',
      'User Type',
      'Active',
      'Created',
      'Updated',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns
            .map((col) => DataColumn(
                  label: Text(
                    col,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ))
            .toList(),
        rows: filteredEntities.map((entity) {
          return DataRow(
            cells: [
              DataCell(Text(entity['id']?.toString() ?? entity['_id']?.toString() ?? '')),
              DataCell(Text(entity['fullName']?.toString() ?? '')),
              DataCell(Text(entity['email']?.toString() ?? '')),
              DataCell(Text(entity['userType']?.toString() ?? '')),
              DataCell(
                Row(
                  children: [
                    Icon(
                      entity['isActive'] == true ? Icons.check_circle : Icons.cancel,
                      color: entity['isActive'] == true ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(entity['isActive'] == true ? 'Active' : 'Inactive'),
                  ],
                ),
              ),
              DataCell(Text(entity['createdAt']?.toString().split('T').first ?? '')),
              DataCell(Text(entity['updatedAt']?.toString().split('T').first ?? '')),
            ],
          );
        }).toList(),
        dataRowColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return Theme.of(context).colorScheme.primary.withOpacity(0.08);
          }
          return null;
        }),
        headingRowColor: MaterialStateProperty.all(Colors.blueGrey[50]),
        dividerThickness: 1,
        showCheckboxColumn: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users / Entities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEntities,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : Column(
                  children: [
                    _buildFilters(),
                    const Divider(height: 1),
                    Expanded(
                      child: filteredEntities.isEmpty
                          ? const Center(child: Text('No users/entities found.'))
                          : _buildDataTable(),
                    ),
                  ],
                ),
    );
  }
} 