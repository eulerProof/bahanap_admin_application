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
  final List<Map<String, String>> _rescuers = [
    {},
    // ... (your other rescuers)
  ];
  final Map<String, String> _assignedRescuers = {}; 
  final Map<String, bool> _rescuerAvailability = {}; 

  // ----------------------- 🟢 Initialize -----------------------
  ReceivedJSONProvider() {
    _startPolling();
    fetchRescuersFromFirestore();
  }

  Future<void> fetchRescuersFromFirestore() async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('profiles').get();

    _rescuers.clear(); // Clear default hardcoded list

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['role'] == 'Rescuer') {
        _rescuers.add({
          "name": data['Name'] ?? "Unknown", // Replace with actual username field
          "id": doc.id,
        });
        _rescuerAvailability[doc.id] = true; // Mark all as available initially
      }
    }

    notifyListeners();
    debugPrint("Rescuers fetched from Firestore: ${_rescuers.length}");
  } catch (e) {
    debugPrint("Error fetching rescuers from Firestore: $e");
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

  // ----------------------- 🟢 1. The Confirmation Logic -----------------------
  // When a confirmation comes in, we must archive the UNIQUE identifying info
  // (Timestamp or Raw JSON) of the active message so we don't pick it up again.
  void _handleConfirmed(Map<String, dynamic> confirmMsg) {
    final id = confirmMsg["id"];
    if (id == null) return;

    if (_lastConfirmedId == id) return;
    _lastConfirmedId = id;

    // A. Find the ACTIVE message that corresponds to this ID
    // We need to grab its timestamp/rawJson before we delete it.
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
      // 🛑 SAVE THE FINGERPRINTS
      // If the SOS had a timestamp, save it. If not, save the raw string.
      "sos_timestamp": originalData["timestamp"], 
      "_rawJson": originalData["_rawJson"], 
      "lat": originalData["lat"],
      "lon": originalData["lon"],
    });

    notifyListeners();
  }

  // ----------------------- 🟢 2. The Fetch SOS Logic -----------------------
  int _victimCounter = 0;

  Future<void> _fetchSOS() async {
    try {
      const esp32IP = "192.168.4.3";
      final response = await http.get(Uri.parse('http://$esp32IP/lastsos'));

      if (response.statusCode != 200) return;
      final rawBody = response.body.trim();
      if (rawBody.isEmpty) return;

      final data = jsonDecode(rawBody);
      data["_rawJson"] = rawBody; // Attach raw body for comparison
      
      // 🛑 GUARD 1: TIMESTAMP / RAW JSON CHECK
      // Check if this specific signal is already in _finishedOperations
      final incomingTimestamp = data["timestamp"]; 
      
      final isAlreadyFinished = _finishedOperations.any((finishedOp) {
        // A. If both have timestamps, match them exactly.
        if (incomingTimestamp != null && finishedOp["sos_timestamp"] != null) {
          return incomingTimestamp == finishedOp["sos_timestamp"];
        }
        // B. Fallback: Match the Raw JSON string exactly.
        // (The ESP32 sends the exact same string until cleared)
        return rawBody == finishedOp["_rawJson"];
      });

      if (isAlreadyFinished) {
        return; // STOP. Do not add.
      }

      if (data["type"] == "SOS") {
        if (data["id"] == "Victim") {
          
          // 🛑 GUARD 2: IS IT ALREADY ACTIVE?
          // We check if this specific timestamp/rawJson is already in the active list
          final activeIndex = _messages.indexWhere((m) {
             if (incomingTimestamp != null && m["timestamp"] != null) {
               return incomingTimestamp == m["timestamp"];
             }
             return rawBody == m["_rawJson"];
          });

          if (activeIndex != -1) {
            // IT EXISTS: Update existing victim, keep the same ID
            data["id"] = _messages[activeIndex]["id"];
          } else {
            // NEW: Increment counter and assign new ID
            _victimCounter++;
            data["id"] = "Victim $_victimCounter";
          }
        }
        
        addMessage(data);
      }
    } catch (e) {
      debugPrint("Error in _fetchSOS: $e");
    }
  }

  // ----------------------- 🟢 3. Add Message -----------------------
  // Simplified: logic is now handled in _fetchSOS, so we just update/add.
  void addMessage(Map<String, dynamic> message) {
    try {
      if (message["type"] == "CONFIRMED") {
        _handleConfirmed(message);
        return;
      }

      final msgId = message["id"] ?? "unknown";
      if (!message.containsKey("status")) {
        message["status"] = "unassigned";
      }

      final index = _messages.indexWhere((m) => m["id"] == msgId);

      if (index == -1) {
        _messages.add(message);
        notifyListeners();
      } else {
        // Check for changes before notifying to save performance
        final oldJson = jsonEncode(_messages[index]);
        final newJson = jsonEncode(message);
        if (oldJson != newJson) {
           _messages[index] = message;
           notifyListeners();
        }
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
   List<Map<String, String>> get rescuers => List.unmodifiable(_rescuers);
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