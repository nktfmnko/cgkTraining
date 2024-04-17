import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cgk/login.dart';
import 'package:cgk/menu.dart';
import 'package:cgk/select_questions.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:cgk/union_state.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';

//парсинг к нужному типу
extension TypeCast<T> on T? {
  R safeCast<R>() {
    final value = this;
    if (value is R) return value;
    throw Exception('не удалось привести тип $runtimeType к типу $R');
  }
}

//класс для вопросов и ответов
class QA {
  final int id;
  final String question;
  final String answer;

  const QA({
    required this.id,
    required this.question,
    required this.answer,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QA &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          question == other.question &&
          answer == other.answer;

  @override
  int get hashCode => id.hashCode ^ question.hashCode ^ answer.hashCode;
}

bool timeGame = false;

GlobalKey<_QuestionTimerState> globalKey = GlobalKey();

class Training extends StatefulWidget {
  const Training({super.key});

  @override
  State<Training> createState() => _TrainingState();
}

final answered = <int>[];
int questionIndex = 0;
int last = 1;
double time = 0;

String twoDigits(int n) {
  return n.toString().padLeft(2, '0');
}

Future<void> addValue<T>(T value, String column) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final data = await Supabase.instance.client
        .from('users')
        .select('email, $column')
        .eq('email', '${isLogin ? (prefs?.getString('mail') ?? "") : userEmail}');
    await Supabase.instance.client.from('users').update(
        {'$column': data.last.values.last + value}).eq('email', '${isLogin ? (prefs?.getString('mail') ?? "") : userEmail}');
  } on Exception {
    throw new Exception('Ошибка');
  }
}

class QuestionTimer extends StatefulWidget {
  final VoidCallback notifyParent;
  final List<QA> questions;

  QuestionTimer({Key? key, required this.notifyParent, required this.questions})
      : super(key: key);

  @override
  State<QuestionTimer> createState() => _QuestionTimerState();
}

class _QuestionTimerState extends State<QuestionTimer> {
  Duration duration = Duration(seconds: 60);
  Duration countDownDuration = Duration(seconds: 60);
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void addTime() {
    final addSeconds = -1;
    final seconds = duration.inSeconds + addSeconds;
    if (seconds == 10) {
      vib! ? Vibration.vibrate(duration: 700, amplitude: 128) : null;
    }
    if (seconds < 0) {
      timer?.cancel();
      last++;
      time += countDownDuration.inSeconds;
      if (questionIndex < widget.questions.length - 1) {
        questionIndex++;
      }
      widget.notifyParent();
      reset();
    } else {
      duration = Duration(seconds: seconds);
    }
    setState(() {});
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (_) => addTime());
    sound! ? AudioPlayer().play(AssetSource('startTimer.mp3')) : null;
  }

  void reset() {
    duration = countDownDuration;
    if (last != widget.questions.length + 1) {
      startTimer();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff4397de),
      body: Center(
        child: Text(
          '${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}',
          style: TextStyle(fontSize: 80, color: Colors.white),
        ),
      ),
    );
  }
}

class _TrainingState extends State<Training> with WidgetsBindingObserver{
  final qaState = ValueNotifier<UnionState<List<QA>>>(UnionState$Loading());

  //чтение данных из бд
  Future<List<QA>> readData() async {
    final response = await Supabase.instance.client.from('questions').select();
    return TypeCast(response)
        .safeCast<List<Object?>>()
        .map((e) => TypeCast(e).safeCast<Map<String, Object?>>())
        .map(
          (e) => QA(
            id: TypeCast(e['id']).safeCast<int>(),
            question: TypeCast(e['question']).safeCast<String>(),
            answer: TypeCast(e['answer']).safeCast<String>(),
          ),
        )
        .toList();
  }

  //обновление экрана при разных состояниях
  Future<void> updateScreen() async {
    try {
      qaState.value = UnionState$Loading();
      final data = await readData();
      data.shuffle();
      addValue(selected.toInt(), 'selectedQuestions');
      qaState.value = UnionState$Content(data.take(selected.toInt()).toList());
    } on Exception catch (e) {
      qaState.value = UnionState$Error(e);
    }
  }

  @override
  void initState() {
    updateScreen();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    qaState.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    if(state == AppLifecycleState.paused && timeGame && globalKey.currentState!.timer!.isActive){
      globalKey.currentState!.timer?.cancel();
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) {
          return AlertDialog(
            backgroundColor: Color(0xff4397de),
            content: SizedBox(
              height: 180,
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  SizedBox(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        globalKey.currentState!
                            .startTimer();
                        setState(() {});
                      },
                      child: Text(
                        "Продолжить",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      style: ButtonStyle(
                        backgroundColor:
                        MaterialStatePropertyAll<
                            Color>(
                          Color(0xff3987C8),
                        ),
                        shape:
                        MaterialStateProperty.all<
                            RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(
                              Radius.circular(8),
                            ),
                            side: BorderSide(
                                color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    width: 170,
                    height: 50,
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  SizedBox(
                    child: ElevatedButton(
                      onPressed: () {
                        last = 1;
                        questionIndex = 0;
                        selected = 1;
                        time = 0;
                        answered.clear();
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const menu(),
                            ),
                                (route) => false);
                      },
                      child: Text(
                        "Домой",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      style: ButtonStyle(
                        backgroundColor:
                        MaterialStatePropertyAll<
                            Color>(
                          Color(0xff3987C8),
                        ),
                        shape:
                        MaterialStateProperty.all<
                            RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(
                              Radius.circular(8),
                            ),
                            side: BorderSide(
                                color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    width: 170,
                    height: 50,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff4397de),
      body: ValueUnionStateListener<List<QA>>(
        unionListenable: qaState,
        contentBuilder: (content) {
          if (content.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ошибка, перезагрузите страницу'),
                  ElevatedButton(
                    onPressed: () {
                      updateScreen();
                    },
                    child: const Text('Обновить'),
                  ),
                ],
              ),
            );
          }
          return SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                timeGame
                    ? (last == content.length + 1
                        ? SizedBox.shrink()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {
                                  globalKey.currentState!.timer?.cancel();
                                  showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (_) {
                                      return AlertDialog(
                                        backgroundColor: Color(0xff4397de),
                                        content: SizedBox(
                                          height: 180,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(context, rootNavigator: true).pop();
                                                    globalKey.currentState!
                                                        .startTimer();
                                                    setState(() {});
                                                  },
                                                  child: Text(
                                                    "Продолжить",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        MaterialStatePropertyAll<
                                                            Color>(
                                                      Color(0xff3987C8),
                                                    ),
                                                    shape:
                                                        MaterialStateProperty.all<
                                                            RoundedRectangleBorder>(
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(8),
                                                        ),
                                                        side: BorderSide(
                                                            color: Colors.black),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                width: 170,
                                                height: 50,
                                              ),
                                              SizedBox(
                                                height: 30,
                                              ),
                                              SizedBox(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    last = 1;
                                                    questionIndex = 0;
                                                    selected = 1;
                                                    time = 0;
                                                    answered.clear();
                                                    Navigator.pushAndRemoveUntil(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              const menu(),
                                                        ),
                                                        (route) => false);
                                                  },
                                                  child: Text(
                                                    "Домой",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        MaterialStatePropertyAll<
                                                            Color>(
                                                      Color(0xff3987C8),
                                                    ),
                                                    shape:
                                                        MaterialStateProperty.all<
                                                            RoundedRectangleBorder>(
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(8),
                                                        ),
                                                        side: BorderSide(
                                                            color: Colors.black),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                width: 170,
                                                height: 50,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                  setState(() {});
                                },
                                icon: Icon(
                                  Icons.pause,
                                  size: 55,
                                  color: Colors.white,
                                ),
                              )
                            ],
                          ))
                    : (last == content.length + 1
                        ? SizedBox.shrink()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 9, right: 2),
                                child: SizedBox(
                                  height: 40,
                                  width: 135,
                                  child: ElevatedButton(
                                    style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty.all(
                                        const Color(0xff3987C8),
                                      ),
                                      shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(7),
                                          side: const BorderSide(
                                              color: Colors.black),
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (_) {
                                          return AlertDialog(
                                            title: Text(
                                              'Вы действительно хотите завершить тренировку?',
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            backgroundColor: Color(0xff4397de),
                                            content: SizedBox(
                                              height: 180,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        addValue(answered.length,
                                                            'rightAnswers');
                                                        last = 1;
                                                        questionIndex = 0;
                                                        selected = 1;
                                                        answered.clear();
                                                        Navigator
                                                            .pushAndRemoveUntil(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          const menu(),
                                                                ),
                                                                (route) => false);
                                                      },
                                                      child: Text(
                                                        "Завершить",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      style: ButtonStyle(
                                                        backgroundColor:
                                                            MaterialStatePropertyAll<
                                                                Color>(
                                                          Color(0xff3987C8),
                                                        ),
                                                        shape: MaterialStateProperty
                                                            .all<
                                                                RoundedRectangleBorder>(
                                                          RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.all(
                                                              Radius.circular(8),
                                                            ),
                                                            side: BorderSide(
                                                                color:
                                                                    Colors.black),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    width: 170,
                                                    height: 50,
                                                  ),
                                                  SizedBox(
                                                    height: 30,
                                                  ),
                                                  SizedBox(
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.of(context, rootNavigator: true).pop();
                                                      },
                                                      child: Text(
                                                        "Продолжить",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      style: ButtonStyle(
                                                        backgroundColor:
                                                            MaterialStatePropertyAll<
                                                                Color>(
                                                          Color(0xff3987C8),
                                                        ),
                                                        shape: MaterialStateProperty
                                                            .all<
                                                                RoundedRectangleBorder>(
                                                          RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.all(
                                                              Radius.circular(8),
                                                            ),
                                                            side: BorderSide(
                                                                color:
                                                                    Colors.black),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    width: 170,
                                                    height: 50,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Text(
                                      'Закончить тренировку',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )),
                last == content.length + 1
                    ? SizedBox.shrink()
                    : SizedBox(
                        height: 130,
                        child: timeGame
                            ? QuestionTimer(
                                notifyParent: refresh,
                                questions: content,
                                key: globalKey)
                            : SizedBox.shrink(),
                      ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    timeGame || last == content.length + 1
                        ? SizedBox(
                            width: 60,
                          )
                        : (questionIndex == 0
                            ? SizedBox(
                                width: 66,
                              )
                            : IconButton(
                                onPressed: () {
                                  if (questionIndex != 0) {
                                    questionIndex--;
                                  } else {
                                    return;
                                  }
                                  setState(() {});
                                },
                                icon:
                                    const Icon(Icons.arrow_back_ios_new_rounded),
                                iconSize: 50,
                                color: Colors.black,
                              )),
                    last == content.length + 1
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                              gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: <Color>[
                                    Color(0xff3987C7),
                                    Color(0xff3A83C5),
                                    Color(0xff3C78BD),
                                    Color(0xff4067AF),
                                  ]),
                            ),
                            child: SizedBox(
                              height: 360,
                              width: 270,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20, horizontal: 5),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Всего вопросов: ${content.length}',
                                        style: TextStyle(
                                            fontSize: 25, color: Colors.white),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        'Вопросов взято: ${answered.length}',
                                        style: TextStyle(
                                          fontSize: 25,
                                          color: Colors.white,
                                        ),
                                      ),
                                      timeGame
                                          ? SizedBox(
                                              height: 10,
                                            )
                                          : SizedBox.shrink(),
                                      timeGame
                                          ? Text(
                                              'Общее время: ${time}с',
                                              style: TextStyle(
                                                  fontSize: 25,
                                                  color: Colors.white),
                                            )
                                          : SizedBox.shrink(),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      ElevatedButton(
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all(
                                                  const Color(0xff3987C8)),
                                          shadowColor: MaterialStateProperty.all(
                                              const Color(0xff3987C8)),
                                          overlayColor: MaterialStateProperty.all(
                                              Colors.black12),
                                          shape: MaterialStateProperty.all<
                                              RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              side: const BorderSide(
                                                  color: Colors.black),
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          addValue(
                                              answered.length, 'rightAnswers');
                                          timeGame
                                              ? {
                                                  addValue(time, 'time'),
                                                  addValue(answered.length,
                                                      'timeAnswered')
                                                }
                                              : null;
                                          last = 1;
                                          questionIndex = 0;
                                          selected = 1;
                                          time = 0;
                                          answered.clear();
                                          Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const menu(),
                                              ),
                                              (route) => false);
                                        },
                                        child: Text(
                                          'Домой',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 300,
                              width: 220,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black),
                                  gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: <Color>[
                                        Color(0xff3987C7),
                                        Color(0xff3A83C5),
                                        Color(0xff3C78BD),
                                        Color(0xff4067AF),
                                      ]),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: InkWell(
                                  highlightColor: Colors.black38,
                                  splashColor: Colors.black26,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                  onLongPress: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext builder) {
                                        return AlertDialog(
                                          contentPadding:
                                              const EdgeInsets.all(24),
                                          content: Text(
                                            content[questionIndex].question,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          backgroundColor: Color(0xff4397de),
                                        );
                                      },
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SingleChildScrollView(
                                      key: ValueKey(questionIndex),
                                      scrollDirection: Axis.vertical,
                                      child: Text(
                                        content[questionIndex].question,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    timeGame || last == content.length + 1
                        ? SizedBox(
                            width: 60,
                          )
                        : (questionIndex == content.length - 1
                            ? SizedBox(
                                width: 66,
                              )
                            : IconButton(
                                iconSize: 50,
                                onPressed: () {
                                  if (questionIndex < content.length - 1) {
                                    questionIndex++;
                                  } else {
                                    return;
                                  }
                                  setState(() {});
                                },
                                icon: const Icon(Icons.arrow_forward_ios_rounded),
                                color: Colors.black,
                              ))
                  ],
                ),
                Center(
                  child: last == content.length + 1
                      ? SizedBox.shrink()
                      : SizedBox(
                          width: 100,
                          height: 40,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                  const Color(0xff3987C8)),
                              shadowColor: MaterialStateProperty.all(
                                  const Color(0xff3987C8)),
                              overlayColor:
                                  MaterialStateProperty.all(Colors.black12),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Colors.black),
                                ),
                              ),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    contentPadding: const EdgeInsets.all(24),
                                    content: Text(
                                      content[questionIndex].answer,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Color(0xff4397de),
                                  );
                                },
                              );
                            },
                            child: const Text(
                              'Ответ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                ),
                Row(
                  children: [
                    last == content.length + 1
                        ? SizedBox.shrink()
                        : Container(
                            height: 210,
                            width: MediaQuery.of(context).size.width,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: SizedBox(
                                      width: 250,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: timeGame
                                            ? () {
                                                if (questionIndex !=
                                                    content.length - 1) {
                                                  answered.contains(
                                                          content[questionIndex]
                                                              .id)
                                                      ? null
                                                      : answered.add(
                                                          content[questionIndex]
                                                              .id);
                                                  questionIndex++;
                                                  last++;
                                                  time += globalKey
                                                          .currentState!
                                                          .countDownDuration
                                                          .inSeconds -
                                                      globalKey.currentState!
                                                          .duration.inSeconds;
                                                  globalKey.currentState?.timer
                                                      ?.cancel();
                                                  globalKey.currentState?.reset();
                                                  setState(() {});
                                                } else {
                                                  answered.add(
                                                      content[questionIndex].id);
                                                  globalKey.currentState?.timer
                                                      ?.cancel();
                                                  last++;
                                                  time += globalKey
                                                          .currentState!
                                                          .countDownDuration
                                                          .inSeconds -
                                                      globalKey.currentState!
                                                          .duration.inSeconds;
                                                  setState(
                                                    () {},
                                                  );
                                                }
                                              }
                                            : answered.contains(
                                                    content[questionIndex].id)
                                                ? null
                                                : () {
                                                    answered.add(
                                                        content[questionIndex]
                                                            .id);
                                                    if (questionIndex !=
                                                        content.length - 1) {
                                                      questionIndex++;
                                                    }
                                                    last++;
                                                    setState(
                                                      () {},
                                                    );
                                                  },
                                        style: ButtonStyle(
                                          backgroundColor: answered.contains(
                                                  content[questionIndex].id)
                                              ? MaterialStateProperty.all(
                                                  const Color(0xff235d8c))
                                              : MaterialStateProperty.all(
                                                  const Color(0xff3987C8)),
                                          shadowColor: answered.contains(
                                                  content[questionIndex].id)
                                              ? MaterialStateProperty.all(
                                                  const Color(0xff235d8c))
                                              : MaterialStateProperty.all(
                                                  const Color(0xff3987C8)),
                                          overlayColor: MaterialStateProperty.all(
                                              const Color(0xff235d8c)),
                                          shape: MaterialStateProperty.all<
                                              RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              side: const BorderSide(
                                                  color: Colors.black),
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Вопрос взят',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )
                  ],
                ),
              ],
            ),
          );
        },
        loadingBuilder: () {
          return const SafeArea(
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white60,
              ),
            ),
          );
        },
        errorBuilder: (_) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ошибка, перезагрузите страницу',
                  style: TextStyle(color: Colors.white),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(const Color(0xff3987C8)),
                    shadowColor:
                        MaterialStateProperty.all(const Color(0xff3987C8)),
                  ),
                  onPressed: () {
                    updateScreen();
                  },
                  child: const Text('Обновить',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
