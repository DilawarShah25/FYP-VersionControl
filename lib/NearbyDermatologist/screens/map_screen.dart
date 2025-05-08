import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../services/location_service.dart';
import '../services/nearby_search_service.dart';
import '../models/clinic.dart';
import '../models/dermatologist.dart';
import '../../../Community/services/community_firebase_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  LatLng? _currentLocation;
  List<Clinic> _clinics = [];
  List<Clinic> _nearbyClinics = [];
  List<Clinic> _filteredClinics = [];
  List<Dermatologist> _dermatologists = []; // Added for Google Places API results
  bool _isLoading = true;
  MapType _currentMapType = MapType.normal;
  BitmapDescriptor? _clinicIcon;
  BitmapDescriptor? _dermatologistIcon; // Added for dermatologist markers
  final FirestoreService _firestoreService = FirestoreService();
  final NearbySearchService _nearbySearchService = NearbySearchService();
  final CommunityFirebaseService _communityService = CommunityFirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  LatLng? _selectedLocation;
  bool _showAllClinics = false;
  final TextEditingController _searchController = TextEditingController();
  String? _userRole;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    print("MapScreen initialized");
    _initialize();
  }

  Future<void> _initialize() async {
    print("Starting initialization...");
    try {
      await _setCustomMarkerIcon();
      await _setDermatologistMarkerIcon(); // Added for dermatologist markers
      await _fetchUserRole();
      await _fetchLocationAndClinics();
    } catch (e) {
      print("Initialization error: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to initialize map: $e",
            style: GoogleFonts.poppins(color: AppTheme.white),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fetchUserRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("No user logged in");
      setState(() {
        _userRole = null;
      });
      return;
    }

    try {
      final profile = await _communityService.getUserProfile(user.uid);
      setState(() {
        _userRole = profile?.role ?? null;
        print("User role fetched: $_userRole");
      });
    } catch (e) {
      print("Error fetching user role: $e");
      setState(() {
        _userRole = null;
      });
    }
  }

  Future<void> _setCustomMarkerIcon() async {
    print("Setting custom marker icon...");
    try {
      if (_clinicIcon != null) {
        print("Using cached clinic icon");
        return;
      }

      const Size size = Size(80, 80);
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

      final Paint paint = Paint()..color = AppTheme.secondaryColor;
      canvas.drawCircle(const Offset(40, 40), 40, paint);

      const IconData iconData = Icons.medical_services;
      final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      textPainter.text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: const TextStyle(
          fontSize: 40.0,
          fontFamily: 'MaterialIcons',
          color: AppTheme.white,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );

      final ui.Image image = await pictureRecorder.endRecording().toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to convert image to byte data");
      }

      final Uint8List bytes = byteData.buffer.asUint8List();

      setState(() {
        _clinicIcon = BitmapDescriptor.fromBytes(bytes);
        print("Custom marker icon set successfully");
      });
    } catch (e) {
      print("Error creating custom marker: $e");
      setState(() {
        _clinicIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      });
    }
  }

  Future<void> _setDermatologistMarkerIcon() async {
    print("Setting dermatologist marker icon...");
    try {
      _dermatologistIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      print("Dermatologist marker icon set successfully");
    } catch (e) {
      print("Error setting dermatologist marker: $e");
      _dermatologistIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<void> _fetchLocationAndClinics() async {
    print("Fetching location and clinics...");
    setState(() => _isLoading = true);

    final locationService = LocationService();
    _currentLocation = await locationService.getCurrentLocation();

    if (_currentLocation != null) {
      print(
          "Current location fetched: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}");
      try {
        // Fetch clinics from Firestore
        _clinics = await _firestoreService.getAllClinics();
        print("Firestore clinics fetched: ${_clinics.length}");
        _clinics.forEach((clinic) {
          print(
              "Clinic: ${clinic.name}, Location: (${clinic.location.latitude}, ${clinic.location.longitude})");
        });

        _nearbyClinics = await _firestoreService.getClinicsWithinRadius(
            _currentLocation!, 20);
        print("Nearby clinics (within 20km) from Firestore: ${_nearbyClinics.length}");

        // Fetch dermatologists from Google Places API
        _dermatologists = await _nearbySearchService.getNearbyDermatologists(_currentLocation!);
        print("Dermatologists fetched from Google Places API: ${_dermatologists.length}");
        _dermatologists.forEach((derm) {
          print(
              "Dermatologist: ${derm.name}, Location: (${derm.location.latitude}, ${derm.location.longitude})");
        });

        // Convert dermatologists to clinics for unified handling
        final apiClinics = _dermatologists.map((d) => Clinic(
          id: "api_${DateTime.now().millisecondsSinceEpoch}",
          name: d.name,
          address: d.address,
          location: d.location,
          userId: '',
          createdAt: Timestamp.now(),
        )).toList();

        // Combine Firestore nearby clinics with API results
        _nearbyClinics.addAll(apiClinics);
        print("Total nearby clinics after combining API results: ${_nearbyClinics.length}");

        // Update filtered clinics
        _filteredClinics = _showAllClinics ? _clinics : _nearbyClinics;
        print("Filtered clinics: ${_filteredClinics.length}");

        if (_filteredClinics.isEmpty && !_showAllClinics) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "No dermatologists found within 20km.",
                style: GoogleFonts.poppins(color: AppTheme.white),
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print("Error fetching clinics or dermatologists: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to fetch dermatologists: $e",
              style: GoogleFonts.poppins(color: AppTheme.white),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (_controller != null) {
        _controller!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 12),
        );
        print("Camera moved to current location");
      }
    } else {
      print("Failed to get current location");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to get your current location. Please enable location services and grant permissions.",
            style: GoogleFonts.poppins(color: AppTheme.white),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() => _isLoading = false);
    print("Finished fetching location and clinics");
  }

  void _toggleMapType() {
    print("Toggling map type...");
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  void _searchClinics(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        if (query.isEmpty) {
          _filteredClinics = _showAllClinics ? _clinics : _nearbyClinics;
        } else {
          final lowerQuery = query.toLowerCase();
          _filteredClinics = (_showAllClinics ? _clinics : _nearbyClinics)
              .where((clinic) =>
              clinic.name.toLowerCase().contains(lowerQuery))
              .toList();
        }
      });
    });
  }

  void _showClinicList() {
    print("Showing clinic list...");
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppTheme.white,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _showAllClinics
                            ? "All\nDermatologists"
                            : "Nearby\nDermatologists",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: _showAllClinics,
                        onChanged: (value) {
                          print("Switch toggled: Show all clinics = $value");
                          setModalState(() {
                            _showAllClinics = value;
                            _filteredClinics =
                            _showAllClinics ? _clinics : _nearbyClinics;
                            _searchController.clear();
                          });
                          setState(() {});
                        },
                        activeTrackColor:
                        AppTheme.primaryColor.withOpacity(0.3),
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  _filteredClinics.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    child: Text(
                      _showAllClinics
                          ? "No dermatologists registered in the app."
                          : "No dermatologists found nearby.",
                      style:
                      Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                      : Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _filteredClinics.length,
                      itemBuilder: (context, index) {
                        final clinic = _filteredClinics[index];
                        return GestureDetector(
                          onTap: () async {
                            print("Tapped clinic: ${clinic.name}");
                            Navigator.pop(context);
                            if (_controller != null) {
                              await _controller!.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                    clinic.location, 15),
                              );
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: AppTheme.paddingSmall,
                              horizontal: 0,
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.local_hospital,
                                color: AppTheme.secondaryColor,
                                size: 30,
                              ),
                              title: Text(
                                clinic.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                clinic.address,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<LatLng?> _screenPointToLatLng(Offset position) async {
    if (_controller == null) {
      print("Map controller is null");
      return null;
    }
    try {
      final screenCoordinate = ScreenCoordinate(
        x: position.dx.round(),
        y: position.dy.round(),
      );
      final latLng = await _controller!.getLatLng(screenCoordinate);
      return latLng;
    } catch (e) {
      print("Error converting screen point to LatLng: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to get map coordinates. Please try again.",
            style: GoogleFonts.poppins(color: AppTheme.white),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
  }

  void _onMapDoubleTapped(Offset position) async {
    if (_userRole != 'Doctor') {
      print("User role is not Doctor, ignoring double-tap");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Only doctors can register dermatologist clinics.",
            style: GoogleFonts.poppins(color: AppTheme.white),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final latLng = await _screenPointToLatLng(position);
    if (latLng == null) {
      print("Failed to convert screen point to LatLng");
      return;
    }
    print("Map double-tapped at: ${latLng.latitude}, ${latLng.longitude}");
    if (_auth.currentUser == null) {
      print("User not authenticated");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You must be logged in to register a dermatologist clinic.",
            style: GoogleFonts.poppins(color: AppTheme.white),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _selectedLocation = latLng;
      print("Selected location updated: $_selectedLocation");
    });
    _showRegisterClinicDialog(latLng);
  }

  void _onMapTapped(LatLng position) {
    print("Map single-tapped at: ${position.latitude}, ${position.longitude}");
    if (_userRole == 'Doctor') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Double-tap to select a location to register a dermatologist clinic.",
            style: GoogleFonts.poppins(color: AppTheme.white),
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showRegisterClinicDialog(LatLng position) {
    print("Showing register clinic dialog...");
    final TextEditingController nameController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    LatLng dialogPosition = position;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Register Dermatologist/Hair Specialist",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Clinic Name",
                        hintText: "e.g., City Skin Clinic",
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: "Address",
                        hintText: "e.g., 123 Main St",
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      "Selected Location: (${dialogPosition.latitude.toStringAsFixed(4)}, ${dialogPosition.longitude.toStringAsFixed(4)})",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    ElevatedButton(
                      onPressed: () async {
                        print("Use Current Location button pressed");
                        final locationService = LocationService();
                        final currentLocation =
                        await locationService.getCurrentLocation();
                        if (currentLocation != null) {
                          print(
                              "Current location fetched: ${currentLocation.latitude}, ${currentLocation.longitude}");
                          setDialogState(() {
                            dialogPosition = currentLocation;
                            _selectedLocation = currentLocation;
                          });
                          setState(() {});
                        } else {
                          print("Failed to get current location in dialog");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Failed to get current location. Please try again.",
                                style:
                                GoogleFonts.poppins(color: AppTheme.white),
                              ),
                              backgroundColor: AppTheme.errorColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text("Use Current Location"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    print("Cancel button pressed");
                    setState(() {
                      _selectedLocation = null;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    print("Register button pressed");
                    final name = nameController.text.trim();
                    final address = addressController.text.trim();

                    if (name.isEmpty || address.isEmpty) {
                      print(
                          "Validation failed: Name or address is empty");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Please fill in all fields.",
                            style: GoogleFonts.poppins(
                                color: AppTheme.white),
                          ),
                          backgroundColor: AppTheme.errorColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    setDialogState(() {
                      isSaving = true;
                    });

                    final clinic = Clinic(
                      id: DateTime.now()
                          .millisecondsSinceEpoch
                          .toString(),
                      name: name,
                      address: address,
                      location: dialogPosition,
                      userId: _auth.currentUser!.uid,
                      createdAt: Timestamp.now(),
                    );

                    try {
                      print("Saving clinic to Firestore: ${clinic.name}");
                      await _firestoreService.addClinic(clinic);
                      print("Clinic saved successfully");
                      setState(() {
                        _selectedLocation = null;
                      });
                      Navigator.pop(context);
                      await _fetchLocationAndClinics();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Dermatologist clinic registered successfully!",
                            style: GoogleFonts.poppins(
                                color: AppTheme.white),
                          ),
                          backgroundColor: AppTheme.secondaryColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      print("Error saving clinic: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Failed to register dermatologist clinic: $e",
                            style: GoogleFonts.poppins(
                                color: AppTheme.white),
                          ),
                          backgroundColor: AppTheme.errorColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } finally {
                      setDialogState(() {
                        isSaving = false;
                      });
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor),
                    ),
                  )
                      : Text(
                    "Register",
                    style:
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70.0),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Dermatologists',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 20.0,
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.white),
            onPressed: () {
              print("Refresh button pressed");
              _fetchLocationAndClinics();
            },
            tooltip: "Refresh Dermatologists",
          ),
          IconButton(
            icon: Icon(
              _currentMapType == MapType.normal ? Icons.satellite : Icons.map,
              color: AppTheme.white,
            ),
            onPressed: _toggleMapType,
            tooltip: "Toggle Map Type",
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _controller?.dispose();
    print("Disposing MapScreen...");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Building MapScreen with ${_filteredClinics.length} clinic markers");
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: GestureDetector(
              onDoubleTapDown: _userRole == 'Doctor'
                  ? (TapDownDetails details) {
                _onMapDoubleTapped(details.localPosition);
              }
                  : null,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation ?? const LatLng(0.0, 0.0),
                  zoom: 12,
                ),
                mapType: _currentMapType,
                onMapCreated: (controller) {
                  _controller = controller;
                  print("Map created successfully");
                  if (_currentLocation != null) {
                    _controller!.animateCamera(
                      CameraUpdate.newLatLngZoom(_currentLocation!, 12),
                    );
                  }
                },
                onTap: _onMapTapped,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                padding: const EdgeInsets.only(top: 100.0, right: 10.0),
                markers: {
                  if (_currentLocation != null)
                    Marker(
                      markerId: const MarkerId('current_location'),
                      position: _currentLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue),
                      infoWindow: const InfoWindow(title: 'You are here'),
                    ),
                  if (_selectedLocation != null && _userRole == 'Doctor')
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: _selectedLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen),
                      infoWindow: const InfoWindow(title: 'Selected Location'),
                    ),
                  ..._filteredClinics.map((c) {
                    print("Adding marker for ${c.name} at ${c.location}");
                    return Marker(
                      markerId: MarkerId(c.id),
                      position: c.location,
                      icon: _clinicIcon ??
                          BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed),
                      infoWindow: InfoWindow(
                        title: c.name,
                        snippet: c.address,
                      ),
                    );
                  }),
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingMedium,
                vertical: AppTheme.paddingSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _searchClinics,
                      decoration: InputDecoration(
                        hintText: "Search for a dermatologist...",
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.black54,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.paddingMedium,
                          vertical: AppTheme.paddingSmall,
                        ),
                      ),
                      style: GoogleFonts.poppins(color: Colors.black87),
                    ),
                  ),
                  if (_userRole == 'Doctor')
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.paddingSmall),
                      child: Container(
                        decoration: AppTheme.cardDecoration,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.paddingMedium,
                            vertical: AppTheme.paddingSmall,
                          ),
                          child: Text(
                            "Double-tap to select a location",
                            style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      "Loading dermatologists...",
                      style: GoogleFonts.poppins(
                        color: AppTheme.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Floating action button pressed");
          _showClinicList();
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.list, color: AppTheme.white),
        tooltip: "View Dermatologist List",
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}