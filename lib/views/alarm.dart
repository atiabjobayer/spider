// ignore_for_file: prefer_const_constructors

import 'dart:isolate';
import 'dart:math';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spider/controllers/alarmController.dart';
import 'package:flutter/services.dart';
import 'package:spider/views/stopwatch.dart';
import 'package:system_alert_window/system_alert_window.dart';

import '../rahi.dart';

final alarmController = Get.put(AlarmController());

const String isolateName = 'isolate';

// /// A port used to communicate from a background isolate to the UI isolate.
// final ReceivePort port = ReceivePort();

void tagListener(tag) {
  WidgetsFlutterBinding.ensureInitialized();
  print("$tag tag called");

  if (tag == "close") {
    SystemAlertWindow.closeSystemWindow();
  }
}

class AlarmView extends StatefulWidget {
  const AlarmView({Key? key}) : super(key: key);

  @override
  _AlarmViewState createState() => _AlarmViewState();
}

class _AlarmViewState extends State<AlarmView> {
  bool flag = true;
  final box = GetStorage();

  String _platformVersion = 'Unknown';

  bool _isShowingWindow = false;
  bool _isUpdatedWindow = false;

  SystemWindowPrefMode prefMode = SystemWindowPrefMode.OVERLAY;

  @override
  void initState() {
    super.initState();
    AndroidAlarmManager.initialize();
    _initPlatformState();
    _requestPermissions();
    //SystemAlertWindow.registerOnClickListener(callback);
    // Register for events from the background isolate. These messages will
    // always coincide with an alarm firing.
    //port.listen((_) async => await _incrementCounter());

    SystemAlertWindow?.registerOnClickListener(tagListener);
    _player = AudioPlayer();
  }

  Future<void> _initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = (await SystemAlertWindow.platformVersion)!;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _requestPermissions() async {
    await SystemAlertWindow.requestPermissions(prefMode: prefMode);
  }

  static SendPort? uiSendPort;

  static Future<void> callback(int alarmId) async {
    developer.log('Alarm fired! ' + alarmId.toString());
    // Get the previous cached count and increment it.

    // This will be null if we're running in the background.
    uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
    uiSendPort?.send(null);

    WidgetsFlutterBinding.ensureInitialized();

    _AlarmViewState().showOverlayWindow(alarmId);
  }

  late AudioPlayer _player;

  @override
  Widget build(BuildContext context) {
    //box.write("spideralarms", null);
    //var alarms = box.read("spideralarms");
    //print(alarms);

    //var alarm;

    List<dynamic>? alarmIds = alarmController.alarmIds;

    print(alarmIds);

    alarmController.fetchAlarmDetails();

    return Scaffold(
      appBar: AppBar(
        title: Text('Alarm'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          TimeOfDay initialTime = TimeOfDay.now();

          TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: initialTime,
          );

          if (pickedTime != null) {
            int alarmId = Random().nextInt(pow(2, 31) as int);

            Map<dynamic, dynamic>? alarmData = {
              "id": alarmId,
              "timeHour": pickedTime.hour.toInt(),
              "timeMinute": pickedTime.minute.toInt(),
              "meridian": pickedTime.period.toString(),
              "enabled": 1,
            };

            alarmController.addAlarm(alarmId, alarmData);

            alarmController.update();
            setState(() {});

            DateTime now = DateTime.now();

            Map<String, int> timeDiff = computeTimeDifference(
                alarmData["timeHour"] as int,
                alarmData["timeMinute"] as int,
                0,
                now.hour,
                now.minute,
                now.second);

            print("Time differece = " +
                timeDiff["hour"].toString() +
                ":" +
                timeDiff["minute"].toString() +
                ":" +
                timeDiff["second"].toString());
            await AndroidAlarmManager.oneShot(
                Duration(seconds: 5), alarmId, callback,
                alarmClock: true,
                allowWhileIdle: true,
                exact: true,
                wakeup: true);
          }

          // await AndroidAlarmManager.oneShot(
          //     Duration(
          //         hours: timeDiff["hour"]!,
          //         minutes: timeDiff["minute"]!,
          //         seconds: timeDiff["second"]!),
          //     alarmId,
          //     callback,
          //     alarmClock: true,
          //     allowWhileIdle: true,
          //     exact: true,
          //     wakeup: true);
        },
        child: Icon(Icons.add),
      ),
      //floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        showUnselectedLabels: true,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white38,
        elevation: 15,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.watch), label: 'Clock'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Alarm'),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_clock),
            label: 'Stopwatch',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.timelapse), label: 'Timer'),
        ],
        onTap: (value) {
          print(value);

          if (value == 2) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => StopwatchView(),
            ));
          }
        },
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: GetBuilder<AlarmController>(
            builder: (_) => Column(
              children: <Widget>[
                SizedBox(
                  height: 20,
                ),
                for (int i = 0; i < alarmController.alarmIds!.length; i++) ...[
                  AlarmCard(
                    alarmId:
                        alarmController.getAlarm(alarmIds![i])!["id"] as int,
                    flag: alarmController.getAlarm(alarmIds[i])!["enabled"] == 1
                        ? true
                        : false,
                    ampm: alarmController.getAlarm(alarmIds[i])!["meridian"] ==
                            DayPeriod.am
                        ? "am"
                        : "pm",
                    timeDigits: (alarmController
                                    .getAlarm(alarmIds[i])!["timeHour"]
                                    .toString()
                                    .length <
                                2
                            ? "0"
                            : "") +
                        alarmController
                            .getAlarm(alarmIds[i])!["timeHour"]
                            .toString() +
                        ":" +
                        (alarmController
                                    .getAlarm(alarmIds[i])!["timeMinute"]
                                    .toString()
                                    .length <
                                2
                            ? "0"
                            : "") +
                        alarmController
                            .getAlarm(alarmIds[i])!["timeMinute"]
                            .toString(),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, int> computeTimeDifference(int startHour, int startMinute,
      int startSecond, int endHour, int endMinute, int endSecond) {
    if (endSecond > startSecond) {
      --startMinute;
      startSecond += 60;
    }

    int diffHour = 0, diffMinute = 0, diffSecond = 0;

    diffSecond = startSecond - endSecond;

    if (endMinute > startMinute) {
      --startHour;
      startMinute += 60;
    }

    diffMinute = startMinute - endMinute;
    diffHour = startHour - endHour;

    return <String, int>{
      "hour": diffHour,
      "minute": diffMinute,
      "second": diffSecond,
    };
  }

  void showOverlayWindow(int alarmId) {
    //Map<dynamic, dynamic>? data = alarmController.getAlarm(alarmId);

    if (!_isShowingWindow) {
      SystemWindowHeader header = SystemWindowHeader(
        title: SystemWindowText(
          text: "Spider Alarm ",
          fontSize: 10,
          textColor: Colors.black45,
        ),
        padding: SystemWindowPadding.setSymmetricPadding(12, 12),
        decoration: SystemWindowDecoration(startColor: Colors.grey[100]),
      );
      SystemWindowBody body = SystemWindowBody(
        rows: [
          EachRow(
            columns: [
              EachColumn(
                text: SystemWindowText(
                    text: "AlarmID : $alarmId",
                    fontSize: 50,
                    textColor: Colors.black45),
              ),
            ],
            gravity: ContentGravity.CENTER,
          ),
        ],
        padding: SystemWindowPadding(left: 16, right: 16, bottom: 12, top: 12),
      );
      SystemWindowFooter footer = SystemWindowFooter(
          buttons: [
            SystemWindowButton(
              text: SystemWindowText(
                  text: "Dismiss", fontSize: 12, textColor: Colors.white),
              tag: "close",
              width: 0,
              padding:
                  SystemWindowPadding(left: 10, right: 10, bottom: 10, top: 10),
              height: SystemWindowButton.WRAP_CONTENT,
              decoration: SystemWindowDecoration(
                  startColor: Color.fromRGBO(250, 139, 97, 1),
                  endColor: Color.fromRGBO(247, 28, 88, 1),
                  borderWidth: 0,
                  borderRadius: 30.0),
            )
          ],
          padding: SystemWindowPadding(left: 16, right: 16, bottom: 12),
          decoration: SystemWindowDecoration(startColor: Colors.white),
          buttonsPosition: ButtonPosition.CENTER);
      SystemAlertWindow.showSystemWindow(
          height: 300,
          header: header,
          body: body,
          footer: footer,
          margin: SystemWindowMargin(left: 8, right: 8, top: 200, bottom: 0),
          gravity: SystemWindowGravity.TOP,
          notificationTitle: "Alarm",
          notificationBody: "",
          prefMode: prefMode);
      setState(() {
        _isShowingWindow = true;
      });
    } else {
      setState(() {
        _isShowingWindow = false;
        _isUpdatedWindow = false;
      });
      SystemAlertWindow.closeSystemWindow(prefMode: prefMode);
    }
  }
}

class AlarmCard extends StatelessWidget {
  const AlarmCard({
    Key? key,
    required this.alarmId,
    required this.flag,
    required this.timeDigits,
    required this.ampm,
  }) : super(key: key);

  final int alarmId;
  final bool flag;
  final String timeDigits;
  final String ampm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.white70, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //crossAxisAlignment: CrossAxisAlignment.,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        timeDigits,
                        style: TextStyle(fontSize: 50),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        ampm,
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        child: Icon(Icons.more_vert),
                        onTapDown: (details) =>
                            showPopUpMenuAtTap(context, details, alarmId),
                      ),
                    ],
                  )
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Not Scheduled'),
                  GetBuilder<AlarmController>(builder: (_) {
                    return FlutterSwitch(
                      width: 50.0,
                      height: 25.0,
                      activeColor: Theme.of(context).accentColor,
                      // valueFontSize: 25.0,
                      //toggleSize: 45.0,

                      value: _.alarms![alarmId]["enabled"] == 1 ? true : false,
                      // borderRadius: 30.0,
                      padding: 2.0,
                      //showOnOff: true,
                      onToggle: (val) {
                        print("Toggle Clicked");
                        alarmController.toggleAlarm(alarmId, val);
                        _.update();
                      },
                    );
                  }),
                ],
              ),
              SizedBox(
                height: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showPopUpMenuAtTap(
      BuildContext context, TapDownDetails details, int alarmId) async {
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        PopupMenuItem<String>(child: const Text('Edit'), value: 'Edit'),
        PopupMenuItem<String>(
          child: const Text('Delete'),
          value: 'Delete',
          onTap: () {
            alarmController.removeAlarm(alarmId);
            alarmController.update();
          },
        ),
      ],
      // other code as above
    );
  }
}
