import 'package:bahanap_admin_application/pages/users.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'map.dart';
import 'mobile_dashboard.dart';
import 'rescuers.dart';

class OperationsPage extends StatefulWidget {
  const OperationsPage({super.key});

  @override
  _OperationsPageState createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  Timer? _timer;

  // 👇 This will hold your received JSON objects
  List<Map<String, dynamic>> receivedJSON = [];

  @override
  void initState() {
    super.initState();
    _startReceivingMessages();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startReceivingMessages() {
    _fetchMessage(); // Fetch once immediately
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchMessage());
  }

  Future<void> _fetchMessage() async {
    try {
      const String esp32IP = "192.168.4.2";
      final response = await http.get(Uri.parse('http://$esp32IP/lastmessage'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          // ✅ Check if we already have this message (by ID or timestamp)
          final existing = receivedJSON.any((item) => item["id"] == data["id"]);

          if (!existing) {
            setState(() {
              receivedJSON.add(data);
            });
          }
        }
      } else {
        debugPrint("Failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching message: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x0032ade6),
      body: Row(
        children: [
          // ✅ Sidebar
          SafeArea(
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.24,
              decoration: const BoxDecoration(
                color: Color(0xff32ade6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 45, 40, 0),
                    child: SizedBox(
                      height: 82,
                      child: const Text(
                        "BaHanap",
                        style: TextStyle(
                          fontSize: 62,
                          fontFamily: 'Gilroy',
                          color: Colors.white,
                          letterSpacing: -4.0,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 30),
                    child: Container(
                      width: 138,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xff3d3d3d),
                        borderRadius: BorderRadius.circular(37),
                      ),
                      child: const Center(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.support_agent,
                              size: 15,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "Administrator",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // ✅ Navigation buttons
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MapPage()),
                      );
                    },
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.24,
                      padding: const EdgeInsets.fromLTRB(44, 10, 0, 10),
                      child: const Row(
                        children: [
                          Icon(Icons.map, color: Colors.white, size: 25),
                          SizedBox(width: 10),
                          Text(
                            "Map",
                            style: TextStyle(
                              fontFamily: "SFPro",
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OperationsPage()),
                      );
                    },
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.24,
                      decoration: const BoxDecoration(
                        color: Color(0xff2294C9),
                      ),
                      padding: const EdgeInsets.fromLTRB(44, 10, 0, 10),
                      child: const Row(
                        children: [
                          Icon(Icons.track_changes,
                              color: Colors.white, size: 25),
                          SizedBox(width: 10),
                          Text(
                            "Operations",
                            style: TextStyle(
                              fontFamily: "SFPro",
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UsersPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.24,
                      padding: const EdgeInsets.fromLTRB(44, 10, 0, 10),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.supervised_user_circle,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Users",
                            style: TextStyle(
                              fontFamily: "SFPro",
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RescuersPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.24,
                      padding: const EdgeInsets.fromLTRB(44, 10, 0, 10),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Rescuers",
                            style: TextStyle(
                                fontFamily: "SFPro",
                                fontSize: 20,
                                color: Colors.white),
                          )
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MobileDashboardPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.24,
                      padding: const EdgeInsets.fromLTRB(44, 10, 0, 10),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.dashboard,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Mobile App Dashboard",
                            style: TextStyle(
                              fontFamily: "SFPro",
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                        width: MediaQuery.sizeOf(context).width * 0.24,
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 50),
                        child: Center(
                          child: Container(
                            height: 41,
                            width: 162,
                            child: ElevatedButton(onPressed: () {

                            },
                                style: ElevatedButton.styleFrom(
                               
                                backgroundColor: const Color(0XFF2294C9),
                                foregroundColor: Colors.white,
                                
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(37),
                                
                                ),
                              ),
                           child: const Center(
                            child: Row(
                            children: [
                              Icon(Icons.logout, size: 20,),
                              SizedBox(width: 19,),
                              Text("Log Out", style: TextStyle(
                                fontFamily: "SFPro",
                                fontSize: 20,
                                color: Colors.white,
                              ),)
                            ],
                           ),
                           )),
                          )
                        ),
                      )
,
                      )
                      
                  ],
                ),
              
              
              ),),

          // ✅ Main Content
          Expanded(
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

                // ✅ Content Body
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
                      Expanded(
                        child: GridView.builder(
                          shrinkWrap: true,
                          itemCount: receivedJSON.length,
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 550,
                            mainAxisSpacing: 15,
                            crossAxisSpacing: 15,
                            mainAxisExtent: 150,
                          ),
                          itemBuilder: (context, i) {

                            final item = receivedJSON[i];
                            final lat = item["lat"] ?? "Unknown";
                            final lon = item["lon"] ?? "Unknown";
                            var id = "";
                            if (id == "null") {
                              id = "No Username";
                            } else {
                              id = item["id"] ?? "No Username";
                            }
                            

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.5),
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
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        "Coordinates",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Lat: $lat, Lon: $lon",     
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Handle rescuer assignment here
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0XFF2294C9),
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    child: const Text(
                                      "Assign Rescuer",
                                      style: TextStyle(color: Colors.white),
                                    ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}