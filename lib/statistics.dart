import 'package:cgk/login.dart';
import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class userStat {
  final int answered;
  final int selected;

  const userStat({required this.answered, required this.selected});
}

class stat extends StatefulWidget {
  const stat({super.key});

  @override
  State<stat> createState() => _statState();
}

class _statState extends State<stat> {
  final statisticState =
      ValueNotifier<UnionState<List<userStat>>>(UnionState$Loading());

  Future<List<userStat>> readStat() async {
    final response = await Supabase.instance.client
        .from('users')
        .select('rightAnswers, selectedQuestions')
        .eq('email', '$userEmail');
    return TypeCast(response)
        .safeCast<List<Object?>>()
        .map((e) => TypeCast(e).safeCast<Map<String, Object?>>())
        .map(
          (e) => userStat(
            answered: TypeCast(e['rightAnswers']).safeCast<int>(),
            selected: TypeCast(e['selectedQuestions']).safeCast<int>(),
          ),
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

  @override
  void initState() {
    updateScreen();
    super.initState();
  }

  @override
  void dispose() {
    statisticState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff3987c8),
      body: SafeArea(
        child: Center(
          child: Column(
            children: <Widget>[
              ValueUnionStateListener<List<userStat>>(
                unionListenable: statisticState,
                contentBuilder: (content) {
                  return Column(
                    children: [
                      const Text(
                        'Статистика:',
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Общее кол-во вопросов: ${content[0].selected}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 25),
                      CircularPercentIndicator(
                        radius: 105.0,
                        lineWidth: 20.0,
                        animation: true,
                        animationDuration: 1000,
                        percent: content[0].answered / content[0].selected,
                        center: Text(
                          '${(content[0].answered / content[0].selected * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: Colors.yellow,
                        backgroundColor: Colors.black,
                      ),
                      const SizedBox(height: 25),
                      Text(
                        'Кол-во взятых вопросов: ${content[0].answered}',
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
              //Таблица лидеров
              SizedBox(
                height: 410,
                width: 400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
