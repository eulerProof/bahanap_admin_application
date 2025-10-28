import 'dart:async';
import 'dart:convert';
import 'package:bahanap_admin_application/pages/mobile_dashboard.dart';
import 'package:bahanap_admin_application/pages/rescuers.dart';
import 'package:bahanap_admin_application/pages/users.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'operations.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;


class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? userLocation;
  Marker? _userMarker;
  final List<Marker> _markers = [];
  double _currentZoom = 13.0;
  String _responseMessage = '';
  StreamSubscription<Position>? _positionStreamSubscription;
  String _username = '';
  double _latitude = 0;
  double _longitude = 0;
  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    // _fetchCurrentLocation();
    // _startLocationUpdates();
    _fetchLocationFromModule();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }
  void refresh () async {
    await _fetchLocationFromModule();
    _initializeLorawanMarker();
  }
  Future<void> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        userLocation = newLocation;
        _updateUserMarker(newLocation);
        uploadLocation(newLocation);
      });
    } catch (e) {
      print("Error fetching current location: $e");
      _showErrorDialog('Unable to fetch current location.');
    }
  }
  
  Future<void> _fetchLocationFromModule() async {
  try {
    String esp32IP = "192.168.4.2";
    final response = await http.get(Uri.parse('http://$esp32IP/lastmessage'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body); // Parse JSON

      setState(() {
        // Assign extracted fields to variables
        _username = data["id"] ?? "Unknown";
        _latitude = data["lat"]?.toDouble() ?? 0.0;
        _longitude = data["lon"]?.toDouble() ?? 0.0;
        _responseMessage = "✅ Data received successfully!";
      });
    } else {
      setState(() {
        _responseMessage =
            'Failed to receive message. Status: ${response.statusCode}';
      });
    }
  } catch (e) {
    setState(() {
      _responseMessage = 'Error: $e';
    });
  }
}

  void _initializeLorawanMarker() async {
    try {
      _markers.add(
              Marker(
                width: 100.0,
                height: 100.0,
                point: LatLng(_latitude, _longitude),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red,
                          width: 3.0,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundImage:
                            const AssetImage('assets/images/dgfdfdsdsf2.jpg'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                        fontFamily: 'SfPro',
                      ),
                    ),
                  ],
                ),
              ),
        );
      
      setState(() {});
    }
    catch (e){
      _responseMessage = "Error initializing markers: $e";
    }
  }
  void _initializeMarkers() async {
    _markers.clear();
    final String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('profiles').get();

      for (var doc in querySnapshot.docs) {
        String coordinates = doc['Coordinates'] ?? "0.0, 0.0";
        String fullName = doc['Name'] ?? "User";
        String uid = doc.id;

        if (uid == currentUserUid) continue;

        List<String> latLng = coordinates.split(',');
        double latitude = double.tryParse(latLng[0].trim()) ?? 0.0;
        double longitude = double.tryParse(latLng[1].trim()) ?? 0.0;
        String userName = fullName.split(' ').first;

        _markers.add(
          Marker(
            width: 100.0,
            height: 100.0,
            point: LatLng(latitude, longitude),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green,
                      width: 3.0,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundImage:
                        const AssetImage('assets/images/dgfdfdsdsf2.jpg'),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0,
                    fontFamily: 'SfPro',
                  ),
                ),
              ],
            ),
          ),
        );
      }
      setState(() {});
    } catch (e) {
      print("Error initializing markers: $e");
      _showErrorDialog('Error loading markers.');
    }
  }

  void _updateUserMarker(LatLng location) {
    if (_userMarker != null) {
      _markers.remove(_userMarker);
    }
    /*
    final imageProvider = Provider.of<CustomImageProvider>(context, listen: false);
    final imageFile = imageProvider.imageFile;
    */

    _userMarker = Marker(
      width: 40.0,
      height: 40.0,
      point: location,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.blue,
            width: 3.0,
          ),
        ),
        child: CircleAvatar(
          radius: 20,
          // Use local image if you don't have a custom image provider:
          backgroundImage: const AssetImage('assets/images/dgfdfdsdsf2.jpg'),
        ),
      ),
    );

    _markers.add(_userMarker!);
  }

  void _startLocationUpdates() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        userLocation = newLocation;
        _updateUserMarker(newLocation);
        uploadLocation(newLocation);
      });
    });
  }

  Future<void> uploadLocation(LatLng loc) async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      print("Error: User not logged in.");
      return;
    }
    try {
      String formattedLocation = "Lat: ${loc.latitude}, Lon: ${loc.longitude}";
      await FirebaseFirestore.instance.collection("profiles").doc(uid).set({
        "LiveCoordinates": formattedLocation,
      }, SetOptions(merge: true));
      print("Location updated successfully");
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  Future<void> _searchLocation() async {
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(query);

        debugPrint("Geocoding result: $locations");

        if (locations.isEmpty) {
          _showErrorDialog('No locations found for "$query".');
        } else {
          Location location = locations.first;
          debugPrint(
              "Location found: ${location.latitude}, ${location.longitude}");

          _mapController.move(
              LatLng(location.latitude, location.longitude), 13.0);
        }
      } catch (e) {
        debugPrint("Geocoding error: $e");
        _showErrorDialog('Error: $e');
      }
    } else {
      _showErrorDialog('Please enter a valid address to search.');
    }
  }

  void _moveToUserLocation() {
    if (userLocation != null) {
      _mapController.move(userLocation!, 18.0);
    } else {
      _showErrorDialog('User location is not available.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Ok"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x0032ade6),
      body: Row(
        children: [
          SafeArea(
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.24,
              decoration: const BoxDecoration(
                color: Color(0xff32ade6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(40, 45, 40, 0),
                    child: SizedBox(
                      height: 82,
                      child: Text(
                        "BaHanap",
                        style: TextStyle(
                          fontSize: 62,
                          fontFamily: 'Gilroy',
                          color: Colors.white,
                          letterSpacing: -4.0,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 30),
                    child: Container(
                      width: 138,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xff3d3d3d),
                        borderRadius: BorderRadius.circular(37),
                      ),
                      child: const Center(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.support_agent,
                              size: 15,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "Administrator",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapPage(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xff2294C9),
                      ),
                      width: MediaQuery.sizeOf(context).width * 0.24,
                      padding: const EdgeInsets.fromLTRB(44, 10, 0, 10),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.map,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Map",
                            style: TextStyle(
                              fontFamily: "SFPro",
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OperationsPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.24,
                      padding: const EdgeInsets.fromLTRB(44, 10, 0, 10),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.track_changes,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Operations",
                            style: TextStyle(
                              fontFamily: "SFPro",
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UsersPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.24,
                      padding: const EdgeInsets.fromLTRB(44, 10, 0, 10),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.supervised_user_circle,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Users",
                            style: TextStyle(
                              fontFamily: "SFPro",
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RescuersPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.24,
                      padding: const EdgeInsets.fromLTRB(44, 10, 0, 10),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Rescuers",
                            style: TextStyle(
                                fontFamily: "SFPro",
                                fontSize: 20,
                                color: Colors.white),
                          )
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MobileDashboardPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.24,
                      padding: const EdgeInsets.fromLTRB(44, 10, 0, 10),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.dashboard,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Mobile App Dashboard",
                            style: TextStyle(
                              fontFamily: "SFPro",
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.24,
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 50),
                      child: Center(
                        child: SizedBox(
                          height: 41,
                          width: 162,
                          child: ElevatedButton(
                            onPressed: () {
                              refresh();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0XFF2294C9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(37),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.logout, size: 20),
                                SizedBox(width: 19),
                                Text(
                                  "Log Out",
                                  style: TextStyle(
                                    fontFamily: "SFPro",
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 100,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.fromLTRB(40, 15, 15, 15),
                  child: const Text(
                    "Map",
                    style: TextStyle(
                      fontFamily: "SFPro",
                      fontSize: 43,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2294C9),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.location_searching_outlined,
                        color: Color(0xffafafaf),
                      ),
                      labelText: 'Search Map',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onFieldSubmitted: (_) => _searchLocation(),
                  ),
                ),
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: userLocation ?? LatLng(10.7202, 122.5621),
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(markers: _markers),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      
                        const SizedBox(
                          width: 20,
                        ),
                      ElevatedButton(
                        onPressed: (){
                          refresh();
                        },//Initialize marker 
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(15),
                          backgroundColor: Colors.black,
                          textStyle: const TextStyle(
                            color: Colors.white
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Rounded corners
                            side: const BorderSide(color: Colors.blue, width: 0.2), // Border
                          ),

                        ),
                        child: const Text("Refresh"),
                        
                      ),
                      IconButton(
                        icon: const Icon(Icons.zoom_in),
                        onPressed: () {
                          setState(() {
                            _currentZoom = (_currentZoom + 1).clamp(1.0, 18.0);
                            _mapController.move(
                                userLocation ?? _mapController.camera.center,
                                _currentZoom);
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.zoom_out),
                        onPressed: () {
                          setState(() {
                            _currentZoom = (_currentZoom - 1).clamp(1.0, 18.0);
                            _mapController.move(
                                userLocation ?? _mapController.camera.center,
                                _currentZoom);
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: () {
                          if (userLocation != null) {
                            setState(() {
                              _currentZoom = 18.0;
                              _mapController.move(userLocation!, _currentZoom);
                            });
                          } else {
                            _showErrorDialog('User location is not available.');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
