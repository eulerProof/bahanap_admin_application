import 'dart:async';
import 'dart:convert';
import 'package:bahanap_admin_application/pages/mobile_dashboard.dart';
import 'package:bahanap_admin_application/pages/rescuers.dart';
import 'package:bahanap_admin_application/pages/users.dart';
import 'package:bahanap_admin_application/pages/received_json_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:bahanap_admin_application/pages/sidebar_navigation.dart';
import 'operations.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final rescuers = [
    "Roberto",
    "John",
    "Sergei",
    "Joshua",
    "BJ",
    "Achilles",
    "Paulo",
    "Ben"
  ];

  Map<String, String> assignedRescuers = {}; // userId -> rescuerName
  Map<String, bool> rescuerAvailability =
      {};
  LatLng? userLocation;
  Marker? _userMarker;
  final List<Marker> _markers = [];
  double _currentZoom = 13.0;
  String _responseMessage = '';
  StreamSubscription<Position>? _positionStreamSubscription;
  String _username = '';
  double _latitude = 0;
  double _longitude = 0;
  late ReceivedJSONProvider receivedProvider;
  @override
  void initState() {
    super.initState();
    receivedProvider =
        Provider.of<ReceivedJSONProvider>(context, listen: false);
    _initializeMarkers();
    // _fetchCurrentLocation();
    // _startLocationUpdates();
    _fetchLocationFromModule();
    refresh();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void refresh() async {
    await _fetchLocationFromModule();
    _initializeLorawanMarker();
  }
  Future<void> _assignRescuer(
      String rescuer, String userId, double lat, double lon) async {
    // Send JSON to ESP32
    try {
      final payload = {"latitude": lat, "longitude": lon, "uid": rescuer};
      const esp32IP = "192.168.4.2";
      await http
          .post(
            Uri.parse('http://$esp32IP/message'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 3));

      // Save assignment in Firestore
      await FirebaseFirestore.instance
          .collection("assignments")
          .doc(userId)
          .set({
        "rescuer": rescuer,
        "lat": lat,
        "lon": lon,
        "timestamp": FieldValue.serverTimestamp(),
      });

      // Update local state
      setState(() {
        assignedRescuers[userId] = rescuer;
        rescuerAvailability[rescuer] = false;
      });

      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Rescuer Assigned"),
          content: Text("Rescuer: $rescuer\nRescuee Coordinates: $lat, $lon"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Assignment error: $e");
    }
  }
  Future<void> _selectRescuer(String userId, double lat, double lon) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.3,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(43),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Rescuers",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rescuers.length,
                      itemBuilder: (context, index) {
                        final rescuerName = rescuers[index];
                        final isAvailable =
                            rescuerAvailability[rescuerName] ?? true;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text(rescuerName,
                                      style: const TextStyle(fontSize: 18))),
                              ElevatedButton(
                                onPressed: isAvailable
                                    ? () {
                                        _assignRescuer(
                                            rescuerName, userId, lat, lon);
                                        Navigator.of(context).pop();
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isAvailable
                                      ? const Color(0XFF2294C9)
                                      : Colors.grey,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5)),
                                ),
                                child: Text(
                                    isAvailable ? "Assign Rescuer" : "Busy",
                                    style:
                                        const TextStyle(color: Colors.white)),
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
          );
        });
      },
    );
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
      const String esp32IP = "192.168.4.2";
      final response = await http.get(Uri.parse('http://$esp32IP/lastmessage'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          data["status"] = data["status"] ?? "unassigned";
          receivedProvider.addMessage(data);
        }
      } else {
        debugPrint("Failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching message: $e");
    }
  }
  

  void _initializeLorawanMarker() {
  try {
    // Clear all old LoRaWAN markers first
    _markers.removeWhere((m) {
      return m.key is ValueKey &&
             (m.key as ValueKey).value.toString().contains("lorawan");
    });

    // Loop through ALL messages received
    for (var msg in receivedProvider.messages) {
      final username = msg["id"] ?? "Unknown";
      final lat = (msg["lat"] ?? 0).toDouble();
      final lon = (msg["lon"] ?? 0).toDouble();

      // Safety check
      if (lat == 0 || lon == 0) continue;

      _markers.add(
        Marker(
          key: ValueKey("lorawan_${username}_${lat.toString()}_${lon.toString()}"),
          width: 100.0,
          height: 100.0,
          point: LatLng(lat, lon),
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context)
              .showSnackBar(
                const SnackBar(
                  content: Text(
                    "You tapped this marker")),
              );
              _selectRescuer(username, lat, lon);
            },
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
                child: const CircleAvatar(
                  radius: 15,
                  backgroundImage: AssetImage('assets/images/dgfdfdsdsf2.jpg'),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                  fontFamily: 'SfPro',
                ),
              ),
            ],
          ),
          )
        ),
      );
    }

    setState(() {});
  } catch (e) {
    setState(() {
      _responseMessage = "Error initializing LoRaWAN markers: $e";
    });
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
      _mapController.move(userLocation!, 13.0);
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
          Expanded(
            flex: 1,
            child: SidebarNavigation(activePage: "Map"),
          ),
          Expanded(
            flex: 3,
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
                      maxZoom: 16, // <-- REQUIRED FIX
                      minZoom: 12,
                    ),
                    children: [
                      TileLayer(
                        tileProvider: AssetTileProvider(),
                        urlTemplate: 'tiles2/{z}/{x}/{y}.png',
                        maxZoom: 16,
                        minZoom: 12,
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
                        onPressed: () {
                          refresh();
                        }, //Initialize marker
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(15),
                          backgroundColor: Colors.black,
                          textStyle: const TextStyle(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10), // Rounded corners
                            side: const BorderSide(
                                color: Colors.blue, width: 0.2), // Border
                          ),
                        ),
                        child: const Text("Refresh"),
                      ),
                      IconButton(
                        icon: const Icon(Icons.zoom_in),
                        onPressed: () {
                          setState(() {
                            _currentZoom = (_currentZoom + 1).clamp(1.0, 16.0);
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
                            _currentZoom = (_currentZoom - 1).clamp(1.0, 16.0);
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
                              _currentZoom = 13.0;
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
