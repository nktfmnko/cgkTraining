import 'dart:io';
import 'package:cgk/changeQuestions.dart';
import 'package:cgk/login.dart';
import 'package:cgk/main.dart';
import 'package:cgk/team.dart';
import 'package:cgk/select_questions.dart';
import 'package:cgk/timer.dart';
import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cgk/statistics.dart';

extension TypeCast<T> on T? {
  R safeCast<R>() {
    final value = this;
    if (value is R) return value;
    throw Exception('не удалось привести тип $runtimeType к типу $R');
  }
}

late int haveTeam;

//Звук
bool? sound = true;

//Вибрация
bool? vib = true;

class userWithPic {
  final String name;
  final int answered;
  final int time;
  final String picture;
  final bool admin;
  final int time_answered;
  final int team_id;

  const userWithPic({
    required this.name,
    required this.answered,
    required this.time,
    required this.picture,
    required this.admin,
    required this.time_answered,
    required this.team_id,
  });
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await Supabase.instance.client
        .from('users')
        .select(
            'name, rightAnswers, time, picture, admin, timeAnswered, team_id')
        .eq('email',
            '${isLogin ? (prefs?.getString('mail') ?? "") : userEmail}');
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
              time_answered: TypeCast(e['timeAnswered']).safeCast<int>(),
              team_id: TypeCast(e['team_id']).safeCast<int>()),
        )
        .toList();
    haveTeam = data.last.team_id;
    return userWithPic(
      name: data.last.name,
      answered: data.last.answered,
      time: data.last.time,
      picture: data.last.picture,
      admin: data.last.admin,
      time_answered: data.last.time_answered,
      team_id: data.last.team_id,
    );
  }

  Future<void> exit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove("isLogin");
    prefs.remove("mail");
    prefs.remove('sound');
    prefs.remove('vibration');
    isLogin = false;
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const MyApp(),
        ),
        (route) => false);
  }

  Future<void> soundSettings(bool s) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('sound', s);
  }

  Future<void> vibrationSettings(bool v) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('vibration', v);
  }

  Future<void> updateScreen() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      vib = prefs.getBool('vibration') == null
          ? true
          : prefs.getBool('vibration');
      sound = prefs.getBool('sound') == null ? true : prefs.getBool('sound');
      menuState.value = UnionState$Loading();
      final data = await readUser();
      menuState.value = UnionState$Content(data);
    } on Exception catch (e) {
      menuState.value = UnionState$Error(e);
    }
  }

  Future<void> takePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      File file = File(image?.path ?? '');
      await Supabase.instance.client.storage
          .from('pictures')
          .upload(image?.path ?? '', file);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await Supabase.instance.client.from('users').update({
        'picture':
            '${await Supabase.instance.client.storage.from('pictures').getPublicUrl('${image?.path}')}'
      }).eq(
          'email', '${isLogin ? (prefs?.getString('mail') ?? "") : userEmail}');
      updateScreen();
    } on Exception catch (e) {
      throw new Exception(e);
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
              ),
            ),
          );
        },
        contentBuilder: (content) {
          return SafeArea(
            child: RefreshIndicator(
              color: Colors.blueGrey,
              onRefresh: () async {
                await Future.delayed(
                  Duration(seconds: 1),
                );
                return updateScreen();
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: Column(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          color: Colors.white70,
                          icon: Icon(
                            Icons.exit_to_app,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Color(0xff4397de),
                                  title: Text(
                                    'Вы уверены, что хотите выйти?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: exit,
                                        child: Text(
                                          'Да',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          'Нет',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(width: width / 20),
                          //вместо иконки
                          SizedBox(
                            width: width * 1 / 3,
                            height: width * 1 / 3,
                            // Inkwell
                            child: InkWell(
                              radius: 100,
                              // display a snackbar on tap
                              onTap: () => showDialog<String>(
                                barrierDismissible: false,
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  backgroundColor: Color(0xff4397de),
                                  content: new SizedBox(
                                    height: height * 22 / 100,
                                    width: width / 5,
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 100,
                                              height: 100,
                                              child: InkWell(
                                                radius: 50,
                                                // изменение картинки профиля
                                                onTap: () => takePicture(),
                                                child: content.picture.isEmpty
                                                    ? Image.asset(
                                                        "assets/avatar_image.png")
                                                    : Image(
                                                        fit: BoxFit.cover,
                                                        image: NetworkImage(
                                                            content.picture),
                                                      ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            SizedBox(
                                              height: 100,
                                              width: 120,
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: SizedBox(
                                                    width: 240,
                                                    child: Text(
                                                      content.name,
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 26),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Взятых вопросов: ${content.answered}',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Среднее время: ${content.time_answered == 0 ? 0 : (content.time / content.time_answered).toStringAsFixed(1)}',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, 'Готово'),
                                      child: const Text('Готово',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20)),
                                    ),
                                  ],
                                ),
                              ),
                              // implement the image with Ink.image
                              child: content.picture.isEmpty
                                  ? Image.asset("assets/avatar_image.png")
                                  : Image(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(content.picture),
                                    ),
                            ),
                          ),
                          SizedBox(width: width / 20),
                          SizedBox(
                            width: width * 32 / 60,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: width * 40 / 60,
                                child: Text(
                                  "${content.name}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: width * 2 / 60)
                        ],
                      ),
                      SizedBox(height: height / 40),
                      ElevatedButton(
                        style: ButtonStyle(
                          fixedSize: MaterialStateProperty.all(
                            Size(8 / 9 * width, 1 / 12 * height),
                          ),
                          backgroundColor: MaterialStateProperty.all(
                              Color.fromRGBO(57, 135, 200, 1)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
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
                              builder: (context) => SelectQuestion(),
                            ),
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
                            Size(8 / 9 * width, 1 / 12 * height),
                          ),
                          backgroundColor: MaterialStateProperty.all(
                            Color.fromRGBO(57, 135, 200, 1),
                          ),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
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
                              builder: (context) => stat(),
                            ),
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
                            Size(8 / 9 * width, 1 / 12 * height),
                          ),
                          backgroundColor: MaterialStateProperty.all(
                            Color.fromRGBO(57, 135, 200, 1),
                          ),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
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
                              builder: (context) => StateTimerPage(),
                            ),
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
                                      Size(8 / 9 * width, 1 / 12 * height),
                                    ),
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
                          : (content.admin
                              ? SizedBox.shrink()
                              : Column(
                                  children: [
                                    ElevatedButton(
                                      style: ButtonStyle(
                                        fixedSize: MaterialStateProperty.all(
                                          Size(8 / 9 * width, 1 / 12 * height),
                                        ),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                          Color.fromRGBO(57, 135, 200, 1),
                                        ),
                                        shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            side: const BorderSide(
                                                width: 1.5,
                                                color: Colors.black),
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Team(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Команда',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 1 / 20 * height),
                                  ],
                                )),
                      ElevatedButton(
                        style: ButtonStyle(
                          fixedSize: MaterialStateProperty.all(
                            Size(8 / 9 * width, 1 / 12 * height),
                          ),
                          backgroundColor: MaterialStateProperty.all(
                            Color.fromRGBO(57, 135, 200, 1),
                          ),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                  width: 1.5, color: Colors.black),
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
                                side:
                                    BorderSide(width: 1.5, color: Colors.black),
                              ),
                              content: SizedBox(
                                width: 3 / 4 * width,
                                height: 1 / 7 * height,
                                child: Column(
                                  children: [
                                    StatefulBuilder(builder:
                                        (BuildContext context,
                                            StateSetter setState) {
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
                                            soundSettings(newBool!);
                                          });
                                        },
                                      );
                                    }),
                                    StatefulBuilder(builder:
                                        (BuildContext context,
                                            StateSetter setState) {
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
                                            vibrationSettings(newBool!);
                                          });
                                        },
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, 'Назад'),
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
                      SizedBox(
                        height: 1 / 20 * height,
                      )
                    ],
                  ),
                ),
              ),
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
                      backgroundColor: MaterialStateProperty.all(
                        const Color(0xff3987C8),
                      ),
                      shadowColor: MaterialStateProperty.all(
                        const Color(0xff3987C8),
                      ),
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
