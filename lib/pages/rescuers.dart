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
            Expanded(
              flex: 1,
              child: SidebarNavigation(activePage: "Rescuers"),
            ),
            Expanded(
                flex: 3,
                child: Column(children: [
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
                ]))
          ],
        ));
  }
}
