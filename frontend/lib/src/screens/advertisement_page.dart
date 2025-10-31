import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../services/api_services.dart';
import '../components/header.dart';
import '../components/sidebar.dart';

class AdvertisementPage extends StatefulWidget {
  const AdvertisementPage({Key? key}) : super(key: key);

  @override
  State<AdvertisementPage> createState() => _AdvertisementPageState();
}

class _AdvertisementPageState extends State<AdvertisementPage> {
  List<dynamic> ads = [];
  bool isLoading = false;
  File? _image;
  Uint8List? _imageBytes;
  XFile? _pickedFile;
  final picker = ImagePicker();
  static const String _baseUrl = 'https://barrim.online';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    fetchAds();
  }

  Future<void> fetchAds() async {
    try {
      setState(() => isLoading = true);
      final uri = Uri.parse('$_baseUrl/api/admin/ads');
      // Add auth headers to avoid 401
      Map<String, String> headers = {};
      try {
        headers = await ApiService.getAuthHeaders();
      } catch (_) {}
      final response = await http.get(uri, headers: headers);
      if (!mounted) return;

      if (response.statusCode == 200) {
        dynamic decoded;
        try {
          decoded = json.decode(response.body);
        } catch (_) {
          decoded = null;
        }

        List<dynamic> parsedAds = [];
        if (decoded is Map<String, dynamic>) {
          // Try common keys
          if (decoded['data'] is List) parsedAds = decoded['data'];
          else if (decoded['ads'] is List) parsedAds = decoded['ads'];
          else if (decoded['data'] is Map && decoded['data']['ads'] is List) parsedAds = decoded['data']['ads'];
        } else if (decoded is List) {
          parsedAds = decoded;
        }

        setState(() {
          ads = parsedAds;
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized. Please re-login to view ads.')),
        );
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch ads (status ${response.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch ads: $e')),
      );
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200, // downscale large images
      maxHeight: 800,
      imageQuality: 75, // compress quality
    );
    if (pickedFile == null) return;
    _pickedFile = pickedFile;
    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _image = null;
      });
    } else {
      setState(() {
        _image = File(pickedFile.path);
        _imageBytes = null;
      });
    }
  }

  Future<void> uploadAd() async {
    if (!kIsWeb && _image == null) return;
    if (kIsWeb && _imageBytes == null) return;

    setState(() => isLoading = true);
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/admin/ads'));

    // Add auth header if available
    try {
      final headers = await ApiService.getAuthHeaders();
      request.headers.addAll(headers);
    } catch (_) {}

    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        _imageBytes!,
        filename: _pickedFile?.name ?? 'ad_image.jpg',
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (!mounted) return;
      setState(() => isLoading = false);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad uploaded successfully')));
        await fetchAds();
        setState(() {
          _image = null;
          _imageBytes = null;
          _pickedFile = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload ad (status ${response.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload ad: $e')),
      );
    }
  }

  Future<void> _deleteAd(String id) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Advertisement'),
            content: const Text('Are you sure you want to delete this ad?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ?? false;
    if (!confirm) return;
    try {
      setState(() => isLoading = true);
      final uri = Uri.parse('$_baseUrl/api/admin/ads/$id');
      Map<String, String> headers = {};
      try { headers = await ApiService.getAuthHeaders(); } catch (_) {}
      final response = await http.delete(uri, headers: headers);
      setState(() => isLoading = false);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad deleted successfully')));
        fetchAds();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete ad (status ${response.statusCode})')));
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete ad: $e')));
    }
  }

  String _fullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) return imageUrl;
    if (!imageUrl.startsWith('/')) imageUrl = '/$imageUrl';
    return '$_baseUrl$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header component from header.dart
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              child: HeaderComponent(
                logoPath: 'assets/logo/logo.png',
                scaffoldKey: _scaffoldKey,
                onMenuPressed: () {
                  setState(() {
                    _isSidebarOpen = !_isSidebarOpen;
                  });
                },
              ),
            ),
            // Sub AppBar (moved under HeaderComponent)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Advertisements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  // Main content area
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: pickImage,
                              icon: const Icon(Icons.image),
                              label: const Text('Pick Image'),
                            ),
                            const SizedBox(width: 16),
                            if (_image != null || _imageBytes != null)
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 480,
                                      height: 300,
                                      color: Colors.grey.shade100,
                                      child: Center(
                                        child: kIsWeb
                                            ? Image.memory(
                                                _imageBytes!,
                                                width: 480,
                                                height: 300,
                                                fit: BoxFit.contain,
                                              )
                                            : Image.file(
                                                _image!,
                                                width: 480,
                                                height: 300,
                                                fit: BoxFit.contain,
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: isLoading ? null : uploadAd,
                                    child: isLoading
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Text('Upload'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (isLoading) const Center(child: CircularProgressIndicator()) else Expanded(
                          child: ads.isEmpty
                              ? const Center(child: Text('No ads found'))
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 1,
                                    childAspectRatio: 480/300, // very large banner
                                  ),
                                  itemCount: ads.length,
                                  itemBuilder: (context, index) {
                                    final ad = ads[index];
                                    final imageUrl = (ad['imageURL'] ?? ad['imageUrl'] ?? '').toString();
                                    final url = imageUrl.isNotEmpty ? _fullImageUrl(imageUrl) : '';
                                    final String id = (ad['_id'] ?? ad['id'] ?? '').toString();
                                    return Card(
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 480,
                                            height: 300,
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.all(8.0),
                                            child: url.isNotEmpty
                                              ? Image.network(
                                                  url,
                                                  width: 480,
                                                  height: 300,
                                                  fit: BoxFit.contain,
                                                )
                                              : const Icon(Icons.broken_image, size: 80),
                                          ),
                                          // Delete button
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              tooltip: 'Delete',
                                              onPressed: isLoading ? null : () => _deleteAd(id),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  if (_isSidebarOpen)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 280,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(-2, 0),
                              ),
                            ],
                          ),
                          child: Sidebar(
                            parentContext: context,
                            onCollapse: () {
                              setState(() {
                                _isSidebarOpen = false;
                              });
                            },
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
}
