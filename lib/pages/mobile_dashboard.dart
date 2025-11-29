import 'package:bahanap_admin_application/pages/mobile_dashboard.dart';
import 'package:bahanap_admin_application/pages/rescuers.dart';
import 'package:bahanap_admin_application/pages/users.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:bahanap_admin_application/pages/sidebar_navigation.dart';
import 'map.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'operations.dart';

class MobileDashboardPage extends StatefulWidget {
  const MobileDashboardPage({super.key});
  @override
  _MobileDashboardPageState createState() => _MobileDashboardPageState();
}

class _MobileDashboardPageState extends State<MobileDashboardPage> {
  final TextEditingController _textController = TextEditingController();
  
  final waterLevel = ["Low", "Middle", "High"];
  String value = "Low";
  String _responseMessage = '';
  bool showAddPage = false;
  bool isLoadingWaterLevel = true;
  String selectedCategory = "pre_disaster"; // default dropdown value
  DropdownMenuItem<String> buildMenuItem(String waterLev) => DropdownMenuItem(
        value: waterLev,
        child: Text(
          waterLev,
        ),
      );
  final guidelines = [
    {"guideline": "SOmething", "category": "pre-disaster"}
  ];
  @override
  void initState() {
    super.initState();
    getWaterLevelFromFirebase();
  }
  void getWaterLevelFromFirebase() async {
    final water = await FirebaseFirestore.instance
      .collection('disaster_guidelines').doc("water_level")
      .get();
    if (water.exists) {
      setState(() {
        value = water.data()?['level'] ?? "Low";
        isLoadingWaterLevel = false;
      });
    }
  }
  Widget _buildCategory(String title, List<String> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      if (items.isEmpty)
        const Text("• No guidelines added yet."),
      for (final text in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            "• $text",
            style: const TextStyle(fontSize: 14),
          ),
        ),
    ],
  );
}
  Future<Map<String, List<String>>> _fetchGuidelineCategories() async {
    final firestore = FirebaseFirestore.instance;

    Future<List<String>> fetchCategory(String collectionName) async {
      final snap = await firestore
          .collection('disaster_guidelines')
          .doc('guidelines')
          .collection(collectionName)
          .orderBy('timestamp', descending: false)
          .get();

      return snap.docs.map((d) => d['content'] as String).toList();
    }

    return {
      "pre_disaster": await fetchCategory("pre_disaster"),
      "during_disaster": await fetchCategory("during_disaster"),
      "post_disaster": await fetchCategory("post_disaster"),
    };
  }
   @override
  void dispose() {
    super.dispose();
  }

  void showEditPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            TextEditingController textController = TextEditingController();

            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: MediaQuery.of(context).size.height * 0.75,
                padding: const EdgeInsets.all(43),
                child: showAddPage == true
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Add New Guideline",
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border:
                                  Border.all(color: Colors.black, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCategory,
                                isExpanded:
                                    true, // makes the dropdown take full width
                                onChanged: (value) {
                                  setState(() => selectedCategory = value!);
                                },
                                items: const [
                                  DropdownMenuItem(
                                      value: "pre_disaster",
                                      child: Text(
                                        "Pre-disaster",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      )),
                                  DropdownMenuItem(
                                      value: "during_disaster",
                                      child: Text("During disaster",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(
                                      value: "post_disaster",
                                      child: Text("Post-disaster",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                ],
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Colors.black),
                                dropdownColor: Colors.white,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: textController,
                            maxLines: 5,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter guideline content...",
                              hintStyle: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 15),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.black, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    showAddPage = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.fromLTRB(28, 18, 28, 18),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(37),
                                  ),
                                ),
                                child: const Text(
                                  "Back",
                                  style: TextStyle(
                                    color: Color(0xff32ade6),
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final guidelineText = textController.text.trim();
                                  if (guidelineText.isEmpty) return;

                                  final jsonData = {
                                    "category": selectedCategory,
                                    "content": guidelineText,
                                    "timestamp": DateTime.now().toIso8601String(),
                                  };

                                  const String esp32IP = "192.168.4.3"; // double-check this
                                  final esp32Url = Uri.parse('http://$esp32IP/message');

                                  try {
                                    // 1) Try to POST to ESP32 first (short timeout)
                                    final http.Response espResp = await http
                                        .post(
                                          esp32Url,
                                          headers: {"Content-Type": "application/json"},
                                          body: jsonEncode(jsonData),
                                        )
                                        .timeout(const Duration(seconds: 6));

                                    debugPrint('ESP32 status: ${espResp.statusCode}');
                                    debugPrint('ESP32 body: ${espResp.body}');

                                    if (espResp.statusCode == 200) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Guideline sent to ESP32")),
                                      );
                                    } else {
                                      // ESP responded but not OK — fallback to Firestore and inform user
                                      debugPrint('ESP32 returned non-200. Falling back to Firestore.');
                                      await FirebaseFirestore.instance
                                          .collection("disaster_guidelines")
                                          .doc("guidelines")
                                          .collection(selectedCategory)
                                          .add({
                                        "category": selectedCategory,
                                        "content": guidelineText,
                                        "timestamp": FieldValue.serverTimestamp(),
                                        "source": "fallback_esp_${espResp.statusCode}",
                                      });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("ESP32 error ${espResp.statusCode}. Saved to Firestore.")),
                                      );
                                    }
                                  } on TimeoutException catch (te) {
                                    debugPrint('ESP32 timeout: $te');
                                    // fallback to Firestore
                                    await FirebaseFirestore.instance
                                        .collection("disaster_guidelines")
                                        .doc("guidelines")
                                        .collection(selectedCategory)
                                        .add({
                                      "category": selectedCategory,
                                      "content": guidelineText,
                                      "timestamp": FieldValue.serverTimestamp(),
                                      "source": "fallback_timeout",
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("ESP32 timed out. Saved to Firestore.")),
                                    );
                                  } catch (e, st) {
                                    // other network errors: unreachable host, socket exception, etc.
                                    debugPrint('Error sending to ESP32: $e\n$st');

                                    // fallback to Firestore
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection("disaster_guidelines")
                                          .doc("guidelines")
                                          .collection(selectedCategory)
                                          .add({
                                        "category": selectedCategory,
                                        "content": guidelineText,
                                        "timestamp": FieldValue.serverTimestamp(),
                                        "source": "fallback_error",
                                        "error": e.toString(),
                                      });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Error sending to ESP32. Saved to Firestore: $e")),
                                      );
                                    } catch (fsErr) {
                                      debugPrint('Failed to save to Firestore: $fsErr');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Failed to save: $fsErr")),
                                      );
                                    }
                                  } finally {
                                    // Reset UI regardless of path
                                    textController.clear();
                                    setState(() => showAddPage = false);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.fromLTRB(28, 18, 28, 18),
                                  backgroundColor: Color(0xff32ade6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(37),
                                  ),
                                ),
                                child: const Text(
                                  "Add Guideline",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Disaster Guidelines",
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: StreamBuilder(
                              stream: FirebaseFirestore.instance
                                  .collection('disaster_guidelines')
                                  .doc('guidelines')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                // Fetch each category
                                return FutureBuilder(
                                  future: _fetchGuidelineCategories(),
                                  builder: (context, snap) {
                                    if (!snap.hasData) {
                                      return const Center(child: CircularProgressIndicator());
                                    }

                                    final data = snap.data as Map<String, List<String>>;

                                    final pre = data["pre_disaster"]!;
                                    final during = data["during_disaster"]!;
                                    final post = data["post_disaster"]!;

                                    return ListView(
                                      children: [
                                        _buildCategory("Pre-Disaster", pre),
                                        const SizedBox(height: 20),
                                        _buildCategory("During Disaster", during),
                                        const SizedBox(height: 20),
                                        _buildCategory("Post-Disaster", post),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.fromLTRB(28, 18, 28, 18),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(37),
                                  ),
                                ),
                                child: const Text(
                                  "Close",
                                  style: TextStyle(
                                    color: Color(0xff32ade6),
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    showAddPage = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.fromLTRB(28, 18, 28, 18),
                                  backgroundColor: Color(0xff32ade6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(37),
                                  ),
                                ),
                                child: const Text(
                                  "Add Content",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
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
              child: SidebarNavigation(activePage: "MobileDashboard"),
            ),
            Expanded(
                flex: 3,
                child: Column(children: [
                  Container(
                    height: 100,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.fromLTRB(40, 15, 15, 15),
                    child: const Text(
                      "Mobile Dashboard",
                      style: TextStyle(
                        fontFamily: "SFPro",
                        fontSize: 43,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2294C9),
                      ),
                    ),
                  ),
                  const Divider(),
                  Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.fromLTRB(40, 15, 15, 40),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Water Level",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontFamily: "SFPro",
                                    fontSize: 33,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                Container(
                                    width: 300,
                                    height: 50,
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 0, 15, 0),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.black, width: 1.0),
                                        borderRadius:
                                            BorderRadius.circular(20.0)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton2<String>(
                                        isExpanded: true,
                                        iconStyleData: const IconStyleData(
                                            icon: Icon(Icons
                                                .keyboard_arrow_down_rounded),
                                            iconEnabledColor: Colors.black),
                                        value: value,
                                        items: waterLevel
                                            .map(buildMenuItem)
                                            .toList(),
                                        onChanged: (value) =>
                                            setState(() => this.value = value!),
                                        dropdownStyleData:
                                            const DropdownStyleData(
                                                direction: DropdownDirection
                                                    .textDirection),
                                      ),
                                    )),
                                const SizedBox(
                                  height: 8,
                                ),
                                ElevatedButton(
                                    onPressed: () async {
                                      //placeholder for saving water level to IOT
                                      await FirebaseFirestore.instance
                                      .collection('disaster_guidelines')
                                      .doc('water_level')
                                      .update({
                                        'level': value,   // e.g. "High"
                                      });

                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Water Level"),
                                          content: const Text("Water Level successfully updated!"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: const Text("Ok"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.fromLTRB(
                                          28, 14, 28, 14),
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.grey, width: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            17), // optional rounded corners
                                      ),
                                    ),
                                    child: const Text(
                                      "Save",
                                      style: TextStyle(
                                          fontSize: 22, color: Colors.black),
                                    )),
                                const SizedBox(
                                  height: 40,
                                ),
                                const Text(
                                  "Disaster Preparedness Guidelines",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontFamily: "SFPro",
                                    fontSize: 33,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                ElevatedButton(
                                    onPressed: () {
                                      showEditPopup(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.fromLTRB(
                                          28, 14, 28, 14),
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.grey, width: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            17), // optional rounded corners
                                      ),
                                    ),
                                    child: const Text(
                                      "Open",
                                      style: TextStyle(
                                          fontSize: 22, color: Colors.black),
                                    )),
                                const SizedBox(
                                  height: 40,
                                ),
                              ],
                            ),
                          )
                        ],
                      )),
                ]))
          ],
        ));
  }
}
