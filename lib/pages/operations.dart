import 'package:flutter/material.dart';

class OperationsPage extends StatefulWidget {
  const OperationsPage({super.key});
  @override
  _OperationsPageState createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x0032ade6),
      body: Row(
        children: [
          SafeArea(
            child: Container (
              width: 371,
              decoration: BoxDecoration(
                color: Color(0xff32ade6),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: EdgeInsets.fromLTRB(40, 45, 40, 0),
                      child: Container(
                        height: 82,
                        child: Text("BaHanap", style: TextStyle(
                        fontSize: 62,
                        fontFamily: 'Gilroy',
                        color: Colors.white,
                        letterSpacing: -4.0,
                      ),),
                      ),
                    ),
                      
                      Padding(padding: EdgeInsets.fromLTRB(40, 0, 40, 30),
                        child: Container(
                        width: 138,
                        height: 27,
                        decoration: BoxDecoration(
                          color: Color(0xff3d3d3d),
                          borderRadius: BorderRadius.circular(37),),
                          child: Center(
                            child: const Text("Administrator", style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'SFPro',
                          ))
                          ),
                      ),
                      ),
                      
                      Container(
                        width: 371,
                        padding: EdgeInsets.fromLTRB(44, 10, 0, 10),
                        decoration: BoxDecoration(
                          color: Color(0xff2294C9),
                        ),
                        child: Row(
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
                      ),
                      Container(
                        width: 371,
                        padding: EdgeInsets.fromLTRB(44, 10, 0, 10),
                        child: Row(
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
                      Container(
                        width: 371,
                        padding: EdgeInsets.fromLTRB(44, 10, 0, 10),
                        child: Row(
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
                      ),
                      Container(
                        width: 371,
                        padding: EdgeInsets.fromLTRB(44, 10, 0, 10),
                        
                        child: Row(
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
                      Container(
                        width: 371,
                        padding: EdgeInsets.fromLTRB(44, 10, 0, 10),
                        child: Row(
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
                  ],
                ),
              
              ),),
        ],
      )     
    );
  }
}
