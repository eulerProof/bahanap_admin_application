import 'dart:async';
import 'dart:convert';
import 'package:bahanap_admin_application/pages/received_json_provider.dart';
import 'package:bahanap_admin_application/pages/sidebar_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // Local State
  double _currentZoom = 13.0;
  LatLng? userLocation;
  Marker? _userMarker;
  List<Marker> _evacuationMarkers = [];
  bool _isAddingEvacuationMarker = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeEvacuationMarkers();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 🟢 HELPER: Build Rescuer Markers (Dynamic)
  // ---------------------------------------------------------------------------
  List<Marker> _buildRescuerMarkers(List<Map<String, dynamic>> locations) {
    return locations.map((r) {
      final id = r["id"] ?? "Unknown";
      final lat = (r["lat"] ?? 0).toDouble();
      final lon = (r["lon"] ?? 0).toDouble();

      if (lat == 0 || lon == 0) return null;

      return Marker(
        key: ValueKey("rescuer_$id"),
        width: 90,
        height: 90,
        point: LatLng(lat, lon),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 3),
                color: Colors.white,
              ),
              child: const CircleAvatar(
                radius: 14,
                backgroundImage: AssetImage('assets/images/rescuer.png'),
              ),
            ),
            const SizedBox(height: 4),
                Text(
                  "$id (Rescuer)",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0,
                    fontFamily: 'SfPro',
                  ),
                ),
            
          ],
        ),
      );
    }).whereType<Marker>().toList(); 
  }

  // ---------------------------------------------------------------------------
  // 🟢 HELPER: Build Victim Markers (Dynamic)
  // ---------------------------------------------------------------------------
  List<Marker> _buildLorawanMarkers(List<Map<String, dynamic>> messages, Map<String, String> assignedMap) {
    List<Marker> markers = [];
    
    for (var msg in messages) {
      final username = msg["id"] ?? "Unknown";
      final lat = (msg["lat"] ?? 0).toDouble();
      final lon = (msg["lon"] ?? 0).toDouble();
      
      if (lat == 0 || lon == 0 || username == "Unknown") continue;

      final isAssigned = assignedMap.containsKey(username);

      markers.add(
        Marker(
          key: ValueKey("lora_${username}_${lat}_${lon}"),
          width: 100.0,
          height: 100.0,
          point: LatLng(lat, lon),
          child: GestureDetector(
            onTap: () {
              if (isAssigned) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Already Assigned"),
                    content: Text(
                      "This request is already assigned to ${assignedMap[username]}.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              } else {
                _selectRescuer(username, lat, lon);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAssigned ? Colors.blueGrey : Colors.red,
                      width: 3.0,
                    ),
                    color: Colors.white,
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
          ),
        ),
      );
    }
    return markers;
  }

  // ---------------------------------------------------------------------------
  // 🟡 EXISTING LOGIC (Preserved)
  // ---------------------------------------------------------------------------

  Future<void> _assignRescuer(String rescuer, String userId, double lat, double lon, String rescuerName) async {
    final provider = Provider.of<ReceivedJSONProvider>(context, listen: false);
    try {
      final payload = {"latitude": lat, "longitude": lon, "rescuer": rescuer, "uid": userId};
      const esp32IP = "192.168.4.3";
      
      await http.post(
        Uri.parse('http://$esp32IP/assign'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));
      
      provider.assignRescuer(userId, rescuerName);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Rescuer Assigned"),
          content: Text("Rescuer: $rescuerName\nRescuee Coordinates: $lat, $lon"),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))],
        ),
      );

      await FirebaseFirestore.instance.collection("assignments").doc(userId).set({
        "rescuerId": rescuer, "lat": lat, "lon": lon,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Assignment error: $e");
    }
  }

  Future<void> _selectRescuer(String userId, double lat, double lon) async {
    final provider = Provider.of<ReceivedJSONProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.3,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(43),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Rescuers", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.rescuers.length,
                      itemBuilder: (context, index) {
                        final rescuerName = provider.rescuers[index]["name"];
                        final rescuerId = provider.rescuers[index]["id"];
                        final isAvailable = provider.rescuerAvailability[rescuerId] ?? true;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(children: [
                                  Text(rescuerName!, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 10),
                                  Text(isAvailable ? "Available" : "Busy",
                                    style: TextStyle(fontSize: 13, color: isAvailable ? Colors.green : Colors.red)),
                                ]),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _assignRescuer(rescuerId!, userId, lat, lon, rescuerName!);
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0XFF2294C9),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                ),
                                child: const Text("Assign Rescuer", style: TextStyle(color: Colors.white)),
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
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        userLocation = newLocation;
        _updateUserMarker(newLocation);
        uploadLocation(newLocation);
      });
    } catch (e) {
      debugPrint("Error fetching current location: $e");
    }
  }

  void _startLocationUpdates() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2),
    ).listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        userLocation = newLocation;
        _updateUserMarker(newLocation);
        uploadLocation(newLocation);
      });
    });
  }

  void _updateUserMarker(LatLng location) {
    setState(() {
      _userMarker = Marker(
        width: 40.0, height: 40.0, point: location,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 3.0),
          ),
          child: const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/images/dgfdfdsdsf2.jpg'),
          ),
        ),
      );
    });
  }

  void _initializeEvacuationMarkers() async {
    final snapshot = await FirebaseFirestore.instance.collection('evacuation_markers').get();
    List<Marker> newMarkers = [];
    for (var i = 0; i < snapshot.docs.length; i++) {
      final data = snapshot.docs[i].data();
      final lat = data['lat']?.toDouble();
      final lon = data['lon']?.toDouble();
      final name = data['name'] ?? "Evacuation Center";
      if (lat == null || lon == null) continue;
      newMarkers.add(
        Marker(
          key: ValueKey("evac_${lat}_${lon}_$i"),
          width: 80, height: 80, point: LatLng(lat, lon),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 3.0),
                  color: Colors.white,
                ),
                child: const Center(child: Icon(Icons.house, size: 20, color: Colors.green)),
              ),
              const SizedBox(height: 2),
              Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.0, fontFamily: 'SfPro')),
            ],
          ),
        ),
      );
    }
    setState(() { _evacuationMarkers = newMarkers; });
  }

  Future<void> uploadLocation(LatLng loc) async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    try {
      String formattedLocation = "Lat: ${loc.latitude}, Lon: ${loc.longitude}";
      await FirebaseFirestore.instance.collection("profiles").doc(uid).set({
        "LiveCoordinates": formattedLocation,
      }, SetOptions(merge: true));
    } catch (e) { debugPrint("Error updating location: $e"); }
  }

  Future<void> _searchLocation() async {
    String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(query);
        if (locations.isEmpty) {
          _showErrorDialog('No locations found for "$query".');
        } else {
          Location location = locations.first;
          _mapController.move(LatLng(location.latitude, location.longitude), 13.0);
        }
      } catch (e) { _showErrorDialog('Error: $e'); }
    } else {
      _showErrorDialog('Please enter a valid address to search.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Ok"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x0032ade6),
      body: Row(
        children: [
          Expanded(flex: 1, child: SidebarNavigation(activePage: "Map")),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Container(
                  height: 100,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.fromLTRB(40, 15, 15, 15),
                  child: const Text("Map", style: TextStyle(fontFamily: "SFPro", fontSize: 43, fontWeight: FontWeight.bold, color: Color(0xff2294C9))),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_searching_outlined, color: Color(0xffafafaf)),
                      labelText: 'Search Map',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onFieldSubmitted: (_) => _searchLocation(),
                  ),
                ),
                Expanded(
                  child: Consumer<ReceivedJSONProvider>(
                    builder: (context, provider, child) {
                      
                      // Combine all markers dynamically
                      List<Marker> finalMarkers = [
                        if (_userMarker != null) _userMarker!,
                        ..._evacuationMarkers,
                        ..._buildRescuerMarkers(provider.rescuerLocations),
                        ..._buildLorawanMarkers(provider.messages, provider.assignedRescuers),
                      ];

                      return FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: userLocation ?? const LatLng(10.7202, 122.5621),
                          initialZoom: 13.0,
                          maxZoom: 16,
                          minZoom: 12,
                          onTap: (tapPosition, point) async {
                            if (_isAddingEvacuationMarker) {
                              final TextEditingController _nameController = TextEditingController();
                              final String? evacName = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Enter Evacuation Center Name'),
                                  content: TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(hintText: 'Name'),
                                    autofocus: true,
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_nameController.text.trim().isNotEmpty) {
                                          Navigator.of(context).pop(_nameController.text.trim());
                                        }
                                      },
                                      child: const Text("Add"),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (evacName != null) {
                                provider.addEvacuationMarker(point, name: evacName);
                                _initializeEvacuationMarkers(); 
                              }
                            }
                          },
                        ),
                        children: [
                          // 🟢 RESTORED OFFLINE TILE LAYER
                          TileLayer(
                            // This ensures we use offline assets.
                            tileProvider: AssetTileProvider(),
                            // 🛑 PLEASE VERIFY THIS PATH MATCHES YOUR ASSETS FOLDER
                            urlTemplate: 'tiles2/{z}/{x}/{y}.png', 
                          ),
                          MarkerLayer(
                            markers: finalMarkers,
                          ),
                        ],
                      );
                    },
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
                      
                      const SizedBox(width: 15),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isAddingEvacuationMarker = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tap a location on the map to add marker')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(15),
                          backgroundColor: Colors.orange,
                          textStyle: const TextStyle(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Add Evacuation Marker", style: const TextStyle(color: Colors.white),),
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