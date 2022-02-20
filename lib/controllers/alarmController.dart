import 'dart:math';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AlarmController extends GetxController {
  final box = GetStorage();

  List<dynamic>? _alarmIds;
  Map<dynamic, dynamic>? _alarms;

  DateTime? date;

  List<dynamic>? get alarmIds {
    _alarmIds = box.read("spideralarms");
    return this._alarmIds;
  }

  Map<dynamic, dynamic>? get alarms {
    return _alarms;
  }

  Map<dynamic, dynamic>? getAlarm(int id) {
    return _alarms![id];
  }

  void updateAlarmIds(List<int> ids) {
    this._alarmIds = ids;
  }

  void fetchAlarmDetails() {
    for (int i = 0; i < _alarmIds!.length; i++) {
      int id = _alarmIds![i];

      var alarmDetail = box.read("spideralarm_$id");

      _alarms = _alarms ?? <dynamic, dynamic>{};

      _alarms![id] = alarmDetail;
    }
  }

  void toggleAlarm(int id, bool flag) {
    _alarms![id]["enabled"] = flag == true ? 1 : 0;

    box.write("spideralarm_$id", _alarms![id]);
  }

  void addAlarm(int id, var alarmData) async {
    _alarmIds?.add(id);
    _alarms?[id] = alarmData;

    box.write("spideralarms", _alarmIds);
    box.write("spideralarm_$id", alarmData);

    // await AndroidAlarmManager.oneShotAt(
    //     , Random().nextInt(pow(2, 31) as int), callback,
    //     alarmClock: true, allowWhileIdle: true, exact: true);

    // AndroidAlarmManager.oneShot(
    //     Duration(
    //         hours: timeDiff["hour"]!,
    //         minutes: timeDiff["minute"]!,
    //         seconds: timeDiff["second"]!),
    //     id,
    //     callback,
    //     alarmClock: true,
    //     allowWhileIdle: true,
    //     exact: true,
    //     wakeup: true);
    //var date = DateTime(2022, 1, 22, 15, 12, 00);

    // AndroidAlarmManager.oneShotAt(
    //     date, Random().nextInt(pow(2, 31) as int), callback,
    //     alarmClock: true, allowWhileIdle: true, exact: true);
  }

  void callback() {
    print("Alarm Fired");
  }

  void removeAlarm(int id) {
    _alarmIds!.remove(id);
    _alarms!.remove(id);

    box.write("spideralarms", _alarmIds);
    box.remove("spideralarm_$id");

    update();
  }
}
