import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class ReceivedJSONProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _lastRawMessage; // store last received message
  Timer? _pollingTimer;

  List<Map<String, dynamic>> get messages => _messages;

  // Rescuers
  final List<String> _rescuers = [
    "Roberto",
    "John",
    "Sergei",
    "Joshua",
    "BJ",
    "Achilles",
    "Paulo",
    "Ben"
  ];
  final Map<String, String> _assignedRescuers = {}; // userId -> rescuer
  final Map<String, bool> _rescuerAvailability = {}; // rescuer -> available?

  // ----------------------- 🟢 Initialize polling -----------------------
  ReceivedJSONProvider() {
    _startPolling(); // start as soon as provider is created
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _fetchMessage();
    });
  }

  // ----------------------- 🟢 Fetch from ESP32 -------------------------
  Future<void> _fetchMessage() async {
    try {
      const String esp32IP = "192.168.4.3";
      final response =
          await http.get(Uri.parse('http://$esp32IP/lastmessage'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is! Map<String, dynamic>) return;

        // Always add status if missing
        data["status"] = data["status"] ?? "unassigned";

        addMessage(data); // let the provider handle filtering & updating
      } else {
        debugPrint("Failed to fetch: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // ----------------------- 🟢 Add message safely ------------------------
  void addMessage(Map<String, dynamic> message) {
    final newMessageJson = jsonEncode(message);

    // --------- 1. Ignore exact duplicate messages from LoRa ----------
    if (_lastRawMessage != null &&
        jsonEncode(_lastRawMessage) == newMessageJson) {
      return;
    }

    _lastRawMessage = message;

    // --------- 2. Fix missing/null IDs coming from LoRa --------------
    final msgId =  message["id"];

    message["id"] = msgId;

    // --------- 3. Insert or update -----------------------------------
    final index = _messages.indexWhere((m) => m["id"] == msgId);

    bool changed = false;

    if (index == -1) {
      _messages.add(message); // brand new message
      changed = true;
    } else {
      // Only update if contents actually changed
      final oldJson = jsonEncode(_messages[index]);
      if (oldJson != newMessageJson) {
        _messages[index] = message;
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  // Generates a fallback unique ID when LoRa sends "id":"null"
  String _generateFallbackId(Map<String, dynamic> msg) {
    return "auto_${msg.hashCode}_${DateTime.now().millisecondsSinceEpoch}";
  }

  // ------------------------- 🟡 Existing status logic ------------------------
  void updateStatus(String userId, String status) {
    final index = _messages.indexWhere((m) => m['id'] == userId);
    if (index != -1) {
      _messages[index]['status'] = status;
      notifyListeners();
    }
  }

  List<String> get rescuers => List.unmodifiable(_rescuers);

  Map<String, bool> get rescuerAvailability =>
      Map.unmodifiable(_rescuerAvailability);

  Map<String, String> get assignedRescuers =>
      Map.unmodifiable(_assignedRescuers);

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


  final List<Map<String, dynamic>> _evacuationMarkers = [];

List<Map<String, dynamic>> get evacuationMarkers =>
    List.unmodifiable(_evacuationMarkers);

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
  void clear() {
    _messages.clear();
    _lastRawMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}