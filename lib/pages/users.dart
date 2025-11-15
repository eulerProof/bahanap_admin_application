import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'map.dart';
import 'mobile_dashboard.dart';
import 'operations.dart';
import 'rescuers.dart';
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection("profiles").snapshots(),  
      builder: (context, snapshot) {
                    if(snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Text("No Data Received"),
                      );
                    }

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
                        decoration: const BoxDecoration(
                          color: Color(0xff2294C9),
                        ),
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
                    child: const Text("Users",
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
                    child: Padding(
                      padding: EdgeInsets.all(20),
                    child: ListView(
                      clipBehavior: Clip.none,
                    children: [
                      GridView.builder(
                          clipBehavior: Clip.none,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent:
                                550, // max width of each grid item
                            mainAxisSpacing: 15,
                            crossAxisSpacing: 15,
                            mainAxisExtent: 150, // << fixed height in pixels!
                          ),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, int i) {
                            final users = snapshot.data!.docs.toList();
                            final user = users[i];
                            final name = user['Name'] ?? "No Name Provided";
                            final phoneNumber = user['PhoneNumber'] ?? "No Phone Number Provided";
                            final coordinates = user['Coordinates'];

                            return Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.5),
                                    spreadRadius: 3,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.only(right: 30),
                                  width: 600,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            30, 5, 0, 5),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              name.toString().trim(),
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            
                                            Text(
                                              "Phone Number: " + phoneNumber.toString(),
                                              style: TextStyle(
                                                fontSize: 15,
                                                
                                                color: Color(0XFF2294C9),
                                              ),
                                            ),
                                            Text(
                                              "Citizen",
                                              style: TextStyle(
                                                fontSize: 15,
                                               
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      
                                    ],
                                  ),
                                ));
                          })
                    ],
                  )))
                ]
              ))
                  

        ],
      )     
    );
    
  });
  }
}
