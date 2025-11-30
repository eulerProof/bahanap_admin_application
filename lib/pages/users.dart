import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'map.dart';
import 'mobile_dashboard.dart';
import 'operations.dart';
import 'package:bahanap_admin_application/pages/sidebar_navigation.dart';
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
        stream: FirebaseFirestore.instance.collection("profiles").where("role", isEqualTo: "Rescuee").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                  Expanded(
                    flex: 1,
                    child: SidebarNavigation(activePage: "Users"),
                  ),
                  Expanded(
                      flex: 3,
                      child: Column(children: [
                        Container(
                          height: 100,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.fromLTRB(40, 15, 15, 15),
                          child: const Text(
                            "Users",
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
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent:
                                              550, // max width of each grid item
                                          mainAxisSpacing: 15,
                                          crossAxisSpacing: 15,
                                          mainAxisExtent:
                                              150, // << fixed height in pixels!
                                        ),
                                        itemCount: snapshot.data!.docs.length,
                                        itemBuilder: (context, int i) {
                                          final users =
                                              snapshot.data!.docs.toList();
                                          final user = users[i];
                                          final name = user['Name'] ??
                                              "No Name Provided";
                                          final phoneNumber =
                                              user['PhoneNumber'] ??
                                                  "No Phone Number Provided";
                                          
                                         
                                            return Container(
                                              decoration: BoxDecoration(
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withValues(alpha: 0.5),
                                                    spreadRadius: 3,
                                                    blurRadius: 5,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.only(
                                                    right: 30),
                                                width: 600,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .fromLTRB(
                                                          30, 5, 0, 5),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            name
                                                                .toString()
                                                                .trim(),
                                                            style: TextStyle(
                                                              fontSize: 24,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            "Phone Number: " +
                                                                phoneNumber
                                                                    .toString(),
                                                            style: TextStyle(
                                                              fontSize: 15,
                                                              color: Color(
                                                                  0XFF2294C9),
                                                            ),
                                                          ),
                                                          Text(
                                                            "Citizen",
                                                            style: TextStyle(
                                                              fontSize: 15,
                                                              color:
                                                                  Colors.grey,
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
                      ]))
                ],
              ));
        });
  }
}
