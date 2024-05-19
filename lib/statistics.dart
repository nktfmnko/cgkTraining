import 'package:cgk/login.dart';
import 'package:cgk/type_cast.dart';
import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class userStat {
  final int answered;
  final int selected;

  const userStat({required this.answered, required this.selected});
}

class user {
  final String name;
  final int answered;
  final int time;
  final int timeAnswered;
  final String picture;
  final String email;

  const user(
      {required this.name,
      required this.answered,
      required this.time,
      required this.timeAnswered,
      required this.picture,
      required this.email});
}

class stat extends StatefulWidget {
  const stat({super.key});

  @override
  State<stat> createState() => _statState();
}

class _statState extends State<stat> {
  final statisticState =
      ValueNotifier<UnionState<userStat>>(UnionState$Loading());
  final boardState =
      ValueNotifier<UnionState<List<user>>>(UnionState$Loading());

  Future<userStat> readStat() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await Supabase.instance.client
        .from('users')
        .select('rightAnswers, selectedQuestions')
        .eq('email',
            '${isLogin ? (prefs.getString('mail') ?? "") : userEmail}');
    final data = response
        .safeCast<List<Object?>>()
        .map((e) => e.safeCast<Map<String, Object?>>())
        .map(
          (e) => userStat(
            answered: e['rightAnswers'].safeCast<int>(),
            selected: e['selectedQuestions'].safeCast<int>(),
          ),
        )
        .toList();
    return userStat(answered: data.last.answered, selected: data.last.selected);
  }

  Future<List<user>> readUsers() async {
    final response = await Supabase.instance.client
        .from('users')
        .select('name, rightAnswers, time, timeAnswered, picture, email')
        .neq('rightAnswers', 0);
    return TypeCast(response)
        .safeCast<List<Object?>>()
        .map((e) => TypeCast(e).safeCast<Map<String, Object?>>())
        .map(
          (e) => user(
              email: TypeCast(e['email']).safeCast<String>(),
              name: TypeCast(e['name']).safeCast<String>(),
              answered: TypeCast(e['rightAnswers']).safeCast<int>(),
              time: TypeCast(e['time']).safeCast<int>(),
              timeAnswered: TypeCast(e['timeAnswered']).safeCast<int>(),
              picture: TypeCast(e['picture']).safeCast<String>()),
        )
        .toList();
  }

  Future<void> updateScreen() async {
    try {
      statisticState.value = UnionState$Loading();
      final data = await readStat();
      statisticState.value = UnionState$Content(data);
    } on Exception catch (e) {
      statisticState.value = UnionState$Error(e);
    }
  }

  Future<void> updateBoard() async {
    try {
      boardState.value = UnionState$Loading();
      final data = await readUsers();
      boardState.value = UnionState$Content(data);
    } on Exception catch (e) {
      boardState.value = UnionState$Error(e);
    }
  }

  @override
  void initState() {
    updateScreen();
    updateBoard();
    super.initState();
  }

  @override
  void dispose() {
    statisticState.dispose();
    boardState.dispose();
    super.dispose();
  }

  String value = "POINT";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff3987c8),
      body: SafeArea(
        child: Center(
          child: Column(
            children: <Widget>[
              SizedBox(
                height: MediaQuery.of(context).size.height / 2.5,
                child: ValueUnionStateListener<userStat>(
                  unionListenable: statisticState,
                  contentBuilder: (content) {
                    return Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.005,
                        ),
                        Text(
                          'Общее кол-во вопросов: ${content.selected}',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.025),
                        CircularPercentIndicator(
                          radius: 105.0,
                          lineWidth: 20.0,
                          animation: true,
                          animationDuration: 1000,
                          percent: content.selected == 0
                              ? 0
                              : content.answered / content.selected,
                          center: Text(
                            content.selected == 0
                                ? '0%'
                                : '${(content.answered / content.selected * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                            ),
                          ),
                          circularStrokeCap: CircularStrokeCap.round,
                          progressColor: Colors.yellow,
                          backgroundColor: Colors.black,
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.025),
                        Text(
                          'Кол-во взятых вопросов: ${content.answered}',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
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
                                backgroundColor: MaterialStateProperty.all(
                                    const Color(0xff3987C8)),
                                shadowColor: MaterialStateProperty.all(
                                    const Color(0xff3987C8)),
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
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.001,
              ),
              //Таблица лидеров
              SizedBox(
                height: MediaQuery.of(context).size.height / 1.87,
                width: double.infinity,
                child: ValueUnionStateListener<List<user>>(
                  unionListenable: boardState,
                  contentBuilder: (content) {
                    if (value == "TIME") {
                      content.sort((p1, p2) => (p1.time / p1.timeAnswered)
                          .compareTo(p2.time / p2.timeAnswered));
                    } else {
                      content
                          .sort((p1, p2) => p2.answered.compareTo(p1.answered));
                    }
                    return Scaffold(
                      backgroundColor: const Color(0xff3987C8),
                      appBar: AppBar(
                        leadingWidth: 0,
                        leading: Text(""),
                        backgroundColor: const Color(0xff3987C8),
                        toolbarHeight: 90,
                        title: Column(
                          children: [
                            const SizedBox(
                              height: 5,
                            ),
                            const Text("Таблица лидеров",
                                style: TextStyle(color: Colors.white)),
                            Row(children: [
                              const Text("Ранг",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 17)),
                              const Spacer(),
                              const Text("Имя",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 17)),
                              const Spacer(),
                              DropdownButton<String>(
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 17),
                                dropdownColor: Color(0xff3987C8),
                                value: value,
                                icon: const Icon(Icons.arrow_drop_down_rounded),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    value = newValue!;
                                  });
                                },
                                items: const [
                                  DropdownMenuItem<String>(
                                      value: "TIME", child: Text("Время")),
                                  DropdownMenuItem<String>(
                                      value: "POINT", child: Text("Очки"))
                                ],
                              ),
                            ]),
                            const Divider()
                          ],
                        ),
                      ),
                      body: SafeArea(
                        child: ListView.separated(
                          itemCount: content.length,
                          itemBuilder: (context, index) {
                            return Row(
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.17,
                                  child: Center(
                                    child: Text(
                                      (index + 1).toString(),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 17),
                                    ),
                                  ),
                                ),
                                CircleAvatar(
                                  backgroundImage: content[index]
                                          .picture
                                          .isEmpty
                                      ? Image.asset("assets/avatar_image.png")
                                          .image
                                      : Image(
                                              image: NetworkImage(
                                                  content[index].picture))
                                          .image,
                                  backgroundColor: Colors.black,
                                  radius: 12,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.6,
                                  child: Text(
                                    content[index].name,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 15),
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.1,
                                  child: Center(
                                    child: Text(
                                      value == "POINT"
                                          ? content[index].answered.toString()
                                          : content[index].timeAnswered == 0
                                              ? "0"
                                              : (content[index].time /
                                                      content[index]
                                                          .timeAnswered)
                                                  .toStringAsFixed(1),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 17),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                          separatorBuilder: (context, index) {
                            return const Divider(
                              height: 10,
                              indent: 15,
                              endIndent: 15,
                            );
                          },
                        ),
                      ),
                    );
                  },
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
                                backgroundColor: MaterialStateProperty.all(
                                    const Color(0xff3987C8)),
                                shadowColor: MaterialStateProperty.all(
                                    const Color(0xff3987C8)),
                              ),
                              onPressed: () {
                                updateBoard();
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
