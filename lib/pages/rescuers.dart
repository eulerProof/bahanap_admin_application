import 'package:bahanap_admin_application/pages/mobile_dashboard.dart';
import 'package:bahanap_admin_application/pages/rescuers.dart';
import 'package:bahanap_admin_application/pages/users.dart';
import 'package:bahanap_admin_application/pages/sidebar_navigation.dart';
import 'package:flutter/material.dart';
import 'map.dart';
import 'operations.dart';

class RescuersPage extends StatefulWidget {
  const RescuersPage({super.key});
  @override
  _RescuersPageState createState() => _RescuersPageState();
}

class _RescuersPageState extends State<RescuersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x0032ade6),
      body: Row(
        children: [
          // Sidebar
          Expanded(
            flex: 1,
            child: SidebarNavigation(activePage: "Rescuers"),
          ),

          // Main content
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page header
                Container(
                  height: 100,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.fromLTRB(40, 15, 15, 15),
                  child: const Text(
                    "Rescuers",
                    style: TextStyle(
                      fontFamily: "SFPro",
                      fontSize: 43,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2294C9),
                    ),
                  ),
                ),

                const Divider(),

                // Button on the left
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 10, 0, 20),
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Add functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0XFF2294C9),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      "Add Rescuer",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),

                // Content area (expandable)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                    child: Container(
                      // Replace this with your list or grid of rescuers
                      color: Colors.white.withOpacity(0.1),
                      child: const Center(
                        child: Text(
                          "Rescuer list goes here",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
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
