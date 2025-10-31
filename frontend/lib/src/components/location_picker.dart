import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationPicker extends StatefulWidget {
  final Function(LatLng location, double radius, String address) onLocationSelected;
  final LatLng? initialLocation;
  final double? initialRadius;

  const LocationPicker({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
    this.initialRadius,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();
  
  LatLng? _selectedLocation;
  double _radius = 300.0; // Default 300m radius
  bool _isLoading = false;
  String? _errorMessage;
  double _currentZoom = 15.0; // Track current zoom level

  final List<double> _radiusOptions = [100, 200, 300, 500, 1000, 2000, 5000]; // in meters

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? const LatLng(40.7128, -74.0060); // Default to NYC
    _radius = widget.initialRadius ?? 300.0;
    _radiusController.text = _radius.toString();
    _getAddressFromLocation(_selectedLocation!);
    
    // Add listener to map controller for zoom changes
    _mapController.mapEventStream.listen((MapEvent event) {
      setState(() {
        _currentZoom = _mapController.zoom;
      });
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _addressController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  // Convert radius from meters to pixels based on zoom level
  double _getRadiusInPixels(double radiusInMeters, double zoom) {
    // At zoom level 15, 1 pixel ≈ 1 meter
    // Formula: radiusInPixels = radiusInMeters / (2^(15 - zoom))
    return radiusInMeters / (1 << (15 - zoom.toInt()));
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
        List<String> addressParts = [];
        
        // Safely add non-null address parts
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }
        
        // If we have address parts, join them; otherwise use coordinates
        if (addressParts.isNotEmpty) {
          _addressController.text = addressParts.join(', ');
        } else {
          // Fallback to coordinates if no address parts available
          _addressController.text = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        }
      } else {
        // Fallback to coordinates if no placemarks found
        _addressController.text = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      }
    } catch (e) {
      // Fallback to coordinates on error
      _addressController.text = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      setState(() => _errorMessage = null); // Clear error message since we have fallback
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

  void _onRadiusChanged(double? newRadius) {
    if (newRadius != null) {
      setState(() {
        _radius = newRadius;
        _radiusController.text = newRadius.toString();
      });
    }
  }

  void _onConfirm() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(
        _selectedLocation!,
        _radius,
        _addressController.text,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF0A1747), size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Select Region Area',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1747),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Control Panel
            Column(
              children: [
                // Address Input
                TextField(
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
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: _getLocationFromAddress,
                ),
                const SizedBox(height: 12),
                
                // Radius Dropdown
                Row(
                  children: [
                    const Text('Radius: ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        value: _radius,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _radiusOptions.map((radius) {
                          String label = radius >= 1000 
                              ? '${(radius / 1000).toStringAsFixed(1)}km'
                              : '${radius.toInt()}m';
                          return DropdownMenuItem(
                            value: radius,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: _onRadiusChanged,
                        isExpanded: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Debug info - shows current zoom and calculated pixel radius
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Zoom: ${_currentZoom.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Radius: ${_radius}m (${_getRadiusInPixels(_radius, _currentZoom).toStringAsFixed(1)}px)',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: 12),

            // Map
            Expanded(
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
                      // OpenStreetMap tiles
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      
                      // Selected location marker
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
                      
                      // Radius circle - now properly scaled based on zoom level
                      CircleLayer(
                        circles: [
                          if (_selectedLocation != null)
                            CircleMarker(
                              point: _selectedLocation!,
                              radius: _getRadiusInPixels(_radius, _currentZoom),
                              color: Colors.blue.withOpacity(0.3),
                              borderColor: Colors.blue,
                              borderStrokeWidth: 2,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0A1747)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF0A1747)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedLocation != null ? _onConfirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A1747),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Confirm Selection',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
