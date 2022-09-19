import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:thermal_humid_monitor_app/infor.dart';

class NotificationTab extends StatefulWidget {
  const NotificationTab({super.key});

  @override
  _NotificationTabState createState() {
    return _NotificationTabState();
  }
}

class _NotificationTabState extends State<NotificationTab> {
  User? currentUser;
  List<Infor> notificationsList = [];

  @override
  void initState() {
    // getLEDStatus();
    // getToken();
    // realtimeLEDStatus();
    // realtimePmvPpdStatus();

    authenticateFirebase();
    readNotifications();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Notification Bar",
      home: Scaffold(
        body: CustomScrollView(
          slivers: <Widget>[
            const CupertinoSliverNavigationBar(
              largeTitle: Text(
                'Notifications',
                // textAlign: TextAlign.center,
                style: TextStyle(color: Colors.green, fontSize: 18.0),
              ),
              //backgroundColor: Colors.green,
            ),
            SliverFixedExtentList(
              itemExtent: 60.0,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.lightGreen,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.email,
                        color: Colors.green,
                        size: 25.0,
                      ),
                      title: Text(notificationsList[index].state),
                      subtitle: Text(
                        '${notificationsList[index].info} °C - ${DateTime.fromMillisecondsSinceEpoch(notificationsList[index].timestamp as int, isUtc: false)}',
                        maxLines: 4,
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
                childCount: notificationsList.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  readNotifications() {
    DatabaseReference starCountRef = FirebaseDatabase.instance
        .ref('users/${currentUser?.uid}/notifications/');
    starCountRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (kDebugMode) {
        print('read notifiction ---------> $data');
      }
    });
  }

  authenticateFirebase() async {
    bool stateLogin = false;
    User? user;
    List<Infor> notList = [];

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: "mohamedrks@gmail.com",
        password: "zaq1XSW@",
      );
      userCredential.user != null ? stateLogin = true : stateLogin = false;
      user = userCredential.user;
      if (user?.uid != null) {
        final notificationRef = FirebaseDatabase.instance
            .ref('users/${user?.uid}/notifications')
            .limitToLast(1);

        notificationRef.onValue.listen((DatabaseEvent event) {
          final data = event.snapshot.children.map((e) =>
              notList.add(Infor.fromJson(jsonDecode(jsonEncode(e.value)))));
          print(
              'listned notification tab  -----------------------------------> $data');
          // Map notificationMap = jsonDecode(data.toString());

          setState(() {
            notificationsList = notList;
          });
        });
      }
      if (kDebugMode) {
        print(
            "Logged in state at notification tab = --------------> $stateLogin ----> ${user?.uid}");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        if (kDebugMode) {
          print('No user found for that email.');
        }
      } else if (e.code == 'wrong-password') {
        if (kDebugMode) {
          print('Wrong password provided for that user.');
        }
      }
    }

    setState(() {
      // isLoggedIn = stateLogin;
      currentUser = user;
      // notificationsList = notList;
    });
  }
}
