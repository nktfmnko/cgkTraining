import 'package:cgk/login.dart';
import 'package:cgk/select_questions.dart';
import 'package:cgk/timer.dart';
import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cgk/statistics.dart';

class menu extends StatefulWidget {
  const menu({Key? key}) : super(key: key);

  @override
  _menu createState() => _menu();
}

class _menu extends State<menu> {
  final menuState = ValueNotifier<UnionState<user>>(UnionState$Loading());

  Future<user> readUser() async {
    final response = await Supabase.instance.client
        .from('users')
        .select('name, rightAnswers, time')
        .eq('email', '$userEmail');
    final data = response
        .safeCast<List<Object?>>()
        .map((e) => e.safeCast<Map<String, Object?>>())
        .map(
          (e) => user(
            name: e['name'].safeCast<String>(),
            answered: e['rightAnswers'].safeCast<int>(),
            time: e['time'].safeCast<int>(),
          ),
        )
        .toList();
    return user(name: data.last.name, answered: data.last.answered, time: data.last.time);
  }

  Future<void> updateScreen() async {
    try {
      menuState.value = UnionState$Loading();
      final data = await readUser();
      menuState.value = UnionState$Content(data);
    } on Exception catch (e) {
      menuState.value = UnionState$Error(e);
    }
  }

  @override
  void initState() {
    updateScreen();
    super.initState();
  }

  @override
  void dispose() {
    menuState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    //Звук
    bool? sound = true;
    //Вибрация
    bool? vib = true;
    return Scaffold(
      backgroundColor: const Color(0xff4397de),
      body: ValueUnionStateListener<user>(
        unionListenable: menuState,
        loadingBuilder: () {
          return const SafeArea(
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 125,
                ),
                CircularProgressIndicator(
                  color: Colors.white,
                )
              ],
            )),
          );
        },
        contentBuilder: (content) {
          return Center(
            child: Column(
              children: <Widget>[
                Row(
                  children: [
                    //вместо иконки
                    SizedBox(width: 180, height: 200),
                    Text(
                      "${content.name}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    fixedSize: MaterialStateProperty.all(
                        Size(8 / 9 * width, 1 / 12 * height)),
                    backgroundColor: MaterialStateProperty.all(
                        Color.fromRGBO(57, 135, 200, 1)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(width: 1.5, color: Colors.black),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SelectQuestion()),
                    );
                  },
                  child: Text(
                    'Играть',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                    ),
                  ),
                ),
                SizedBox(height: 1 / 20 * height),
                ElevatedButton(
                  style: ButtonStyle(
                    fixedSize: MaterialStateProperty.all(
                        Size(8 / 9 * width, 1 / 12 * height)),
                    backgroundColor: MaterialStateProperty.all(
                        Color.fromRGBO(57, 135, 200, 1)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(width: 1.5, color: Colors.black),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => stat()),
                    );
                  },
                  child: Text(
                    'Статистика',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                    ),
                  ),
                ),
                SizedBox(height: 1 / 20 * height),
                ElevatedButton(
                  style: ButtonStyle(
                    fixedSize: MaterialStateProperty.all(
                        Size(8 / 9 * width, 1 / 12 * height)),
                    backgroundColor: MaterialStateProperty.all(
                        Color.fromRGBO(57, 135, 200, 1)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(width: 1.5, color: Colors.black),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StateTimerPage()),
                    );
                  },
                  child: Text(
                    'Таймер',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                    ),
                  ),
                ),
                SizedBox(height: 1 / 20 * height),
                ElevatedButton(
                  style: ButtonStyle(
                    fixedSize: MaterialStateProperty.all(
                        Size(8 / 9 * width, 1 / 12 * height)),
                    backgroundColor: MaterialStateProperty.all(
                        Color.fromRGBO(57, 135, 200, 1)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(width: 1.5, color: Colors.black),
                      ),
                    ),
                  ),
                  onPressed: () {
                    showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        backgroundColor: Color(0xff4397de),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(width: 1.5, color: Colors.black)),
                        content: SizedBox(
                          width: 3 / 4 * width,
                          height: 1 / 7 * height,
                          child: Column(
                            children: [
                              StatefulBuilder(builder:
                                  (BuildContext context, StateSetter setState) {
                                return CheckboxListTile(
                                  checkColor: Colors.white,
                                  activeColor: Colors.black,
                                  side: BorderSide(
                                      width: 1.5, color: Colors.black),
                                  title: Text(
                                    'Звук',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 27,
                                    ),
                                  ),
                                  value: sound,
                                  onChanged: (newBool) {
                                    setState(() {
                                      sound = newBool;
                                    });
                                  },
                                );
                              }),
                              StatefulBuilder(builder:
                                  (BuildContext context, StateSetter setState) {
                                return CheckboxListTile(
                                  checkColor: Colors.white,
                                  activeColor: Colors.black,
                                  side: BorderSide(
                                      width: 1.5, color: Colors.black),
                                  title: Text(
                                    'Вибрация',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 27,
                                    ),
                                  ),
                                  value: vib,
                                  onChanged: (newBool) {
                                    setState(() {
                                      vib = newBool;
                                    });
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'Назад'),
                            child: Text(
                              'Назад',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: width / height * 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    'Настройки',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        errorBuilder: (_) {
          return SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 125,
                  ),
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
            ),
          );
        },
      ),
    );
  }
}
