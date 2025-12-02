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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

  // ---------------------------------------------------------------------------
  // 🟢 INIT & WATER LEVEL LOGIC
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    getWaterLevelFromFirebase();
  }

  void getWaterLevelFromFirebase() async {
    try {
      final water = await FirebaseFirestore.instance
          .collection('disaster_guidelines')
          .doc("water_level")
          .get();
      if (water.exists && mounted) {
        setState(() {
          value = water.data()?['level'] ?? "Low";
          isLoadingWaterLevel = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching water level: $e");
    }
  }

  DropdownMenuItem<String> buildMenuItem(String waterLev) => DropdownMenuItem(
        value: waterLev,
        child: Text(
          waterLev,
        ),
      );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 🟢 NEW: FIRESTORE ACTIONS (EDIT & DELETE)
  // ---------------------------------------------------------------------------

  void _deleteGuideline(String collectionId, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Guideline"),
        content: const Text("Are you sure you want to delete this guideline?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('disaster_guidelines')
                  .doc('guidelines')
                  .collection(collectionId)
                  .doc(docId)
                  .delete();
              
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editGuideline(String collectionId, String docId, String currentContent) {
    final editController = TextEditingController(text: currentContent);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Guideline"),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Content",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2294C9)),
            onPressed: () async {
              if (editController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('disaster_guidelines')
                    .doc('guidelines')
                    .collection(collectionId)
                    .doc(docId)
                    .update({
                      'content': editController.text.trim(),
                    });
                
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🟢 NEW: DYNAMIC UI BUILDERS (STREAMS)
  // ---------------------------------------------------------------------------

  // 1. The Stream Listener (Replaces your old FutureBuilder)
  Widget _buildGuidelineStream(String title, String collectionId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('disaster_guidelines')
          .doc('guidelines')
          .collection(collectionId)
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Error loading data");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ));
        }

        // Convert docs to a list of maps
        final List<Map<String, dynamic>> items = snapshot.data!.docs.map((doc) {
          return {
            'id': doc.id,
            'content': doc['content'] as String? ?? "",
          };
        }).toList();

        return _buildCategory(title, collectionId, items);
      },
    );
  }

  // 2. The Visual Builder (Now includes Edit/Delete buttons)
  Widget _buildCategory(String title, String collectionId, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text("• No guidelines added yet.", style: TextStyle(color: Colors.grey)),
          ),
        for (final item in items)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "• ${item['content']}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xff2294C9), size: 20),
                  onPressed: () => _editGuideline(collectionId, item['id'], item['content']),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteGuideline(collectionId, item['id']),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 🟢 POPUP DIALOG LOGIC
  // ---------------------------------------------------------------------------

  void showEditPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Note: _textController is defined at class level, but we can reuse it
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
                    // --------------------------
                    // VIEW 1: ADD NEW GUIDELINE
                    // --------------------------
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
                                isExpanded: true,
                                onChanged: (value) {
                                  setState(() => selectedCategory = value!);
                                },
                                items: const [
                                  DropdownMenuItem(
                                      value: "pre_disaster",
                                      child: Text("Pre-disaster",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
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
                            controller: _textController,
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
                                  padding: const EdgeInsets.fromLTRB(
                                      28, 18, 28, 18),
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
                                  final guidelineText = _textController.text.trim();
                                  if (guidelineText.isEmpty) return;

                                  final jsonData = {
                                    "category": selectedCategory,
                                    "content": guidelineText,
                                    "timestamp": DateTime.now().toIso8601String(),
                                  };

                                  const String esp32IP = "192.168.4.3"; 
                                  final esp32Url = Uri.parse('http://$esp32IP/message');

                                  try {
                                    final http.Response espResp = await http
                                        .post(
                                          esp32Url,
                                          headers: {"Content-Type": "application/json"},
                                          body: jsonEncode(jsonData),
                                        )
                                        .timeout(const Duration(seconds: 6));

                                    debugPrint('ESP32 status: ${espResp.statusCode}');

                                    if (espResp.statusCode == 200) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Guideline sent to ESP32")),
                                      );
                                    } else {
                                      // Fallback
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
                                  } on TimeoutException catch (_) {
                                    // Timeout fallback
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
                                  } catch (e) {
                                    // General error fallback
                                    debugPrint('Error: $e');
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
                                      });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Saved to Firestore (Network Error)")),
                                      );
                                    } catch (fsErr) {
                                      debugPrint('Failed to save to Firestore: $fsErr');
                                    }
                                  } finally {
                                    _textController.clear();
                                    setState(() => showAddPage = false);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.fromLTRB(
                                      28, 18, 28, 18),
                                  backgroundColor: const Color(0xff32ade6),
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
                    // --------------------------
                    // VIEW 2: LIST EXISTING GUIDELINES (With Streams)
                    // --------------------------
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
                            child: ListView(
                              children: [
                                _buildGuidelineStream("Pre-Disaster", "pre_disaster"),
                                const SizedBox(height: 20),
                                _buildGuidelineStream("During Disaster", "during_disaster"),
                                const SizedBox(height: 20),
                                _buildGuidelineStream("Post-Disaster", "post_disaster"),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.fromLTRB(
                                      28, 18, 28, 18),
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
                                  padding: const EdgeInsets.fromLTRB(
                                      28, 18, 28, 18),
                                  backgroundColor: const Color(0xff32ade6),
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

  // ---------------------------------------------------------------------------
  // 🟢 MAIN SCAFFOLD BUILD
  // ---------------------------------------------------------------------------
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
                                const SizedBox(height: 8),
                                Container(
                                    width: 300,
                                    height: 50,
                                    padding: const EdgeInsets.fromLTRB(10, 0, 15, 0),
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
                                const SizedBox(height: 8),
                                ElevatedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('disaster_guidelines')
                                          .doc('water_level')
                                          .update({
                                        'level': value,
                                      });

                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Water Level"),
                                          content: const Text(
                                              "Water Level successfully updated!"),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
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
                                            17), 
                                      ),
                                    ),
                                    child: const Text(
                                      "Save",
                                      style: TextStyle(
                                          fontSize: 22, color: Colors.black),
                                    )),
                                const SizedBox(height: 40),
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
                                const SizedBox(height: 8),
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
                                            17),
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