import 'package:bahanap_admin_application/pages/mobile_dashboard.dart';
import 'package:bahanap_admin_application/pages/received_json_provider.dart';
import 'package:bahanap_admin_application/pages/rescuers.dart';
import 'package:bahanap_admin_application/pages/users.dart';
import 'package:bahanap_admin_application/pages/sidebar_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'map.dart';
import 'operations.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class RescuersPage extends StatefulWidget {
  const RescuersPage({super.key});
  @override
  _RescuersPageState createState() => _RescuersPageState();
}

class _RescuersPageState extends State<RescuersPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
 void _showEditDialog(Map<String, dynamic> rescuer) {
    // 1. Get the ID reliably
    final String docId = rescuer["id"] ?? rescuer["uid"] ?? rescuer["rescuerId"];

    // 2. Initialize Controllers 
    // We populate 'name' immediately if we have it locally, others start empty.
    final TextEditingController nameCtrl = 
        TextEditingController(text: rescuer["name"] ?? rescuer["Name"] ?? "");
    final TextEditingController phoneCtrl = TextEditingController();
    final TextEditingController emailCtrl = TextEditingController();

    // 3. State variable for the dialog
    bool isLoading = true;
    bool hasFetched = false; // To prevent infinite fetching loops

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            // 4. Trigger Firestore Fetch (Only once)
            if (!hasFetched) {
              hasFetched = true; // Mark as started immediately
              FirebaseFirestore.instance
                  .collection('profiles')
                  .doc(docId)
                  .get()
                  .then((snapshot) {
                if (snapshot.exists && context.mounted) {
                  final data = snapshot.data() as Map<String, dynamic>;
                  
                  // Update controllers with Firestore data
                  nameCtrl.text = data['Name'] ?? nameCtrl.text;
                  phoneCtrl.text = data['PhoneNumber'] ?? "";
                  emailCtrl.text = data['email'] ?? "";

                  // Refresh dialog to hide spinner and show form
                  setState(() {
                    isLoading = false;
                  });
                } else if (context.mounted) {
                   // Handle case where doc doesn't exist but we stop loading
                   setState(() { isLoading = false; });
                }
              }).catchError((e) {
                 print("Error fetching profile: $e");
                 if(context.mounted) setState(() { isLoading = false; });
              });
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: isLoading 
                // 🟢 SHOW LOADING SPINNER WHILE FETCHING
                ? const SizedBox(
                    height: 150,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 15),
                          Text("Fetching Rescuer Details..."),
                        ],
                      ),
                    ),
                  )
                // 🟢 SHOW FORM ONCE DATA IS READY
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Edit Rescuer",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF154961)),
                    ),
                    const SizedBox(height: 20),

                    // NAME
                    const Text("Name"),
                    TextField(controller: nameCtrl),
                    const SizedBox(height: 10),

                    // PHONE
                    const Text("Phone"),
                    TextField(controller: phoneCtrl),
                    const SizedBox(height: 10),

                    // EMAIL
                    const Text("Email"),
                    TextField(controller: emailCtrl),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.pop(context),
                        ),
                        ElevatedButton(
                          child: const Text("Update"),
                          onPressed: () async {
                            try {
                              // Update Firestore
                              await FirebaseFirestore.instance
                                  .collection("profiles")
                                  .doc(docId)
                                  .update({
                                "Name": nameCtrl.text.trim(),
                                "PhoneNumber": phoneCtrl.text.trim(),
                                "email": emailCtrl.text.trim(),
                                // Update these too just in case your fields vary
                              });

                              if (context.mounted) {
                                // Refresh the provider list
                                Provider.of<ReceivedJSONProvider>(context, listen: false)
                                    .fetchAllProfiles();

                                Navigator.pop(context); // Close dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Updated successfully")));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error updating: $e")));
                              }
                            }
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

void _confirmDelete(String rescuerId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Rescuer"),
          content: const Text(
              "Are you sure you want to delete this rescuer? This action cannot be undone."),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                try {
                  // 1. DELETE FROM FIRESTORE
                  await FirebaseFirestore.instance
                      .collection("profiles")
                      .doc(rescuerId)
                      .delete();

                  // 2. REFRESH PROVIDER
                  if (context.mounted) {
                    Provider.of<ReceivedJSONProvider>(context, listen: false)
                        .fetchAllProfiles();
                    
                    Navigator.pop(context); // Close Dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Rescuer deleted successfully")));
                  }
                } catch (e) {
                   print("Delete failed: $e");
                   if (context.mounted) {
                     Navigator.pop(context);
                     ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Delete failed: $e")));
                   }
                }
              },
            ),
          ],
        );
      },
    );
  }
  void _showSignUpSuccessDialog() async {
    final provider = Provider.of<ReceivedJSONProvider>(context, listen: false);          
    await provider.fetchAllProfiles();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Color(0XFF32ade6), size: 30),
              SizedBox(width: 10),
              Text(
                "Success!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0XFF154961),
                ),
              ),
            ],
          ),
          content: const Text(
            "Account created successfully!",
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            Center(
              child: SizedBox(
                width: 100,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0XFF32ade6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // closes success dialog
                    Navigator.of(context).pop(); // closes signup dialog
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
  void signUp() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Rescuer',
                      style: TextStyle(
                          fontFamily: 'SfPro',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF154961)),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Email Address',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF575757)),
                    ),
                    TextFormField(
                      maxLength: 45,
                      controller: _emailController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          labelText: 'Enter email address',
                          labelStyle: const TextStyle(
                              color: Color(0xFFAFAFAF), fontSize: 15)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegex =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Name',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF575757)),
                    ),
                    TextFormField(
                      controller: _nameController,
                      maxLength: 20,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          labelText: 'Enter name',
                          labelStyle: const TextStyle(
                              color: Color(0xFFAFAFAF), fontSize: 15)),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Phone number',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF575757)),
                    ),
                    TextFormField(
                      maxLength: 15,
                      controller: _phoneController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          labelText: 'Enter phone number',
                          labelStyle: const TextStyle(
                              color: Color(0xFFAFAFAF), fontSize: 15)),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Password',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF575757)),
                    ),
                    TextFormField(
                      maxLength: 20,
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          labelText: 'Enter password',
                          labelStyle: const TextStyle(
                              color: Color(0xFFAFAFAF), fontSize: 15)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Confirm Password',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF575757)),
                    ),
                    TextFormField(
                      maxLength: 20,
                      obscureText: true,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          labelText: 'Re-enter password',
                          labelStyle: const TextStyle(
                              color: Color(0xFFAFAFAF), fontSize: 15)),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final credential =
                                await _auth.createUserWithEmailAndPassword(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );

                            String uid = credential.user!.uid;
                            String rescuerId = uid;
                             
                            await _firestore
                                .collection('profiles')
                                .doc(uid)
                                .set({
                              'uid': uid,
                              'email': _emailController.text,
                              'Name': _nameController.text,
                              'PhoneNumber': _phoneController.text,
                              'role': "Rescuer",
                              'rescuerId': rescuerId,
                            });

                            _showSignUpSuccessDialog();
                          } on FirebaseAuthException catch (e) {
                            String errorMessage =
                                'An error occurred. Please try again.';
                            if (e.code == 'weak-password') {
                              errorMessage =
                                  'The password provided is too weak.';
                            } else if (e.code == 'email-already-in-use') {
                              errorMessage =
                                  'The account already exists for that email.';
                            }

                            _showDialog(
                                context, 'Sign-Up Failed', errorMessage);
                          } catch (e) {
                            print(e);
                            _showDialog(context, 'Error',
                                'An unexpected error occurred.');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(300, 60),
                          backgroundColor: Color(0XFF32ade6),
                          foregroundColor: Colors.white,
                          elevation: 5.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0XFF32ade6),
                              width: 2.0,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'SfPro'),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 70,
                    )
                  ],
                ),
              ),
            ),
          ),
          );
        });
      },
    );
  }
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
                      signUp();
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
                    padding: const EdgeInsets.all(20),
                    child: Consumer<ReceivedJSONProvider>(
                      builder: (context, provider, _) {
                        final rescuers = provider.rescuers; // this is the list

                        if (rescuers.isEmpty) {
                          return const Center(
                            child: Text("No Rescuers Available"),
                          );
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
                              itemCount: rescuers.length,
                              itemBuilder: (context, i) {
                                final rescuer = rescuers[i];
                                final name = rescuer["name"] ?? "No Name";
                                final id = rescuer["id"] ?? "No ID";

                                return Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 3,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // LEFT SIDE — Rescuer Info
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(20, 10, 0, 10),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  "ID: $id",
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Color(0XFF2294C9),
                                                  ),
                                                ),
                                                const Text(
                                                  "Rescuer",
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // RIGHT SIDE — ACTION BUTTONS
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // EDIT BUTTON
                                            SizedBox(
                                              width: 90,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  _showEditDialog(rescuer);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0XFF2294C9),
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child: const Text("Edit", style: TextStyle(color: Colors.white)),
                                              ),
                                            ),

                                            const SizedBox(height: 10),

                                            // DELETE BUTTON
                                            SizedBox(
                                              width: 90,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  final docId = rescuer["id"] ?? rescuer["uid"] ?? rescuer["rescuerId"];
                                                  _confirmDelete(docId!);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child:
                                                    const Text("Delete", style: TextStyle(color: Colors.white)),
                                              ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
