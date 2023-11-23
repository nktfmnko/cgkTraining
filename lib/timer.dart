import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StateTimerPage extends StatefulWidget {
  final int waitTimeInSec;
  const StateTimerPage({Key? key, required this.waitTimeInSec}) : super(key: key);

  @override
  _StateTimerPageState createState() => _StateTimerPageState();
}

// Класс Таймера
class _StateTimerPageState extends State<StateTimerPage> {
  Timer? _timer;
  late int _waitTime;
  var _percent = 1.0;
  var isStart = false;
  var timeStr = '05:00';

  @override
  void initState() {
    super.initState();
    _waitTime = widget.waitTimeInSec;
    _calculateTime();
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  // Функция кнопки Старт
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

  // Функция кнопки Перезагрузки
  void restart() {
    _waitTime = widget.waitTimeInSec;
    _calculateTime();
  }

  // Функция кнопки Паузы
  void pause() {
    _timer?.cancel();
    setState(() {
      isStart = false;
    });
  }

  // Дополнительная функция для вычисления времени
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
          backgroundColor: const Color.fromARGB(200, 29, 82, 117),
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
                        strokeWidth: 11,
                        color: Colors.blue,
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
                          backgroundColor: Colors.blue,
                          onPressed: (){
                            isStart ? pause() : start(context);
                          },
                          child: isStart ? const Icon(Icons.pause, size: 80,) : const Icon(Icons.play_arrow_outlined, size: 80,)),
                    ),
                    Container(
                      height: size.height * 0.15,
                      width: size.height * 0.15,
                      margin: const EdgeInsets.all(20),
                      child: FloatingActionButton(
                        backgroundColor: Colors.blue,
                          onPressed: (){
                            restart();
                          },
                          child: const Icon(Icons.restart_alt, size: 80,)),
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