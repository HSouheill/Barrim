import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../utils/google_maps_loader.dart' as google_maps_loader;

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
  static const String _googleMapsApiKey = 'AIzaSyAHe-qtN5j-7_fb4RNxv_V8ZqPryDTjjyQ';
  static const LatLng _defaultCenter = LatLng(33.8938, 35.5018); // Beirut

  final TextEditingController _addressController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng _currentCenter = _defaultCenter;
  LatLng? _selectedLocation;
  bool _isLoading = false;
  bool _isMapReady = false;
  String? _errorMessage;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentCenter = LatLng(widget.initialLat!, widget.initialLng!);
    }
    _selectedLocation = _currentCenter;
    _markers = {
      Marker(
        markerId: const MarkerId('selected'),
        position: _currentCenter,
      ),
    };
    _initializePicker();
  }

  Future<void> _initializePicker() async {
    try {
      await google_maps_loader.ensureGoogleMapsScriptLoaded(_googleMapsApiKey);
      if (!mounted) return;
      setState(() {
        _isMapReady = true;
      });
      await _reverseGeocode(_currentCenter);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to initialize Google Maps: $e';
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng location) async {
    _setLoading(true);
    try {
      final success = await _tryGoogleReverseGeocode(location);
      if (!success) {
        final fallbackSuccess = await _reverseGeocodeFallback(location);
        if (!fallbackSuccess && mounted) {
          setState(() {
            _errorMessage = 'Unable to determine address for this location.';
          });
        }
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _tryGoogleReverseGeocode(LatLng location) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=$_googleMapsApiKey',
      );
      final response = await http.get(url);
      if (!mounted) return false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;
        if (status == 'OK' && (data['results'] as List).isNotEmpty) {
          final formattedAddress = data['results'][0]['formatted_address'] as String;
          setState(() {
            _addressController.text = formattedAddress;
            _errorMessage = null;
          });
          return true;
        }
      }
    } catch (_) {
      // Ignore and fall back.
    }
    return false;
  }

  Future<bool> _reverseGeocodeFallback(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (!mounted) return false;
      if (placemarks.isEmpty) return false;
      final place = placemarks.first;
      final parts = [
        place.street,
        place.locality,
        place.administrativeArea,
        place.country,
      ].whereType<String>().where((part) => part.isNotEmpty).toList();
      if (parts.isEmpty) return false;
      setState(() {
        _addressController.text = parts.join(', ');
        _errorMessage = null;
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) return;
    _setLoading(true);
    try {
      final success = await _tryGooglePlaceSearch(query);
      if (!success) {
        final fallback = await _fallbackPlaceSearch(query);
        if (!fallback && mounted) {
          setState(() {
            _errorMessage = 'Unable to locate "$query".';
          });
        }
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _tryGooglePlaceSearch(String query) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json'
        '?input=${Uri.encodeComponent(query)}'
        '&inputtype=textquery'
        '&fields=formatted_address,geometry'
        '&key=$_googleMapsApiKey',
      );
      final response = await http.get(url);
      if (!mounted) return false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;
        final candidates = (data['candidates'] as List?) ?? [];
        if (status == 'OK' && candidates.isNotEmpty) {
          final candidate = candidates.first as Map<String, dynamic>;
          final geometry = candidate['geometry'] as Map<String, dynamic>;
          final location = geometry['location'] as Map<String, dynamic>;
          final latLng = LatLng(
            (location['lat'] as num).toDouble(),
            (location['lng'] as num).toDouble(),
          );
          _addressController.text = candidate['formatted_address'] as String? ?? query;
          _updateSelectedLocation(latLng);
          return true;
        }
      }
    } catch (_) {
      // Ignore and fall back.
    }
    return false;
  }

  Future<bool> _fallbackPlaceSearch(String query) async {
    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) return false;
      final location = locations.first;
      final latLng = LatLng(location.latitude, location.longitude);
      _updateSelectedLocation(latLng);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _useCurrentLocation() async {
    _setLoading(true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Location permissions are permanently denied';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      final latLng = LatLng(position.latitude, position.longitude);
      _updateSelectedLocation(latLng);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to get current location: $e';
      });
    } finally {
      _setLoading(false);
    }
  }

  void _updateSelectedLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _currentCenter = location;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
      _errorMessage = null;
    });
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 15),
      ),
    );
    _reverseGeocode(location);
  }

  void _onMapTap(LatLng location) {
    _updateSelectedLocation(location);
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

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() {
      _isLoading = value;
    });
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
                          onPressed: _useCurrentLocation,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: _searchPlace,
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
                    child: _isMapReady
                        ? GoogleMap(
                            onMapCreated: (controller) => _mapController = controller,
                            initialCameraPosition: CameraPosition(
                              target: _currentCenter,
                              zoom: 15,
                            ),
                            onTap: _onMapTap,
                            markers: _markers,
                            myLocationButtonEnabled: false,
                            myLocationEnabled: true,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                          )
                        : const Center(child: CircularProgressIndicator()),
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
