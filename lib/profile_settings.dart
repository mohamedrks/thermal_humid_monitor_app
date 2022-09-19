import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// import 'package:chaquopy/chaquopy.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class ProfileSettingsTab extends StatefulWidget {
  const ProfileSettingsTab({super.key});

  @override
  _ProfileSettingsTabState createState() {
    return _ProfileSettingsTabState();
  }
}

class _ProfileSettingsTabState extends State<ProfileSettingsTab> {
  final DBref = FirebaseDatabase.instance.ref();

  late TextEditingController _controller;
  late FocusNode _focusNode;

  String _outputOrError = "";

  bool isLoading = false;
  int ledStatus = 0;
  int realtime = 0;
  Color buttonColor = Colors.grey;
  String buttonText = "";
  bool isLoggedIn = false;
  User? currentUser;
  String? currentUserUid;
  int realtimeHumid = 0;

  double _currentSliderValue = 10;

  @override
  void initState() {
    isLoading = true;
    // getLEDStatus();
    // getToken();
    // realtimeLEDStatus();
    // realtimePmvPpdStatus();
    readPersonalTemperature();
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
            
            // This title is visible in both collapsed and expanded states.
            // When the "middle" parameter is omitted, the widget provided
            // in the "largeTitle" parameter is used instead in the collapsed state.
            largeTitle: Text(
              'Personal Thermal Comfort',
              style: TextStyle(color: Colors.green, fontSize: 24),
            ),
            // trailing: Icon(CupertinoIcons.add_circled),
          ),
          // This widget fills the remaining space in the viewport.
          // Drag the scrollable area to collapse the CupertinoSliverNavigationBar.
          SliverFillRemaining(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text(
                  '$_currentSliderValue',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 164,
                  ),
                ),
                CupertinoSlider(
                  key: const Key('slider'),
                  value: _currentSliderValue,
                  // This allows the slider to jump between divisions.
                  // If null, the slide movement is continuous.
                  divisions: 60,
                  // The maximum slider value
                  min: 10,
                  max: 40,
                  activeColor: CupertinoColors.activeGreen,
                  thumbColor: CupertinoColors.activeGreen,
                  // This is called when sliding is started.
                  onChangeStart: (double value) {
                    setState(() {
                      // _sliderStatus = 'Sliding';
                    });
                  },
                  // This is called when sliding has ended.
                  onChangeEnd: (double value) async {
                    // _sliderStatus = 'Finished sliding';
                    UserCredential userCredential =
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: "mohamedrks@gmail.com",
                      password: "zaq1XSW@",
                    );
                    String? loggedUserUid = userCredential.user?.uid;
                    if (kDebugMode) {
                      print("LoggedInUserUid = -------> $loggedUserUid");
                    }
                    DatabaseReference ref = FirebaseDatabase.instance
                        // .ref("users/${currentUser?.uid}");
                        .ref("profiles/users/$loggedUserUid");

                    await ref.set({
                      "name": "Riki",
                      "age": 28,
                      "personal_temperature": value,
                      "address": {"line1": "100 Mountain View"}
                    });
                  },
                  // This is called when slider value is changed.
                  onChanged: (double value) {
                    setState(() {
                      _currentSliderValue = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  readPersonalTemperature() async {
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: "mohamedrks@gmail.com",
      password: "zaq1XSW@",
    );
    String? loggedUserUid = userCredential.user?.uid;

    DBref.child('profiles/users/$loggedUserUid/personal_temperature')
        .onValue
        .listen((event) {
      String data = event.snapshot.value.toString();
      print('value ---------> $data');
      setState(() {
        _currentSliderValue = double.parse(data);
        // final result = await fetchThermal();
        // _outputOrError = '${result.pmv} , ${result.ppd}';
      });
    });
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

  void realtimeLEDStatus() {
    DBref.child('TEMP_VALUE').onValue.listen((event) {
      int data = event.snapshot.value as int;

      setState(() {
        realtime = data;
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
          changeButtonColor(result.pmv);
        });
      }
    });
  }

  changeButtonColor(double pmv) {
    Color currentColor = Colors.grey;
    String currentButtonText = "";
    if (pmv > 3) {
      currentColor = Colors.red;
      currentButtonText = "Hot";
    } else if (pmv < 3 && pmv >= 2) {
      currentColor = Colors.pink;
      currentButtonText = "Warm";
    } else if (pmv < 2 && pmv >= 0.5) {
      currentColor = Colors.pinkAccent;
      currentButtonText = "Slightly Warm";
    } else if (pmv < 0.5 && pmv >= -1) {
      currentColor = Colors.lightBlueAccent;
      currentButtonText = "Neutral";
    } else if (pmv < -1 && pmv >= -2) {
      currentColor = Colors.lightBlue;
      currentButtonText = "Slightly Cold";
    } else if (pmv < -2 && pmv >= -3) {
      currentColor = Colors.blue;
      currentButtonText = "Cool";
    } else if (pmv < -3) {
      currentColor = Colors.blueAccent;
      currentButtonText = "Cold";
    } else {
      currentColor = Colors.grey;
    }

    setState(() {
      buttonColor = currentColor;
      buttonText = currentButtonText;
    });
  }

  getLEDStatus() async {
    await DBref.child('LED_STATUS').once().then((DatabaseEvent databaseEvent) {
      ledStatus = databaseEvent.snapshot.value as int;
      if (kDebugMode) {
        print(ledStatus);
      }
    });

    setState(() {
      isLoading = false;
    });
  }

  void buttonPressed() {
    ledStatus == 0
        ? DBref.child('LED_STATUS').set(1)
        : DBref.child('LED_STATUS').set(0);
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

  const Thermal({
    required this.pmv,
    required this.ppd,
  });

  factory Thermal.fromJson(Map<String, dynamic> json) {
    return Thermal(
      ppd: json['ppd'],
      pmv: json['pmv'],
    );
  }
}
