import 'dart:async';

import 'package:flutter/material.dart';

class StateTimerPage extends StatefulWidget {
  final int waitTimeInSec;
  const StateTimerPage({Key? key, required this.waitTimeInSec}) : super(key: key);

  @override
  _StateTimerPageState createState() => _StateTimerPageState();
}

class _StateTimerPageState extends State<StateTimerPage> {
  Timer? _timer;
  late int _waitTime;
  var _percent = 1.0;
  var isStart = false;
  var timeStr = '05:00';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _waitTime = widget.waitTimeInSec;
    _calculateTime();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _timer?.cancel();
  }

  void start(BuildContext context) {
    if (_waitTime > 0) {
      setState(() {
        isStart = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _waitTime -= 1;
        _calculateTime();
        if (_waitTime <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Finished')));
          pause();
        }
      });
    }
  }

  void restart() {
    _waitTime = widget.waitTimeInSec;
    _calculateTime();
  }

  void pause() {
    _timer?.cancel();
    setState(() {
      isStart = false;
    });
  }

  void _calculateTime() {
    var minuteStr = (_waitTime ~/ 60).toString().padLeft(2, '0');
    var secondStr = (_waitTime % 60).toString().padLeft(2, '0');
    setState(() {
      _percent = _waitTime / widget.waitTimeInSec;
      timeStr = '$minuteStr:$secondStr';
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.blue,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: size.height * 0.3,
                      width: size.height * 0.3,
                      margin: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        value: _percent,
                        backgroundColor: Colors.red,
                        strokeWidth: 10,
                      ),
                    ),
                    Positioned(
                      child: Text(
                        timeStr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 50,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: size.height * 0.15,
                      width: size.height * 0.15,
                      margin: const EdgeInsets.all(20),
                      child: FloatingActionButton(
                          onPressed: (){
                            isStart ? pause() : start(context);
                          },
                          child: isStart ? const Icon(Icons.pause) : const Icon(Icons.play_arrow_outlined)),
                    ),
                    Container(
                      height: size.height * 0.15,
                      width: size.height * 0.15,
                      margin: const EdgeInsets.all(20),
                      child: FloatingActionButton(
                          onPressed: (){
                            restart();
                          },
                          child: const Icon(Icons.restart_alt)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
    );
  }
}