import 'package:flutter/material.dart';
import 'map.dart';
import 'operations.dart';
import 'users.dart';
import 'rescuers.dart';
import 'mobile_dashboard.dart';

class SidebarNavigation extends StatelessWidget {
  final String activePage;

  const SidebarNavigation({super.key, required this.activePage});

  @override
  Widget build(BuildContext context) {
    // Helper function to create navigation items
    Widget navItem(String label, IconData icon, String pageName, Widget page) {
      final isActive = activePage == pageName;
      return GestureDetector(
        onTap: isActive
            ? null // disable tap on active page
            : () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        page,
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 200),
                  ),
                );
              },
        child: Container(
          decoration:
              isActive ? const BoxDecoration(color: Color(0xff2294C9)) : null,
          width: MediaQuery.sizeOf(context).width * 0.24,
          padding: const EdgeInsets.fromLTRB(44, 10, 0, 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 25),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: "SFPro",
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.24,
        decoration: const BoxDecoration(color: Color(0xff32ade6)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
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
            // Role Tag
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
                      Icon(Icons.support_agent, size: 15, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        "Administrator",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Navigation items
            navItem("Map", Icons.map, "Map", MapPage()),
            navItem("Operations", Icons.track_changes, "Operations",
                OperationsPage()),
            navItem(
                "Users", Icons.supervised_user_circle, "Users", UsersPage()),
            navItem("Rescuers", Icons.admin_panel_settings, "Rescuers",
                RescuersPage()),
            navItem("Mobile App Dashboard", Icons.dashboard, "MobileDashboard",
                MobileDashboardPage()),
            const Spacer(),
            // Logout button
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: MediaQuery.sizeOf(context).width * 0.24,
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 50),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0XFF2294C9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(37),
                    ),
                  ),
                  child: const SizedBox(
                    height: 41,
                    width: 162,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 19),
                          Text(
                            "Log Out",
                            style: TextStyle(
                                fontFamily: "SFPro",
                                fontSize: 20,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
