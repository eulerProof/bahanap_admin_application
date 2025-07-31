import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  _SignInPageState createState() => _SignInPageState();
}


class _SignInPageState extends State<SignInPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x0032ade6),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xff32ade6)),
        child: SafeArea(
          child: Center(
            child: 
              Container(
                width: 495,
                height: 544,
                padding: const EdgeInsets.all(35),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Text("BaHanap", style: TextStyle(
                        fontSize: 64,
                        fontFamily: 'Gilroy',
                        color: Color(0xff32ade6),
                        letterSpacing: -4.0,
                      ),),
                      Container(
                        width: 138,
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Color(0xff3d3d3d),
                          borderRadius: BorderRadius.circular(37),),
                          child: Center(
                            child:  Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.support_agent, size: 15, color: Colors.white,),
                                SizedBox(width: 5,),
                                const Text("Administrator", style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ))
                              ],
                            )
                          ),
                      ),
                      Column(
                        children: [
                          Container(
                            width: 400,
                            child: Text("Username", style: TextStyle(
                              fontSize: 16,
                              color: Color(0xff575757),
                              fontFamily: 'SFPro',
                            ),),
                          ),
                          Padding(padding: EdgeInsets.all(2)),
                          Container(
                            width: 410,
                            child: TextFormField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              ),
                              labelText: 'Enter username',
                              labelStyle: const TextStyle(
                              color: Color(0xFFAFAFAF), fontSize: 15),
                              ),
                          ),
                          ),
                          Padding(padding: EdgeInsets.all(12)),
                          Container(
                            width: 400,
                            child: Text("Password", style: TextStyle(
                              fontSize: 16,
                              color: Color(0xff575757),
                              fontFamily: 'SFPro',
                            ),),
                          ),
                          Padding(padding: EdgeInsets.all(2)),
                          Container(
                            width: 410,
                            child: TextFormField(
                              obscureText: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                ),
                                labelText: 'Enter password',
                                labelStyle: const TextStyle(
                                color: Color(0xFFAFAFAF), fontSize: 15),
                              ),
                          ),
                          ),
                          Padding(padding: EdgeInsets.all(19)),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                            onPressed: () {

                            },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(300, 60),
                                backgroundColor: const Color(0XFF32ade6),
                                foregroundColor: Colors.white,
                              
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: Color(0XFF32ade6),
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'SfPro',
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                ),)       
      ),
      ),)
     
      
      
    );
  }
}
