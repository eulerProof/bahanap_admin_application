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
    // _startReceivingMessages();

    // Initially mark all rescuers as available

    // Load persisted assignments from Firestore
    _loadAssignments();
  }

  void _startReceivingMessages() {
    _fetchMessage(); // fetch immediately
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMessage());
  }
  Widget _buildRequestCard(Map<String, dynamic> item) {
  final id = item["id"]?.toString() ?? "Invalid";
  final lat = double.tryParse(item["lat"]?.toString() ?? "0") ?? 0;
  final lon = double.tryParse(item["lon"]?.toString() ?? "0") ?? 0;

  final bool assigned = receivedProvider.assignedRescuers.containsKey(id);
  final String assignedRescuer = receivedProvider.assignedRescuers[id] ?? "";

  // If ID is invalid, return an empty widget
  if (id == "Invalid") {
    return SizedBox(width: 0,);
  }

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
            Text(
              "User: $id",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              "Lat: $lat, Lon: $lon",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            if (assigned)
              Text(
                "Assigned: $assignedRescuer",
                style: const TextStyle(fontSize: 15, color: Colors.green),
              ),
          ],
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: assigned ? null : () => _selectRescuer(id, lat, lon),
          style: ElevatedButton.styleFrom(
            backgroundColor: assigned ? Colors.grey : const Color(0XFF2294C9),
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
      const String esp32IP = "192.168.4.3";
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
      String rescuer, String userId, double lat, double lon, String rescuerName) async {
        
    // Send JSON to ESP32
    try {
      final payload = {"latitude": lat, "longitude": lon, "rescuer": rescuer, "uid": userId};
      const esp32IP = "192.168.4.3";
      await http
          .post(
            Uri.parse('http://$esp32IP/assign'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));
      receivedProvider.assignRescuer(userId, rescuerName);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Rescuer Assigned"),
          content: Text("Rescuer: $rescuerName\nRescuee Coordinates: $lat, $lon"),
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
        "rescuerId": rescuer,                    // ID // Name for display
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
                        final rescuerName = receivedProvider.rescuers[index]["name"];
                        final rescuerId   = receivedProvider.rescuers[index]["id"];

                        final isAvailable =
                            receivedProvider.rescuerAvailability[rescuerId] ?? true;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Row(
                                    children: [
                                      Text(rescuerName!,
                                      style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 10,),
                                      Text(isAvailable ?
                                      "Available" : "Busy"
                                      ,
                                      style: TextStyle(fontSize: 13,
                                        color: isAvailable ?
                                        Colors.green : Colors.red
                                      
                                      )),
                                    ],
                                  )),
                              ElevatedButton(
                                onPressed:  () {
                                        _assignRescuer(
                                            rescuerId!, userId, lat, lon, rescuerName);
                                        Navigator.of(context).pop();
                                      }
                                    ,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0XFF2294C9)
                                      ,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5)),
                                ),
                                child: const Text(
                                    "Assign Rescuer",
                                    style:
                                      TextStyle(color: Colors.white)),
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
  void _showFinishedOperationsDialog() {
  final finishedOps =
      Provider.of<ReceivedJSONProvider>(context, listen: false)
          .finishedOperations;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Finished Rescue Operations"),
      content: SizedBox(
        width: double.maxFinite,
        child: finishedOps.isEmpty
            ? const Text("No finished operations yet.")
            : ListView.builder(
                shrinkWrap: true,
                itemCount: finishedOps.length,
                itemBuilder: (context, index) {
                  final op = finishedOps[index];
                  return ListTile(
                    title: Text("User: ${op['id']}"),
                    subtitle: Text(
                      "Rescuer: ${op['rescuer'] ?? 'Unknown'}",
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    ),
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Rescue Operations",
                              style: TextStyle(
                                fontFamily: "SFPro",
                                fontSize: 33,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),

                            // ⭐ BUTTON: opens finished operations dialog
                            ElevatedButton.icon(
                              onPressed: _showFinishedOperationsDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2294C9),
                              ),
                              icon: const Icon(Icons.history, color: Colors.white),
                              label: const Text(
                                "Finished",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
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
                            return _buildRequestCard(item);
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
                            return _buildRequestCard(item);;
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
