import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class SimpleLocationPicker extends StatefulWidget {
  final Function(double lat, double lng, String address) onLocationSelected;
  final double? initialLat;
  final double? initialLng;

  const SimpleLocationPicker({
    super.key,
    required this.onLocationSelected,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<SimpleLocationPicker> createState() => _SimpleLocationPickerState();
}

class _SimpleLocationPickerState extends State<SimpleLocationPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();
  
  LatLng? _selectedLocation;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
      _getAddressFromLocation(_selectedLocation!);
    } else {
      _selectedLocation = const LatLng(33.8938, 35.5018); // Default to Beirut
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    try {
      setState(() => _isLoading = true);
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = [
          place.street,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
        
        _addressController.text = address;
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to get address: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getLocationFromAddress(String address) async {
    try {
      setState(() => _isLoading = true);
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        Location location = locations[0];
        LatLng newLocation = LatLng(location.latitude, location.longitude);
        
        setState(() {
          _selectedLocation = newLocation;
          _errorMessage = null;
        });
        
        _mapController.move(newLocation, 15.0);
        _getAddressFromLocation(newLocation);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to find location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
      _errorMessage = null;
    });
    _getAddressFromLocation(location);
  }

  void _onConfirm() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        _addressController.text,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E40AF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Address Input
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter address or search location',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.my_location),
                          onPressed: () async {
                            try {
                              Position position = await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high,
                              );
                              LatLng location = LatLng(position.latitude, position.longitude);
                              setState(() {
                                _selectedLocation = location;
                                _errorMessage = null;
                              });
                              _mapController.move(location, 15.0);
                              _getAddressFromLocation(location);
                            } catch (e) {
                              setState(() => _errorMessage = 'Failed to get current location: $e');
                            }
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: _getLocationFromAddress,
              ),
            ),
            
            if (_errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
            
            // Map
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation!,
                        initialZoom: 15.0,
                        onTap: _onMapTap,
                        minZoom: 10.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: [
                            if (_selectedLocation != null)
                              Marker(
                                point: _selectedLocation!,
                                width: 30,
                                height: 30,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 30,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1E40AF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(100, 44),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF1E40AF)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedLocation != null ? _onConfirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(100, 44),
                      ),
                      child: const Text(
                        'Select Location',
                        style: TextStyle(color: Colors.white),
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
