import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

// import 'package:chaquopy/chaquopy.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class ThermalMonitorTab extends StatefulWidget {
  const ThermalMonitorTab({super.key});

  @override
  _ThermalMonitorTabState createState() {
    return _ThermalMonitorTabState();
  }
}

class _ThermalMonitorTabState extends State<ThermalMonitorTab> {
  final DBref = FirebaseDatabase.instance.ref();

  late TextEditingController _controller;
  late FocusNode _focusNode;

  String _outputOrError = "";

  bool isLoading = false;
  int ledStatus = 0;
  int realtime = 0;
  int realtimeHumid = 0;
  Color buttonColor = Colors.grey;
  String buttonText = "";
  bool isLoggedIn = false;

  User? currentUser;

  @override
  void initState() {
    authenticateFirebase();
    readNotifications();
    isLoading = true;
    realtimeTempValueStatus();
    realtimeHumidValueStatus();
    realtimePmvPpdStatus();

    _controller = TextEditingController();
    _focusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // A ScrollView that creates custom scroll effects using slivers.
      child: CustomScrollView(
        // A list of sliver widgets.
        slivers: <Widget>[
          const CupertinoSliverNavigationBar(
            // leading: Icon(
            //   CupertinoIcons.suit_heart,
            //   color: Colors.red,
            // ),
            // This title is visible in both collapsed and expanded states.
            // When the "middle" parameter is omitted, the widget provided
            // in the "largeTitle" parameter is used instead in the collapsed state.
            largeTitle: Text(
              'Thermal Comfort Monitor',
              style: TextStyle(color: Colors.pink, fontSize: 24),
            ),
            // trailing: Icon(CupertinoIcons.add_circled),
          ),
          // This widget fills the remaining space in the viewport.
          // Drag the scrollable area to collapse the CupertinoSliverNavigationBar.
          SliverFillRemaining(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                // isLoading
                //     ? const CircularProgressIndicator()
                //     : ElevatedButton(
                //         child: Text(
                //           ledStatus == 0 ? 'On' : 'Off',
                //           style: GoogleFonts.nunito(
                //               fontSize: 20, fontWeight: FontWeight.w300),
                //         ),
                //         onPressed: () {
                //           buttonPressed();
                //         },
                //       ),
                // Text('TEMP_VALUE value is $ledStatus'),
                // Text('Temperature realtime led status is $realtime'),
                Row(
                  children: [
                    Expanded(
                      child: _getRadialGauge(
                        'Temperature',
                        double.parse('$realtime'),
                      ),
                    ),
                    Expanded(
                      child: _getRadialGaugeHumid(
                        'Humidity',
                        double.parse('$realtimeHumid'),
                      ),
                    )
                  ],
                ),
                CupertinoButton(
                  onPressed: () {
                    print('button press here');
                  },
                  color: buttonColor,
                  child: Text(buttonText),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Thermal> fetchThermal(
      int realtimeTempVal, int realtimeHumidVal) async {
    final response = await http.get(Uri.parse(
        'https://thermal-comfort-api.azurewebsites.net/adaptivecal/?temp=$realtimeTempVal&humid=$realtimeHumidVal'));
    // final response = await http
    //     .get(Uri.parse('https://jsonplaceholder.typicode.com/albums/1'));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return Thermal.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      print('error ------------------------------->');
      throw Exception('Failed to load album');
    }
  }

  Widget _getRadialGauge(
    String headerText,
    double temperature,
  ) {
    return SfRadialGauge(
        title: GaugeTitle(
            text: headerText,
            textStyle: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue)),
        axes: <RadialAxis>[
          RadialAxis(minimum: 0, maximum: 50, ranges: <GaugeRange>[
            GaugeRange(
                startValue: 0,
                endValue: 22,
                color: Colors.green,
                startWidth: 10,
                endWidth: 10),
            GaugeRange(
                startValue: 22,
                endValue: 28,
                color: Colors.orange,
                startWidth: 10,
                endWidth: 10),
            GaugeRange(
                startValue: 28,
                endValue: 50,
                color: Colors.red,
                startWidth: 10,
                endWidth: 10)
          ], pointers: <GaugePointer>[
            NeedlePointer(value: temperature)
          ], annotations: <GaugeAnnotation>[
            GaugeAnnotation(
                widget: Text(temperature.toString(),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                // angle: 90,
                angle: temperature,
                positionFactor: 0.5)
          ])
        ]);
  }

  Widget _getRadialGaugeHumid(
    String headerText,
    double humidity,
  ) {
    return SfRadialGauge(
        title: GaugeTitle(
            text: headerText,
            textStyle: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            )),
        axes: <RadialAxis>[
          RadialAxis(minimum: 0, maximum: 100, ranges: <GaugeRange>[
            GaugeRange(
                startValue: 0,
                endValue: 60,
                color: Colors.green,
                startWidth: 10,
                endWidth: 10),
            GaugeRange(
                startValue: 60,
                endValue: 70,
                color: Colors.orange,
                startWidth: 10,
                endWidth: 10),
            GaugeRange(
                startValue: 70,
                endValue: 100,
                color: Colors.red,
                startWidth: 10,
                endWidth: 10)
          ], pointers: <GaugePointer>[
            NeedlePointer(value: humidity)
          ], annotations: <GaugeAnnotation>[
            GaugeAnnotation(
                widget: Text(humidity.toString(),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                // angle: 90,
                angle: humidity,
                positionFactor: 0.5)
          ])
        ]);
  }

  authenticateFirebase() async {
    bool stateLogin = false;
    User? currentLoggedInUser;
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: "mohamedrks@gmail.com",
        password: "zaq1XSW@",
      );
      if (userCredential.user != null) {
        stateLogin = true;
        currentLoggedInUser = userCredential.user;
      } else {
        stateLogin = false;
      }
      String? user = userCredential.user?.uid;
      if (user != null) {
        DatabaseReference notificationRef =
            FirebaseDatabase.instance.ref('users/$user/notifications');
        notificationRef.onValue.listen((DatabaseEvent event) {
          final data = event.snapshot.value;
          // print('listned notification thermal tab  -> $data');
        });
      }
      if (kDebugMode) {
        print(
            "Logged in state Therml tab = --------------> $stateLogin ----> $user");
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
      isLoggedIn = stateLogin;
      currentUser = currentLoggedInUser;
    });
  }

  readNotifications() {
    DatabaseReference starCountRef =
        FirebaseDatabase.instance.ref('TEMP_VALUE');
    starCountRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      print('listned temp -> $data');
      print('current user id TEMP_VALUE -- > ${currentUser?.uid}');
    });

    print('current user id -- > ${currentUser?.uid}');
  }

  void realtimeTempValueStatus() {
    DBref.child('TEMP_VALUE').onValue.listen((event) {
      int data = event.snapshot.value as int;

      setState(() {
        realtime = data;
        isLoading = false;
        // final result = await fetchThermal();
        // _outputOrError = '${result.pmv} , ${result.ppd}';
      });
    });
  }

  void realtimeHumidValueStatus() {
    DBref.child('HUMID_VALUE').onValue.listen((event) {
      int data = event.snapshot.value as int;

      setState(() {
        realtimeHumid = data;
        // final result = await fetchThermal();
        // _outputOrError = '${result.pmv} , ${result.ppd}';
      });
    });
  }

  void realtimePmvPpdStatus() {
    DBref.child('TEMP_VALUE').onValue.listen((event) async {
      int temperature = event.snapshot.value as int;
      if (temperature >= 10) {
        final result = await fetchThermal(temperature, realtimeHumid);
        setState(() {
          _outputOrError = '${result.pmv} , ${result.ppd}';
          changeButtonColor(result);
        });
      }
    });
  }

  changeButtonColor(Thermal thermal) {
    Color currentColor = Colors.grey;
    String currentButtonText = "";
    // print(DateTime.now().millisecondsSinceEpoch);

    if (thermal.pmv > 3) {
      currentColor = Colors.red;
      currentButtonText = "Hot";
    } else if (thermal.pmv < 3 && thermal.pmv >= 2) {
      currentColor = Colors.pink;
      currentButtonText = "Warm";
    } else if (thermal.pmv < 2 && thermal.pmv >= 0.5) {
      currentColor = Colors.pinkAccent;
      currentButtonText = "Slightly Warm";
      
    } else if (thermal.pmv < 0.5 && thermal.pmv >= -0.5) {
      currentColor = Colors.lightBlueAccent;
      currentButtonText = "Neutral";
    } else if (thermal.pmv < -0.5 && thermal.pmv >= -1.5) {
      currentColor = Colors.lightBlue;
      currentButtonText = "Slightly Cold";
    } else if (thermal.pmv < -1.5 && thermal.pmv >= -2.5) {
      currentColor = Colors.blue;
      currentButtonText = "Cool";
    } else if (thermal.pmv < -2.5) {
      currentColor = Colors.blueAccent;
      currentButtonText = "Cold";
    } else {
      currentColor = Colors.grey;
    }
    if ((thermal.pmv > 0.5 || thermal.pmv < -0.5) && !((currentButtonText == 'Slightly Warm' && thermal.tmpup > 22) || (currentButtonText == 'Slightly Cold' && thermal.tmplow < 22))) {
      double adjustValue;

      if (thermal.pmv > 0.5) {
        adjustValue = realtime - thermal.tmpup;
      } else if (thermal.pmv < -0.5) {
        adjustValue = realtime - thermal.tmplow;
      } else {
        adjustValue = 0;
      }

      String adjustText = "";

      adjustValue > 0 ? adjustText = "reduce" : adjustText = "increase";

      // DatabaseReference ref = FirebaseDatabase.instance.ref(
      //     "users/${currentUser?.uid}/notifications/${DateTime.now().millisecondsSinceEpoch}");

      DatabaseReference postListRef = FirebaseDatabase.instance
          .ref("users/${currentUser?.uid}/notifications");
      DatabaseReference newPostRef = postListRef.push();
      newPostRef.set({
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        "temperature": realtime,
        "state": currentButtonText,
        "pmv": thermal.pmv,
        "tmpup": thermal.tmpup,
        "tmplow": thermal.tmplow,
        "adjustValue": adjustValue,
        "info":
            "Please $adjustText temperature by ${adjustValue.abs().toStringAsFixed(1)}"
      });

      print('added notification ');
    }

    setState(() {
      buttonColor = currentColor;
      buttonText = currentButtonText;
    });
  }

  void buttonPressed() {
    ledStatus == 0
        ? DBref.child('TEMP_VALUE').set(1)
        : DBref.child('TEMP_VALUE').set(0);
    if (ledStatus == 0) {
      setState(() {
        ledStatus = 1;
      });
    } else {
      setState(() {
        ledStatus = 0;
      });
    }
  }
}

// fetchUser(SendPort sendPort) {
//   //  _controller.text =
//   // "print('hello world'); from cgitb import reset; from pythermalcomfort.models import pmv_ppd; result = pmv_ppd(tdb=27, tr=27, vr=0.1, rh=50, met=1.1, clo=0.5, standard='ASHRAE'); print(result); print('hello world last');";
//   const code = "print('hello world'); print('hello world last');";
//   final result = Chaquopy.executeCode(code);
//   sendPort.send("result");
// }

class Thermal {
  final double pmv;
  final double ppd;
  final double tmplow;
  final double tmpup;

  const Thermal({
    required this.pmv,
    required this.ppd,
    required this.tmplow,
    required this.tmpup,
  });

  factory Thermal.fromJson(Map<String, dynamic> json) {
    return Thermal(
      ppd: json['ppd'],
      pmv: json['pmv'],
      tmplow: json['tmp_low'],
      tmpup: json['tmp_up'],
    );
  }
}
