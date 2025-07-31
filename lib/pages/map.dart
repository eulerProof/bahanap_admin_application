import 'package:bahanap_admin_application/pages/mobile_dashboard.dart';
import 'package:bahanap_admin_application/pages/rescuers.dart';
import 'package:bahanap_admin_application/pages/users.dart';
import 'package:flutter/material.dart';
import 'operations.dart';
class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x0032ade6),
      body: Row(
        children: [
          SafeArea(
            child: Container (
              width: MediaQuery.sizeOf(context).width * 0.24,
              decoration: const BoxDecoration(
                color: Color(0xff32ade6),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.fromLTRB(40, 45, 40, 0),
                      child: Container(
                        height: 82,
                        child: const Text("BaHanap", style: TextStyle(
                        fontSize: 62,
                        fontFamily: 'Gilroy',
                        color: Colors.white,
                        letterSpacing: -4.0,
                      ),),
                      ),
                    ),
                      
                      Padding(padding: const EdgeInsets.fromLTRB(40, 0, 40, 30),
                        child: Container(
                        width: 138,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xff3d3d3d),
                          borderRadius: BorderRadius.circular(37),),
                          child: const Center(
                            child:  Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.support_agent, size: 15, color: Colors.white,),
                                SizedBox(width: 5,),
                                Text("Administrator", style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ))
                              ],
                            )
                          ),
                      ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MapPage(),
                              ),
                            );
                        },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xff2294C9),
                        ),
                        width: MediaQuery.sizeOf(context).width * 0.24,
                        padding: const EdgeInsets.fromLTRB(44, 10, 0, 10),
                        
                        child: const Row(
                          children: [
                            Icon(
                              Icons.map,
                              color: Colors.white,
                              size: 25,

                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text("Map", style: TextStyle(
                              fontFamily: "SFPro",
                              fontSize: 20,
                              color: Colors.white,
                            ),)
                          ],
                        ),
                      ),),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OperationsPage(),
                              ),
                            );
                        },
                        child: Container(
                        width: MediaQuery.sizeOf(context).width * 0.24,
                        
                        padding: const EdgeInsets.fromLTRB(44, 10, 0, 10),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.track_changes,
                              color: Colors.white,
                              size: 25,

                            ),
                             SizedBox(
                              width: 10,
                            ),
                            Text("Operations", style: TextStyle(
                              fontFamily: "SFPro",
                              fontSize: 20,
                              color: Colors.white,
                            ),)
                          ],
                        ),
                      ),
                      ),
                      GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UsersPage(),
                              ),
                            );
                          },
                      child: Container(
                        
                        width: MediaQuery.sizeOf(context).width * 0.24,
                        padding: const EdgeInsets.fromLTRB(44, 10, 0, 10),
                        child: 
                          const Row(
                          children: [
                            Icon(
                              Icons.supervised_user_circle,
                              color: Colors.white,
                              size: 25,

                            ),
                             SizedBox(
                              width: 10,
                            ),
                            Text("Users", style: TextStyle(
                              fontFamily: "SFPro",
                              fontSize: 20,
                              color: Colors.white,
                            ),)
                          ],
                        ),
                        )
                      ),
                      GestureDetector(
                        onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RescuersPage(),
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
                             SizedBox(
                              width: 10,
                            ),
                            Text("Rescuers", style: TextStyle(
                              fontFamily: "SFPro",
                              fontSize: 20,
                              color: Colors.white,
                            ),)
                          ],
                        ),
                      ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MobileDashboardPage(),
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
                             SizedBox(
                              width: 10,
                            ),
                            Text("Mobile App Dashboard", style: TextStyle(
                              fontFamily: "SFPro",
                              fontSize: 20,
                              color: Colors.white,
                            ),)
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
              Expanded(child: Column(
                children: [
                  Container(
                    height: 100,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.fromLTRB(40, 15, 15, 15),
                    child: const Text("Map",
                      style: TextStyle(
                        fontFamily: "SFPro",
                        fontSize: 43,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2294C9),
                    ),
                    ),
                  ),
                ]
              ))
                  

        ],
      )     
    );
  }
}
