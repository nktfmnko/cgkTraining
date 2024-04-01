import 'dart:io';

import 'package:cgk/changeQuestions.dart';
import 'package:cgk/login.dart';
import 'package:cgk/select_questions.dart';
import 'package:cgk/timer.dart';
import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cgk/statistics.dart';


extension TypeCast<T> on T? {
  R safeCast<R>() {
    final value = this;
    if (value is R) return value;
    throw Exception('не удалось привести тип $runtimeType к типу $R');
  }
}

class userWithPic {
  final String name;
  final int answered;
  final int time;
  final String picture;
  final bool admin;

  const userWithPic(
      {required this.name,
      required this.answered,
      required this.time,
      required this.picture,
      required this.admin});
}

class menu extends StatefulWidget {
  const menu({Key? key}) : super(key: key);

  @override
  _menu createState() => _menu();
}

class _menu extends State<menu> {
  final menuState =
      ValueNotifier<UnionState<userWithPic>>(UnionState$Loading());

  Future<userWithPic> readUser() async {
    final response = await Supabase.instance.client
        .from('users')
        .select('name, rightAnswers, time, picture, admin')
        .eq('email', '$userEmail');
    final data = TypeCast(response)
        .safeCast<List<Object?>>()
        .map((e) => TypeCast(e).safeCast<Map<String, Object?>>())
        .map(
          (e) => userWithPic(
            name: TypeCast(e['name']).safeCast<String>(),
            answered: TypeCast(e['rightAnswers']).safeCast<int>(),
            time: TypeCast(e['time']).safeCast<int>(),
            picture: TypeCast(e['picture']).safeCast<String>(),
            admin: TypeCast(e['admin']).safeCast<bool>(),
          ),
        )
        .toList();
    return userWithPic(
        name: data.last.name,
        answered: data.last.answered,
        time: data.last.time,
        picture: data.last.picture,
        admin: data.last.admin);
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
      body: ValueUnionStateListener<userWithPic>(
        unionListenable: menuState,
        loadingBuilder: () {
          return SafeArea(
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                    SizedBox(
                        width: width * 1 / 3,
                        height: width * 1 / 3,
                        // Inkwell
                        child: InkWell(
                          radius: 100,
                          // display a snackbar on tap
                          onTap: () => showDialog<String>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                                content: new SizedBox(
                                    height: height * 22 / 100,
                                    width: width / 5,
                                    child: Column(
                                      children: [
                                        Row(children: [
                                          SizedBox(
                                              width: 100,
                                              height: 100,
                                              child: InkWell(
                                                radius: 50,
                                                // изменение картинки профиля
                                                onTap: () async {
                                              final ImagePicker picker = ImagePicker();

                                              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                              //if (image != null)

                                              File file = File(image!.path);



                                              },
                                                child: Ink.image(
                                                  fit: BoxFit.cover,
                                                  image: const NetworkImage(
                                                      'https://www.kindacode.com/wp-content/uploads/2022/07/bottle.jpeg'),
                                                ),
                                              )),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          SizedBox(
                                            height: 100,
                                            width: 120,
                                            child: Align(
                                                alignment: Alignment.center,
                                                child: Text("Имя Фамилия",
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 26))),
                                          ),
                                        ]),
                                        Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Взятых вопросов:',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 20))),
                                        Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Среднее время:',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 20))),
                                      ],
                                    )),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, 'Готово'),
                                    child: const Text('Готово',
                                        style: TextStyle(fontSize: 20)),
                                  ),
                                ]),
                          ),
                        )),
                    Text(
                      "${content.name}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
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
                      color: Colors.white,
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
                      color: Colors.white,
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
                      color: Colors.white,
                      fontSize: 30,
                    ),
                  ),
                ),
                SizedBox(height: 1 / 20 * height),
                content.admin
                    ? Column(
                        children: <Widget>[
                          ElevatedButton(
                            style: ButtonStyle(
                              fixedSize: MaterialStateProperty.all(
                                  Size(8 / 9 * width, 1 / 12 * height)),
                              backgroundColor: MaterialStateProperty.all(
                                  Color.fromRGBO(57, 135, 200, 1)),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                      width: 1.5, color: Colors.black),
                                ),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => adminChange(),
                                ),
                              );
                            },
                            child: Text(
                              'Добавить вопрос',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                              ),
                            ),
                          ),
                          SizedBox(height: 1 / 20 * height),
                        ],
                      )
                    : SizedBox.shrink(),
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
                                      color: Colors.white,
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
                                      color: Colors.white,
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
                                color: Colors.white,
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
                      color: Colors.white,
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
