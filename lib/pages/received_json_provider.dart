import 'package:flutter/material.dart';

class ReceivedJSONProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];

  List<Map<String, dynamic>> get messages => _messages;

  void addMessage(Map<String, dynamic> msg) {
    // avoid duplicates by ID
    if (!_messages.any((m) => m["id"] == msg["id"])) {
      _messages.add(msg);
      notifyListeners();
    }
  }

  void clear() {
    _messages.clear();
    notifyListeners();
  }
}
