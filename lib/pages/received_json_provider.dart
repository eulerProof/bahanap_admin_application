import 'package:flutter/material.dart';

class ReceivedJSONProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];

  List<Map<String, dynamic>> get messages => _messages;

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
  void addMessage(Map<String, dynamic> message) {
    // Avoid duplicates based on "id"
    final index = _messages.indexWhere((m) => m['id'] == message['id']);
    if (index == -1) {
      _messages.add(message);
    } else {
      _messages[index] = message; // update existing
    }
    notifyListeners();
  }

  void updateStatus(String userId, String status) {
    final index = _messages.indexWhere((m) => m['id'] == userId);
    if (index != -1) {
      _messages[index]['status'] = status;
      notifyListeners();
    }
  }

  // Rescuers
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
  void clear() {
    _messages.clear();
    notifyListeners();
  }
}
