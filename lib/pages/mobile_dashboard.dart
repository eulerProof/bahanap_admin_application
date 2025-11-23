import 'package:bahanap_admin_application/pages/mobile_dashboard.dart';
import 'package:bahanap_admin_application/pages/rescuers.dart';
import 'package:bahanap_admin_application/pages/users.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'map.dart';
import 'dart:async';
import 'dart:convert';
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
  String? value;
  String _responseMessage = '';
  bool showAddPage = false;
  String selectedCategory = "Pre-disaster"; // default dropdown value
  DropdownMenuItem<String> buildMenuItem(String waterLev) => DropdownMenuItem(
      value: waterLev,
      child: Text(
        waterLev,
      ),
    );
  final guidelines = [
    {
      "guideline": "SOmething",
      "category": "pre-disaster"
    }
  ];
    
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(color: Colors.black, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true, // makes the dropdown take full width
                              onChanged: (value) {
                                setState(() => selectedCategory = value!);
                              },
                              items: const [
                                DropdownMenuItem(value: "Pre-disaster", child: Text("Pre-disaster", style: TextStyle(fontWeight: FontWeight.bold),)),
                                DropdownMenuItem(value: "During disaster", child: Text("During disaster", style: TextStyle(fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: "Post-disaster", child: Text("Post-disaster", style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                              dropdownColor: Colors.white,
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.black, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.black, width: 2),
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
                              padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
                              backgroundColor: Colors.white,
                              
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(37), 
                              ),
                              
                            ), 
                            child: const Text("Back",
                              style: TextStyle(
                                color: Color(0xff32ade6),
                                fontSize: 18,

                              ),
                            
                            ),
                            ),
                            const SizedBox(width: 10,),
                            ElevatedButton(
                              onPressed: () async {
                                final guidelineText = textController.text;
                                if (guidelineText.isEmpty) return;

                                // Prepare JSON
                                final jsonData = {
                                  "category": selectedCategory,
                                  "content": guidelineText,
                                  
                                  "timestamp": DateTime.now().toIso8601String(),
                                };

                                try {
                                  // Send to ESP32
                                  const String esp32IP = "192.168.4.2"; // or your node's IP
                                  final response = await http.post(
                                    Uri.parse('http://$esp32IP/message'),
                                    headers: {"Content-Type": "application/json"},
                                    body: jsonEncode(jsonData),
                                  );

                                  if (response.statusCode == 200) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Guideline sent successfully")),
                                    );
                                    textController.clear();
                                    setState(() => showAddPage = false);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Failed: ${response.statusCode}")),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error sending guideline: $e")),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
                              backgroundColor: Color(0xff32ade6),
                              
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(37), 
                              ),
                              
                            ), 
                            child: const Text("Add Guideline",
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
                        const Expanded(
                          // child: guidelines.isEmpty
                          //     ? 
                          // child: const Center(
                          //         child: Text("Empty"),
                          //       )
                          child:
                              // ListView.builder(
                              //     itemCount: guidelines.length,
                              //     itemBuilder: (context, index) {
                              //       final item = guidelines[index];
                              //       return Card(
                              //         margin:
                              //             const EdgeInsets.symmetric(vertical: 8),
                              //         child: ListTile(
                              //           title: Text(item["guideline"]),
                              //           subtitle: Text(item["content"]),
                              //         ),
                              //       );
                              //     },
                              //   ),
                              //placeholder for now:
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text("Pre-Disaster", style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Text("• Stay informed: Monitor weather updates, news, and warnings from authorities. Knowing risks helps in early preparation.", 
                                    style: TextStyle(
                                      fontSize: 14,
                                      ),
                                  ),
                                  Text("• Prepare an emergency kit – Pack essentials like food, water, medicine, flashlights, batteries, and important documents.", 
                                    style: TextStyle(
                                      fontSize: 14,
                                      ),
                                  ),
                                  Text("• Create and practice an evacuation plan – Know safe routes, emergency exits, and meeting points for family or community.", 
                                    style: TextStyle(
                                      fontSize: 14,
                                      ),
                                  ),
                                  Text(""),
                                  Text("During Disaster", style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Text("• Stay calm and follow safety protocols – Panic can lead to poor decisions; remain focused on survival.", 
                                    style: TextStyle(
                                      fontSize: 14,
                                      ),
                                  ),
                                  Text("• Evacuate if advised – Leave early to avoid getting trapped in dangerous situations. Follow official evacuation routes.", 
                                    style: TextStyle(
                                      fontSize: 14,
                                      ),
                                  ),
                                  Text("• Seek shelter in safe locations – Stay indoors during storms, go to higher ground during floods, or take cover during earthquakes.", 
                                    style: TextStyle(
                                      fontSize: 14,
                                      ),
                                  ),
                                  Text(""),
                                  Text("Post-Disaster", style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Text("• Check for injuries and seek medical help – Treat minor wounds and call for assistance if needed.", 
                                    style: TextStyle(
                                      fontSize: 14,
                                      ),
                                  ),
                                  Text("• Wait for clearance before returning home – Authorities will assess if it’s safe before allowing re-entry.", 
                                    style: TextStyle(
                                      fontSize: 14,
                                      ),
                                  ),
                                  Text("• Report damages and hazards – Inform officials about collapsed structures, gas leaks, or downed power lines.", 
                                    style: TextStyle(
                                      fontSize: 14,
                                      ),
                                  ),
                                ],
                              )
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
                          decoration: const BoxDecoration(
                          color: Color(0xff2294C9),
                        ),
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
                    child: const Text("Mobile Dashboard",
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
                         const Text("Water Level",
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
                          padding: const EdgeInsets.fromLTRB(10, 0, 15, 0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black,
                              width: 1.0
                            ),
                            borderRadius: BorderRadius.circular(20.0)
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                            isExpanded: true,
                            iconStyleData: const IconStyleData(icon: Icon(Icons.keyboard_arrow_down_rounded), iconEnabledColor: Colors.black),
                          value: value,
                          items: waterLevel.map(buildMenuItem).toList(), 
                          onChanged: (value) => setState(() =>
                            this.value = value
                          ),
                          dropdownStyleData: const DropdownStyleData(
                            direction: DropdownDirection.textDirection
                          ),
                      
                        ), 

                          ) 
                          
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            //placeholder for saving water level to IOT 
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.grey, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22), // optional rounded corners
                            ),
                            
                          ), 
                          child: const Text("Save",
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.black
                            ),  
                          )
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        const Text("Disaster Preparedness Guidelines",
                        textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: "SFPro",
                            fontSize: 33,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                        ),),
                        const SizedBox(
                          height: 8,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            showEditPopup(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.grey, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22), // optional rounded corners
                            ),
                            
                          ), 
                          child: const Text("Open",
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.black
                            ),  
                          )
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        const Text("Evacuation Centers Map",
                        textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: "SFPro",
                            fontSize: 33,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                        ),),
                        const SizedBox(
                          height: 8,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            showEditPopup(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.fromLTRB(35, 14, 35, 14),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.grey, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22), // optional rounded corners
                            ),
                            
                          ), 
                          child: const Text("Upload File",
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.black
                            ),  
                          )
                        ),
                      ],
                    ),
                        )
                      ],
                    )
                    
                  
                  ),
                  

                ]
              ))
                  

        ],
      )   
        
    );

    
  }
}
