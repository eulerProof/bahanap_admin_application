import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class ReceivedJSONProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];
  Timer? _pollingTimer;
  String? _lastConfirmedId;
  final List<Map<String, dynamic>> _rescuerLocations = [];
  final List<Map<String, dynamic>> _evacuationMarkers = [];
  // We use this to prevent processing the exact same packet processing multiple times in one millisecond
  String? _lastProcessedRawJson; 

  // ----------------------- 🟢 Getters -----------------------
  List<Map<String, dynamic>> get messages => _messages;

  final List<Map<String, dynamic>> _finishedOperations = [];
  List<Map<String, dynamic>> get finishedOperations => List.unmodifiable(_finishedOperations);


  List<Map<String, dynamic>> get rescuerLocations => List.unmodifiable(_rescuerLocations);

  // Rescuers Data...
  final List<Map<String, String>> _rescuers = [];
  final List<Map<String, String>> _users = []; // The Rescuees
  final List<Map<String, String>> _blacklisted = [];
  final Map<String, String> _assignedRescuers = {}; 
  final Map<String, bool> _rescuerAvailability = {}; 
  List<Map<String, String>> get rescuers => List.unmodifiable(_rescuers);
  List<Map<String, String>> get users => List.unmodifiable(_users);
  List<Map<String, String>> get blacklisted => List.unmodifiable(_blacklisted);
  ReceivedJSONProvider() {
    _startPolling();
    fetchAllProfiles();
  }


  Future<void> fetchAllProfiles() async {
    try {
      // Get ALL profiles at once (One network call is cheaper than 3)
      final snapshot = await FirebaseFirestore.instance.collection('profiles').get();

      // Clear existing lists so we don't duplicate on refresh
      _rescuers.clear();
      _users.clear();
      _blacklisted.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final role = data['role'] ?? "Rescuee"; // Default to Rescuee if missing
        
        final userMap = {
          "name": data['Name']?.toString() ?? "Unknown",
          "phone": data['PhoneNumber']?.toString() ?? "No Phone",
          "id": data["uid"].toString(),
          "email": data['email']?.toString() ?? "",
        };

        // 🟢 SORT INTO LISTS
        if (role == 'Rescuer') {
          _rescuers.add(userMap);
          _rescuerAvailability[doc.id] = true; 
        } else if (role == 'Rescuee') {
          _users.add(userMap);
        } else if (role == 'Blacklisted') {
          _blacklisted.add(userMap);
        }
      }

      notifyListeners(); // Update UI
      debugPrint("Loaded: ${_rescuers.length} Rescuers, ${_users.length} Users, ${_blacklisted.length} Blacklisted.");
    } catch (e) {
      debugPrint("Error fetching profiles: $e");
    }
  }
  
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchSOS();
      _fetchAssignment();
      _fetchRescuerLocation();
      _fetchLastMessage();
    });
  }

  void _handleConfirmed(Map<String, dynamic> confirmMsg) {
    final id = confirmMsg["id"];
    if (id == null) return;

    if (_lastConfirmedId == id) return;
    _lastConfirmedId = id;
    final existingIndex = _messages.indexWhere((m) => m["id"] == id);
    
    Map<String, dynamic> originalData = {};
    if (existingIndex != -1) {
      originalData = _messages[existingIndex];
      // Remove from active list
      _messages.removeAt(existingIndex);
    } else {
      // If not in active list, we can't do much, but we proceed to finish just in case
      debugPrint("Warning: Confirmed ID $id was not found in active messages.");
    }

    // B. Add to finished operations with the CRITICAL unique identifiers
    _finishedOperations.add({
      ...confirmMsg,
      "completedAt": DateTime.now().toIso8601String(),
      "sos_timestamp": originalData["timestamp"], 
      "_rawJson": originalData["_rawJson"], 
      "lat": originalData["lat"],
      "lon": originalData["lon"],
    });

    notifyListeners();
  }
  int _victimCounter = 0;

  bool _isLocationClose(double? lat1, double? lon1, double? lat2, double? lon2) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) return false;
    // 0.0001 degrees is approx 11 meters. 
    return (lat1 - lat2).abs() < 0.0001 && (lon1 - lon2).abs() < 0.0001;
  }

  Future<void> _fetchSOS() async {
    try {
      const esp32IP = "192.168.4.3";
      final response = await http.get(Uri.parse('http://$esp32IP/lastsos'));

      if (response.statusCode != 200) return;
      final rawBody = response.body.trim();
      if (rawBody.isEmpty || rawBody == "{}") return;

      final data = jsonDecode(rawBody);
      data["_rawJson"] = rawBody; 

      final incomingId = data["id"] ?? "Victim";
      final incomingTimestamp = data["timestamp"]?.toString();
      final double? incomingLat = double.tryParse(data["lat"]?.toString() ?? "");
      final double? incomingLon = double.tryParse(data["lon"]?.toString() ?? "");

      final isFinished = _finishedOperations.any((op) => 
          op["_rawJson"] == rawBody || 
          (incomingTimestamp != null && op["sos_timestamp"] == incomingTimestamp)
      );

      if (isFinished) return; 
      final isExactDuplicate = _messages.any((m) => m["_rawJson"] == rawBody);
      if (isExactDuplicate) return;

      if (incomingId != "Victim") {
        final existingIndex = _messages.indexWhere((m) => m["id"] == incomingId);
        if (existingIndex != -1) {
          // Update existing named user
          data["status"] = _messages[existingIndex]["status"]; 
          _messages[existingIndex] = data; 
          notifyListeners();
        } else {
          addMessage(data); 
        }
        return; 
      }

      if (incomingId == "Victim") {
        final existingVictimIndex = _messages.indexWhere((m) {
           final mId = m["id"].toString();
           
           if (!mId.startsWith("Victim")) return false; // Skip named users

           final mLat = double.tryParse(m["lat"]?.toString() ?? "");
           final mLon = double.tryParse(m["lon"]?.toString() ?? "");
           
           return _isLocationClose(incomingLat, incomingLon, mLat, mLon);
        });

        if (existingVictimIndex != -1) {
           // 🟢 FOUND MATCH: It's the same victim, just updated GPS.
           // Update their data but KEEP THE OLD ID (e.g. "Victim 1")
           data["id"] = _messages[existingVictimIndex]["id"];
           data["status"] = _messages[existingVictimIndex]["status"];
           
           _messages[existingVictimIndex] = data; // Update in place
           notifyListeners();
           return; 
        }

        // If no match found, THEN it is truly a new victim.
        _victimCounter++;
        data["id"] = "Victim $_victimCounter";
        addMessage(data);
      }

    } catch (e) {
      debugPrint("Error in _fetchSOS: $e");
    }
  }
  // ---------------------------------------------------------------------------
  // 🟢 3. Add Message (Simplified)
  // ---------------------------------------------------------------------------
  void addMessage(Map<String, dynamic> message) {
    try {
      if (message["type"] == "CONFIRMED") {
        _handleConfirmed(message);
        return;
      }

      // Default status if missing
      if (!message.containsKey("status")) {
        message["status"] = "unassigned";
      }

      // Deduplication was already handled in _fetchSOS, so we just add safely.
      final msgId = message["id"];
      
      // Safety check: Don't add if ID somehow already exists (race condition)
      final index = _messages.indexWhere((m) => m["id"] == msgId);
      if (index == -1) {
        _messages.add(message);
        notifyListeners();
      } else {
        // If it exists here, it means logic fell through, just update it.
        _messages[index] = message;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error in addMessage: $e');
    }
  }

  // ... (Keep your existing updateStatus, assignRescuer, etc. methods exactly as they were) ...
  
  // ... (Keep your dispose, clear, evacuationMarkers, etc.) ...
  
  // Boilerplate needed for code to run:
  void updateStatus(String userId, String status) {
    final index = _messages.indexWhere((m) => m['id'] == userId);
    if (index != -1) {
      _messages[index]['status'] = status;
      notifyListeners();
    }
  }
   Map<String, bool> get rescuerAvailability => Map.unmodifiable(_rescuerAvailability);
   Map<String, String> get assignedRescuers => Map.unmodifiable(_assignedRescuers);
   
   void assignRescuer(String userId, String rescuerName) {
    _assignedRescuers[userId] = rescuerName;
    _rescuerAvailability[rescuerName] = false;
    updateStatus(userId, "assigned");
    notifyListeners();
   }
   
   void unassignRescuer(String userId) {
    final rescuerName = _assignedRescuers[userId];
    if (rescuerName != null) {
      _rescuerAvailability[rescuerName] = true;
      _assignedRescuers.remove(userId);
      updateStatus(userId, "unassigned");
      notifyListeners();
    }
   }
   
   void clear() {
    _messages.clear();
    notifyListeners();
   }
   
   // (Include the rest of your methods like _fetchAssignment, _fetchRescuerLocation, _fetchLastMessage etc.)
   // Ensure those methods call addMessage or _handleConfirmed appropriately.
   
     Future<void> _fetchLastMessage() async {
     try {
       const esp32IP = "192.168.4.3";
       final response = await http.get(Uri.parse('http://$esp32IP/lastmessage'));

       if (response.statusCode != 200) return;
       final raw = response.body.trim();
       if (raw.isEmpty) return;
       
       // Dedupe repeating confirmed messages
       if (_lastProcessedRawJson == raw) return;
       _lastProcessedRawJson = raw;

       final data = jsonDecode(raw);
       if (data["type"] == "CONFIRMED") {
         _handleConfirmed(data);
       }
     } catch (e) {
       debugPrint("Error fetching last message: $e");
     }
   }

  
  // (Include _fetchAssignment and _fetchRescuerLocation here...)
  Future<void> _fetchAssignment() async {
    try {
      const esp32IP = "192.168.4.3";
      final response = await http.get(Uri.parse('http://$esp32IP/lastassign'));

      if (response.statusCode != 200) return;
      final raw = response.body.trim();
      if (raw.isEmpty) return;

      final data = jsonDecode(raw);
      data["_rawJson"] = raw;

      if (data["type"] == "ASSIGN") {
        addMessage(data);
      }
    } catch (e) {
      debugPrint("Error in _fetchAssignment: $e");
    }
  }

  // ----------------------- 🟡 6. Original Function: Rescuer Location -----------------------
  Future<void> _fetchRescuerLocation() async {
    try {
      const esp32IP = "192.168.4.3";
      final response = await http.get(Uri.parse('http://$esp32IP/lastlocation'));

      if (response.statusCode != 200) return;
      final raw = response.body.trim();
      if (raw.isEmpty) return;

      final data = jsonDecode(raw);

      if (data["type"] == "RESCUER_LOCATION") {
        final id = data["uid"] ?? data["id"];
        final lat = (data["lat"] ?? 0).toDouble();
        final lon = (data["lon"] ?? 0).toDouble();

        if (id != null && lat != 0 && lon != 0) {
          updateRescuerLocation(id, lat, lon);
        }
      }
    } catch (e) {
      debugPrint("Error in _fetchRescuerLocation: $e");
    }
  }

  // ----------------------- 🟡 7. Original Function: Update Rescuer List -----------------------
  void updateRescuerLocation(String rescuerId, double lat, double lon) {
    final index = _rescuerLocations.indexWhere((r) => r["id"] == rescuerId);

    final newEntry = {
      "id": rescuerId,
      "lat": lat,
      "lon": lon,
      "timestamp": DateTime.now().toIso8601String(),
    };

    if (index == -1) {
      _rescuerLocations.add(newEntry);
    } else {
      _rescuerLocations[index] = newEntry;
    }

    notifyListeners();
  }
   void addEvacuationMarker(LatLng point, {String name = "Evacuation Center"}) {
    final markerData = {
      'point': point,
      'name': name,
      'timestamp': DateTime.now(),
    };
    _evacuationMarkers.add(markerData);
    notifyListeners();

    FirebaseFirestore.instance.collection('evacuation_markers').add({
      'lat': point.latitude,
      'lon': point.longitude,
      'name': name,
      'timestamp': FieldValue.serverTimestamp(),
    }).then((_) => print("Evacuation marker uploaded"))
      .catchError((e) => print("Error uploading marker: $e"));
  }
   
   @override
   void dispose() {
     _pollingTimer?.cancel();
     super.dispose();
   }
}