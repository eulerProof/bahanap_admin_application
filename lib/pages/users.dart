import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:bahanap_admin_application/pages/received_json_provider.dart';
import 'package:bahanap_admin_application/pages/sidebar_navigation.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  
  // 🟢 1. REFRESH: Helper to update Firestore AND refresh local list
  void _refreshData() {
    Provider.of<ReceivedJSONProvider>(context, listen: false).fetchAllProfiles();
  }

  void _blacklistUser(String docId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Blacklist User"),
        content: Text("Are you sure you want to blacklist $userName?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // 1. Update Firestore
              await FirebaseFirestore.instance
                  .collection("profiles")
                  .doc(docId)
                  .update({"role": "Blacklisted"});
              
              // 2. Refresh Provider (This moves them from _users to _blacklisted in memory)
              if (mounted) {
                Navigator.pop(context);
                _refreshData(); // <--- CRITICAL
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$userName has been blacklisted."))
                );
              }
            },
            child: const Text("Blacklist", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _unblockUser(String docId, String userName) async {
    await FirebaseFirestore.instance
        .collection("profiles")
        .doc(docId)
        .update({"role": "Rescuee"});
    
    // Refresh lists immediately so they disappear from dialog and appear in grid
    _refreshData(); 
  }

  void _showBlacklistedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Container(
            width: 500,
            height: 600,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Blacklisted Users", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                Expanded(
                  // 🟢 2. CONSUMER: Read cached blacklisted list
                  child: Consumer<ReceivedJSONProvider>(
                    builder: (context, provider, child) {
                      final blockedList = provider.blacklisted;

                      if (blockedList.isEmpty) return const Center(child: Text("No blacklisted users."));

                      return ListView.separated(
                        itemCount: blockedList.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final user = blockedList[index];
                          return ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.block, color: Colors.white)),
                            title: Text(user['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(user['phone']!),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => _unblockUser(user['id']!, user['name']!),
                              child: const Text("Unblock", style: TextStyle(color: Colors.white)),
                            ),
                          );
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          ),
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
          Expanded(flex: 1, child: SidebarNavigation(activePage: "Users")),
          Expanded(
            flex: 3,
            child: Column(children: [
              Container(
                height: 100,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.fromLTRB(40, 15, 40, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Users",
                      style: TextStyle(fontFamily: "SFPro", fontSize: 43, fontWeight: FontWeight.bold, color: Color(0xff2294C9)),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showBlacklistedDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)
                      ),
                      icon: const Icon(Icons.list),
                      label: const Text("Blacklisted Users"),
                    ),
                  ],
                ),
              ),
              const Divider(),
              
              // 🟢 3. CONSUMER: Main Grid using Cached Data
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Consumer<ReceivedJSONProvider>(
                    builder: (context, provider, child) {
                      final usersList = provider.users; // Get Cached List

                      if (usersList.isEmpty) {
                        return const Center(child: Text("No Users Found"));
                      }

                      return ListView(
                        clipBehavior: Clip.none,
                        children: [
                          GridView.builder(
                            clipBehavior: Clip.none,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 550,
                              mainAxisSpacing: 15,
                              crossAxisSpacing: 15,
                              mainAxisExtent: 150,
                            ),
                            itemCount: usersList.length,
                            itemBuilder: (context, index) {
                              final user = usersList[index];
                              
                              return Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(color: Colors.grey.withOpacity(0.5), spreadRadius: 3, blurRadius: 5, offset: const Offset(0, 3)),
                                  ],
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.only(right: 20),
                                  width: 600,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.fromLTRB(30, 5, 0, 5),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(user['name']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                              Text("Phone: ${user['phone']}", style: const TextStyle(fontSize: 15, color: Color(0XFF2294C9))),
                                              const Text("Citizen", style: TextStyle(fontSize: 15, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () => _blacklistUser(user['id']!, user['name']!),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12)
                                            ),
                                            child: const Text("Blacklist", style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              )
            ]),
          )
        ],
      ),
    );
  }
}