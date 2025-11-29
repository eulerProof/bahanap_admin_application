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
  String? _lastConfirmedId;
  final Map<String, String> _victimIdMapping = {};
  int _victimCounter = 0;
  List<Map<String, dynamic>> get messages => _messages;
  final List<Map<String, dynamic>> _finishedOperations = [];
  List<Map<String, dynamic>> get finishedOperations => List.unmodifiable(_finishedOperations);
  // Rescuers
  final List<Map<String, String>> _rescuers = [
  {"name": "Roberto", "id": "5ONCWfgob8YfzrE7QM7TWkCVa863"},
  {"name": "John", "id": ""},
  {"name": "Sergei", "id": ""},
  {"name": "Joshua", "id": ""},
  {"name": "BJ", "id": ""},
  {"name": "Achilles", "id": ""},
  {"name": "Paulo", "id": ""},
  {"name": "Ben", "id": ""},
];
  final Map<String, String> _assignedRescuers = {}; // userId -> rescuer
  final Map<String, bool> _rescuerAvailability = {}; // rescuerId -> available?

  // ----------------------- 🟢 Initialize polling -----------------------
  ReceivedJSONProvider() {
    _startPolling(); // start as soon as provider is created
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _fetchMessage();
    });
  }
  void _handleConfirmed(Map<String, dynamic> msg) {
    final id = msg["id"];
    if (id == null) return;

    // 🛑 Ignore repeated confirmations
    if (_lastConfirmedId == id) return;
    _lastConfirmedId = id;

    _messages.removeWhere((m) => m["id"] == id);

    _finishedOperations.add({
      ...msg,
      "completedAt": DateTime.now().toIso8601String(),
    });

    notifyListeners();
  }
  // ----------------------- 🟢 Fetch from ESP32 -------------------------
  Future<void> _fetchMessage() async {
    try {
      const String esp32IP = "192.168.4.3";
      final response = await http.get(Uri.parse('http://$esp32IP/lastmessage'));

      debugPrint('[_fetchMessage] status=${response.statusCode} body=${response.body}');

      if (response.statusCode == 200) {
        // keep raw string for dedupe
        final rawBody = response.body.trim();
        if (rawBody.isEmpty) return;

        final dataDynamic = jsonDecode(rawBody);
        if (dataDynamic is! Map<String, dynamic>) return;
        final Map<String, dynamic> data = Map<String, dynamic>.from(dataDynamic);

        // store the raw JSON string in data for later checks (but do not mutate it beyond this)
        data['_rawJson'] = rawBody;

        // If CONFIRMED -> pass to handler immediately
        if (data["type"] == "CONFIRMED") {
          _handleConfirmed(data);
          return;
        }

        // ensure status exists
        data["status"] = data["status"] ?? "unassigned";

        // ---------- Victim auto-numbering (safe) ----------
        if (data["id"] == "Victim") {
          // if this raw payload is different from last processed raw payload AND
          // there isn't already an active message with this raw JSON, increment
          final isDuplicateRaw = (_lastRawJson != null && _lastRawJson == rawBody);
          final existsInActiveList =
              _messages.any((m) => m["_rawJson"] == rawBody);

          if (!isDuplicateRaw && !existsInActiveList) {
            _victimCounter++;
          }

          data["id"] = "Victim $_victimCounter";
        }

        // push into addMessage (which will handle dedupe by raw JSON as well)
        addMessage(data);
      } else {
        debugPrint("Failed to fetch: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("Error in _fetchMessage: $e");
    }
  }

  // ----------------------- 🟢 Add message safely (robust) ------------------------
  String? _lastRawJson; // store raw JSON string for dedupe

  void addMessage(Map<String, dynamic> message) {
    try {
      // use raw JSON (if available) for consistent dedupe comparisons
      final rawJson = message.containsKey('_rawJson')
          ? message['_rawJson'].toString()
          : jsonEncode(message);

      // If CONFIRMED
      if (message["type"] == "CONFIRMED") {
        _handleConfirmed(message);
        return;
      }

      // 1) Deduplicate by raw JSON string
      if (_lastRawJson != null && _lastRawJson == rawJson) {
        // exact duplicate of last processed raw packet -> ignore
        return;
      }

      // 2) Prevent adding duplicates based on the final ID
      final msgId = message["id"] ?? _generateFallbackId(message);

      // Clean up: ensure message contains the raw JSON so we can check later
      message['_rawJson'] = rawJson;

      final newMessageJson = jsonEncode(message);

      final index = _messages.indexWhere((m) => m["id"] == msgId);
      bool changed = false;

      if (index == -1) {
        _messages.add(message);
        changed = true;
      } else {
        final oldJson = jsonEncode(_messages[index]);
        if (oldJson != newMessageJson) {
          _messages[index] = message;
          changed = true;
        }
      }

      // update lastRawJson only AFTER we accept (or update) message
      _lastRawJson = rawJson;

      if (changed) notifyListeners();
    } catch (e) {
      debugPrint('Error in addMessage: $e');
    }
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

  List<Map<String, String>> get rescuers => List.unmodifiable(_rescuers);

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