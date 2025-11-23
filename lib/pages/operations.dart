import 'package:bahanap_admin_application/pages/received_json_provider.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:bahanap_admin_application/pages/sidebar_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'map.dart';
import 'mobile_dashboard.dart';
import 'rescuers.dart';
import 'users.dart';

class OperationsPage extends StatefulWidget {
  const OperationsPage({super.key});

  @override
  _OperationsPageState createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  Timer? _timer;
  late ReceivedJSONProvider receivedProvider;

  // final rescuers = [
  //   "Roberto",
  //   "John",
  //   "Sergei",
  //   "Joshua",
  //   "BJ",
  //   "Achilles",
  //   "Paulo",
  //   "Ben"
  // ];

  // Map<String, String> assignedRescuers = {}; // userId -> rescuerName
  // Map<String, bool> rescuerAvailability =
  //     {}; // rescuerName -> true (available) / false (busy)

  @override
  void initState() {
    super.initState();
    receivedProvider =
        Provider.of<ReceivedJSONProvider>(context, listen: false);
    _startReceivingMessages();

    // Initially mark all rescuers as available

    // Load persisted assignments from Firestore
    _loadAssignments();
  }

  void _startReceivingMessages() {
    _fetchMessage(); // fetch immediately
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMessage());
  }
  Widget _buildRequestCard(Map<String, dynamic> item, {required bool assigned}) {
  final lat = double.tryParse(item["lat"]?.toString() ?? "0") ?? 0;
  final lon = double.tryParse(item["lon"]?.toString() ?? "0") ?? 0;
  final id = item["id"]?.toString() ?? "No Username";

  final assigned = receivedProvider.assignedRescuers[id] != null;
  final assignedRescuer = receivedProvider.assignedRescuers[id] ?? "";

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 3,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 30),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("User: $id",
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            Text("Lat: $lat, Lon: $lon",
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            if (assigned)
              Text("Assigned: $assignedRescuer",
                  style: const TextStyle(fontSize: 15, color: Colors.green)),
          ],
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: assigned
              ? null
              : () => _selectRescuer(id, lat, lon),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                assigned ? Colors.grey : const Color(0XFF2294C9),
          ),
          child: Text(
            assigned ? "Assigned" : "Assign Rescuer",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
  Future<void> _fetchMessage() async {
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

  Future<void> _loadAssignments() async {
    final snapshot =
        await FirebaseFirestore.instance.collection("assignments").get();
      
    for (var doc in snapshot.docs) {
      final userId = doc.id;
      final rescuerName = doc['rescuer'] as String;

      // Assign rescuer in provider (updates assignedRescuers, availability, and status)
      receivedProvider.assignRescuer(userId, rescuerName);
    }
    setState(() {});
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
          .timeout(const Duration(seconds: 8));
      receivedProvider.assignRescuer(userId, rescuer);
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
      
      // Show confirmation dialog
      
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
                      itemCount: receivedProvider.rescuers.length,
                      itemBuilder: (context, index) {
                        final rescuerName = receivedProvider.rescuers[index];
                        final isAvailable =
                            receivedProvider.rescuerAvailability[rescuerName] ?? true;
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = Provider.of<ReceivedJSONProvider>(context).messages;
    final unassigned = messages.where((m) => m["status"] == "unassigned").toList();
    final assigned = messages.where((m) => m["status"] == "assigned").toList();
    return Scaffold(
      backgroundColor: const Color(0x0032ade6),
      body: Row(
        children: [
          // ✅ Sidebar
          Expanded(flex: 1, child: SidebarNavigation(activePage: "Operations")),

          // ✅ Main Content
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Container(
                  height: 100,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.fromLTRB(40, 15, 15, 15),
                  child: const Text(
                    "Operations",
                    style: TextStyle(
                      fontFamily: "SFPro",
                      fontSize: 43,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2294C9),
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(40, 20, 40, 40),
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          "Rescue Operations",
                          style: TextStyle(
                            fontFamily: "SFPro",
                            fontSize: 33,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (unassigned.isEmpty && assigned.isEmpty) ... [
                        const Text("No SOS Requests found",
                            style: TextStyle(fontSize: 25,)),
                        
                      ],
                      if (unassigned.isNotEmpty) ...[
                        const Text("Rescue Requests",
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: unassigned.length,
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 550,
                            mainAxisSpacing: 15,
                            crossAxisSpacing: 15,
                            mainAxisExtent: 150,
                          ),
                          itemBuilder: (context, i) {
                            final item = unassigned[i];
                            return _buildRequestCard(item, assigned: false);
                          },
                        ),
                      ],
                      if (assigned.isNotEmpty) ...[
                        const SizedBox(height: 40),
                        const Text("Assigned Requests",
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: assigned.length,
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 550,
                            mainAxisSpacing: 15,
                            crossAxisSpacing: 15,
                            mainAxisExtent: 150,
                          ),
                          itemBuilder: (context, i) {
                            final item = assigned[i];
                            return _buildRequestCard(item, assigned: true);
                          },
                        ),
                      ],
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
