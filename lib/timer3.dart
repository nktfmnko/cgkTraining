import 'dart:async';
import 'package:cgk/menu.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StateTimer3Page extends StatefulWidget {
  const StateTimer3Page({Key? key}) : super(key: key);

  @override
  _StateTimer3PageState createState() => _StateTimer3PageState();
}

// Класс Таймера
class _StateTimer3PageState extends State<StateTimer3Page> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin<StateTimer3Page> {
  Timer? _timer;
  late int _waitTime;
  var _percent = 1.0;
  var isStart = false;
  var timeStr = '05:00';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _waitTime = 60;
    _calculateTime();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
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
          sound! ? AudioPlayer().play(AssetSource('startTimer.mp3')) : null;
          pause();
        } else if (_waitTime == 20) {
          sound! ? AudioPlayer().play(AssetSource('startTimer.mp3')) : null;
          pause();
        } else if (_waitTime == 40) {
          sound! ? AudioPlayer().play(AssetSource('startTimer.mp3')) : null;
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) pause();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                Container(
                  height: size.height * 0.34,
                  width: size.height * 0.315,
                  alignment: Alignment.topCenter,
                  child: SvgPicture.asset(
                    'assets/Group 5.svg',
                    alignment: Alignment.topCenter,
                    width: size.width * 0.315,
                    height: size.height * 0.34,
                  ),
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
                      heroTag: "btn5",
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
                      heroTag: "btn6",
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
