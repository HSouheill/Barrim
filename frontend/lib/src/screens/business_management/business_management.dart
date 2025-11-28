import 'dart:io';
import 'package:flutter/material.dart';
import '../../components/header.dart';
import '../../models/salesperson_model.dart';
import '../../services/sales_manager_service.dart';
import '../../services/salesperson_service.dart';
import '../../services/api_services.dart';
import 'package:image_picker/image_picker.dart';
import '../../screens/homepage/homepage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';


class BusinessManagement extends StatelessWidget {
  const BusinessManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          primary: const Color(0xFF0D47A1),
        ),
        useMaterial3: true,
      ),
      home: const SalesManagementPage(),
    );
  }
}

class SalesManagementPage extends StatefulWidget {
  const SalesManagementPage({super.key});

  @override
  State<SalesManagementPage> createState() => _SalesManagementPageState();
}

class _SalesManagementPageState extends State<SalesManagementPage> {
  final String _logoPath = 'assets/logo/logo.png';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final SalespersonService _salespersonService = SalespersonService(baseUrl: ApiService.baseUrl);
  List<Salesperson> _salespersons = [];
  bool _isLoading = true;
  String? _error;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _territoryController = TextEditingController();
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    // _loadSalespersons();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _territoryController.dispose();
    super.dispose();
  }

  // Future<void> _loadSalespersons() async {
  //   setState(() {
  //     _isLoading = true;
  //     _error = null;
  //   });
  //
  //   try {
  //     final salespersons = await SalesManagerService.GetAdminSalespersons();
  //     setState(() {
  //       _salespersons = salespersons;
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _error = e.toString();
  //       _isLoading = false;
  //     });
  //     _showErrorSnackBar(e.toString());
  //   }
  // }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes; // ensure you have Uint8List? _selectedImageBytes declared in state
          _selectedImage = null;
        });
      } else {
        setState(() {
          _selectedImage = File(image.path);
          _selectedImageBytes = null;
        });
      }
    }
  }

  Future<void> _addSalesperson() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    final newSalesperson = Salesperson(
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phoneNumber: _phoneController.text,
      status: 'active', // Default to active
    );

    // try {
    //   await _salespersonService.createSalesperson(newSalesperson, imageFile: _selectedImage);
    //   _showSuccessSnackBar('Salesperson added successfully');
    //
    //   // Clear form and reload data
    //   _clearForm();
    //   _loadSalespersons();
    //   Navigator.of(context).pop(); // Close dialog
    // } catch (e) {
    //   _showErrorSnackBar('Failed to add salesperson: ${e.toString()}');
    // }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneController.clear();
    _territoryController.clear();
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _passwordVisible = false;
    });
  }

  void _showAddDialog() {
    _clearForm(); // Clear form before showing dialog

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'Add New Salesperson',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1747),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(
                      color: Color(0xFF8A93AD),
                      fontSize: 16,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF0A1747)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(
                      color: Color(0xFF8A93AD),
                      fontSize: 16,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF0A1747)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(
                      color: Color(0xFF8A93AD),
                      fontSize: 16,
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF0A1747)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility : Icons.visibility_outlined,
                        color: const Color(0xFF0A1747),
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _territoryController,
                  decoration: const InputDecoration(
                    labelText: 'Territory (Optional)',
                    labelStyle: TextStyle(
                      color: Color(0xFF8A93AD),
                      fontSize: 16,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF0A1747)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '+961',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF8A93AD),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey.shade700,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: "Salesperson's Phone",
                          labelStyle: TextStyle(
                            color: Color(0xFF8A93AD),
                            fontSize: 16,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF0A1747)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade400,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _selectedImage != null || _selectedImageBytes != null
                        ? (kIsWeb && _selectedImageBytes != null
                            ? Image.memory(
                                _selectedImageBytes!,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _selectedImage!,
                                height: 100,
                                fit: BoxFit.cover,
                              ))
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Drop your images here',
                          style: TextStyle(
                            color: Color(0xFF0A1747),
                          ),
                        ),
                        const Text(
                          'or',
                          style: TextStyle(
                            color: Color(0xFF8A93AD),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A1747),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            minimumSize: const Size(100, 36),
                          ),
                          child: const Text(
                            'Upload',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0A1747)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        minimumSize: const Size(100, 44),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF0A1747),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _addSalesperson,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1747),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        minimumSize: const Size(100, 44),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: Column(
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
          AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardPage()),
                );
              },
            ),
            backgroundColor: const Color(0xFF0D47A1),
            title: const Text('Sales Management', style: TextStyle(color: Colors.white)),
            elevation: 0,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Sales Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showAddDialog,
                  child: const Icon(
                    Icons.add_circle,
                    color: Color(0xFF1565C0),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {},
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {},
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: (){},
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : _salespersons.isEmpty
                ? const Center(
              child: Text('No salespersons found'),
            )
                : ListView.builder(
              itemCount: _salespersons.length,
              itemBuilder: (context, index) {
                final salesperson = _salespersons[index];
                return SalespersonListTile(
                  salesperson: salesperson,
                  onDelete: () async {
                    try {
                      // await _salespersonService.deleteSalesperson(salesperson.id!);
                      _showSuccessSnackBar('Salesperson deleted successfully');
                      // _loadSalespersons();
                    } catch (e) {
                      _showErrorSnackBar('Failed to delete: ${e.toString()}');
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SalespersonListTile extends StatelessWidget {
  final Salesperson salesperson;
  final VoidCallback onDelete;

  const SalespersonListTile({
    super.key,
    required this.salesperson,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Generate avatar from name if no image
    Widget avatarWidget;
    if (salesperson.image != null && salesperson.image!.isNotEmpty) {
      avatarWidget = CircleAvatar(
        backgroundImage: NetworkImage(salesperson.image!),
        radius: 20,
      );
    } else {
      final initials = salesperson.fullName
          .split(' ')
          .take(2)
          .map((part) => part.isNotEmpty ? part[0] : '')
          .join('')
          .toUpperCase();

      avatarWidget = CircleAvatar(
        backgroundColor: Colors.blue,
        radius: 20,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListTile(
        leading: avatarWidget,
        title: Text(
          salesperson.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(salesperson.email),
            Row(
              children: [
                const Icon(
                  Icons.phone,
                  size: 14,
                  color: Colors.blue,
                ),
                const SizedBox(width: 4),
                Text(
                  salesperson.phoneNumber,
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
            
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: salesperson.status == 'active' ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                salesperson.status ?? 'N/A',
                style: TextStyle(
                  color: salesperson.status == 'active' ? Colors.green.shade800 : Colors.red.shade800,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class for API responses
class ApiResponse<T> {
  Status status;
  T? data;
  String? message;

  ApiResponse.initial() : status = Status.initial;
  ApiResponse.loading() : status = Status.loading;
  ApiResponse.completed(this.data) : status = Status.completed;
  ApiResponse.error(this.message) : status = Status.error;

  @override
  String toString() {
    return "Status : $status \n Message : $message \n Data : $data";
  }
}

enum Status { initial, loading, completed, error }