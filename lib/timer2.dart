import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class StateTimer2Page extends StatefulWidget {
  const StateTimer2Page({Key? key}) : super(key: key);

  @override
  _StateTimer2PageState createState() => _StateTimer2PageState();
}

// Класс Таймера
class _StateTimer2PageState extends State<StateTimer2Page> {
  Timer? _timer;
  late int _waitTime;
  var _percent = 1.0;
  var isStart = false;
  var timeStr = '05:00';

  @override
  void initState() {
    super.initState();
    _waitTime = 60;
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
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Finished')));
          AudioPlayer().play(AssetSource('startTimer.mp3'));
          pause();
        } else if (_waitTime == 30) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Temporary stop')));
          AudioPlayer().play(AssetSource('startTimer.mp3'));
          pause();
        }
      });
    }
  }

  // Функция кнопки Перезагрузки
  void restart() {
    _waitTime = 60;
    _calculateTime();
  }

  // Функция кнопки Паузы
  void pause() {
    _timer?.cancel();
    setState(
          () {
        isStart = false;
      },
    );
  }

  // Дополнительная функция для вычисления времени
  void _calculateTime() {
    var minuteStr = (_waitTime ~/ 60).toString().padLeft(2, '0');
    var secondStr = (_waitTime % 60).toString().padLeft(2, '0');
    setState(() {
      _percent = _waitTime / 60;
      timeStr = '$minuteStr:$secondStr';
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xff3987c8),
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
                    color: const Color(0xff235d8c),
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
                Positioned(
                    bottom: 0,
                    left: 117,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    )
                )
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
                      heroTag: "btn1",
                      backgroundColor: const Color(0xff418ecd),
                      onPressed: () {
                        isStart ? pause() : start(context);
                      },
                      child: isStart
                          ? const Icon(
                        Icons.pause,
                        size: 80,
                        color: Color(0xff235d8c),
                      )
                          : const Icon(
                        Icons.play_arrow_outlined,
                        size: 80,
                        color: Color(0xff235d8c),
                      )),
                ),
                Container(
                  height: size.height * 0.15,
                  width: size.height * 0.15,
                  margin: const EdgeInsets.all(20),
                  child: FloatingActionButton(
                      heroTag: "btn2",
                      backgroundColor: const Color(0xff418ecd),
                      onPressed: () {
                        restart();
                      },
                      child: const Icon(
                        Icons.restart_alt,
                        size: 80,
                        color: Color(0xff235d8c),
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}