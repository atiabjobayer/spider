import 'package:flutter/material.dart';
import 'package:spider/views/alarm.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

class StopwatchView extends StatefulWidget {
  static Future<void> navigatorPush(BuildContext context) async {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => StopwatchView(),
      ),
    );
  }

  @override
  _State createState() => _State();
}

class _State extends State<StopwatchView> {
  final _isHours = true;

  final StopWatchTimer _stopWatchTimer = StopWatchTimer(
    mode: StopWatchMode.countUp,
  );

  final _scrollController = ScrollController();

  bool running = false;

  @override
  void initState() {
    super.initState();

    /// Can be set preset time. This case is "00:01.23".
    // _stopWatchTimer.setPresetTime(mSec: 1234);
  }

  @override
  void dispose() async {
    super.dispose();
    await _stopWatchTimer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stopwatch'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
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

          if (value == 1) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => AlarmView(),
            ));
          }
        },
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            /// Display stop watch time
            StreamBuilder<int>(
              stream: _stopWatchTimer.rawTime,
              initialData: _stopWatchTimer.rawTime.value,
              builder: (context, snap) {
                final value = snap.data!;
                final displayTime =
                    StopWatchTimer.getDisplayTime(value, hours: _isHours);
                return Column(
                  children: <Widget>[
                    Text(
                      displayTime,
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),

            /// Lap time.
            Container(
              height: 150,
              margin: const EdgeInsets.all(20),
              child: StreamBuilder<List<StopWatchRecord>>(
                stream: _stopWatchTimer.records,
                initialData: _stopWatchTimer.records.value,
                builder: (context, snap) {
                  final value = snap.data!;
                  if (value.isEmpty) {
                    return Container();
                  }
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut);
                  });
                  print('Listen records. $value');
                  return ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int index) {
                      final data = value[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Column(
                          children: <Widget>[
                            Text(
                              '${index + 1}         ${data.displayTime}',
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const Divider(
                              height: 10,
                            )
                          ],
                        ),
                      );
                    },
                    itemCount: value.length,
                  );
                },
              ),
            ),
            SizedBox(
              height: 50,
            ),

            /// Button
            Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                running ? Colors.red : Colors.green)),
                        onPressed: () {
                          if (running) {
                            _stopWatchTimer.onExecute
                                .add(StopWatchExecute.stop);
                          } else {
                            _stopWatchTimer.onExecute
                                .add(StopWatchExecute.start);
                          }
                          setState(() {
                            running = !running;
                          });
                        },
                        child: Text(running ? "Stop" : "Start")),
                    ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Colors.pinkAccent)),
                      onPressed: () async {
                        _stopWatchTimer.onExecute.add(StopWatchExecute.reset);
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        _stopWatchTimer.onExecute.add(StopWatchExecute.lap);
                      },
                      child: const Text(
                        'Lap',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
