import 'package:cgk/value_union_state_listener.dart';
import 'package:cgk/union_state.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class Training extends StatefulWidget {
  const Training({super.key});

  @override
  State<Training> createState() => _TrainingState();
}

class _TrainingState extends State<Training> {
  final qaState = ValueNotifier<UnionState<List<QA>>>(UnionState$Loading());
  final answered = <QA>[];

  //чтение данных из бд
  Future<List<QA>> readData() async {
    final response = await Supabase.instance.client.from('questions').select();
    if (response is! Object) throw Exception('результат равен null');
    return response
        .safeCast<List<Object?>>()
        .map((e) => e.safeCast<Map<String, Object?>>())
        .map(
          (e) => QA(
            id: e['id'].safeCast<int>(),
            question: e['question'].safeCast<String>(),
            answer: e['answer'].safeCast<String>(),
          ),
        )
        .toList();
  }

  //обновление экрана при разных состояниях
  Future<void> updateScreen() async {
    try {
      qaState.value = UnionState$Loading();
      final data = await readData();
      qaState.value = UnionState$Content(data);
    } on Exception {
      qaState.value = UnionState$Error();
    }
  }

  @override
  void initState() {
    updateScreen();
    super.initState();
  }

  @override
  void dispose() {
    qaState.dispose();
    super.dispose();
  }

  int i = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(200, 29, 82, 117),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(200, 29, 90, 130),
      ),
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
                    child: Text('Обновить'),
                  ),
                ],
              ),
            );
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  Container(
                    height: 130,
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (i != 0) {
                        i--;
                      } else {
                        return;
                      }
                      setState(() {});
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    iconSize: 50,
                    color: Colors.black45,
                  ),
                  Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 300,
                        width: 220,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            color: Colors.black12,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20),
                            ),
                          ),
                          child: InkWell(
                            highlightColor: Colors.black26,
                            splashColor: Colors.black12,
                            //splashColor: Colors.black,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20),
                            ),
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext builder) {
                                  return AlertDialog(
                                    contentPadding: const EdgeInsets.all(24),
                                    content: Text(
                                      content[i].question,
                                      textAlign: TextAlign.center,
                                    ),
                                    backgroundColor: Colors.blueGrey,
                                  );
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(
                                key: ValueKey(i),
                                scrollDirection: Axis.vertical,
                                child: Text(
                                  content[i].question,
                                  style: TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )),
                  IconButton(
                    iconSize: 50,
                    onPressed: () {
                      if (i < content.length - 1) {
                        i++;
                      } else {
                        return;
                      }
                      setState(() {});
                    },
                    icon: Icon(Icons.arrow_forward_ios_rounded),
                    color: Colors.black45,
                  )
                ],
              ),
              Center(
                child: SizedBox(
                  width: 100,
                  height: 40,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.black12),
                      shadowColor: MaterialStateProperty.all(Colors.black12),
                      overlayColor: MaterialStateProperty.all(Colors.black12),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.black),
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
                              content[i].answer,
                              textAlign: TextAlign.center,
                            ),
                            backgroundColor: Colors.blueGrey,
                          );
                        },
                      );
                    },
                    child: Text(
                      'Ответ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    height: 210,
                    width: MediaQuery.of(context).size.width,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 250,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: answered.contains(content[i])
                                  ? null
                                  : () {
                                      answered.add(content[i]);
                                      setState(
                                        () {},
                                      );
                                    },
                              style: ButtonStyle(
                                backgroundColor: answered.contains(content[i])
                                    ? MaterialStateProperty.all(Colors.black45)
                                    : MaterialStateProperty.all(Colors.black12),
                                shadowColor: answered.contains(content[i])
                                    ? MaterialStateProperty.all(Colors.black45)
                                    : MaterialStateProperty.all(Colors.black12),
                                overlayColor:
                                    MaterialStateProperty.all(Colors.black12),
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.black),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Вопрос взят',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
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
          );
        },
        loadingBuilder: () {
          return SafeArea(
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white60,
              ),
            ),
          );
        },
        errorBuilder: () {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ошибка, перезагрузите страницу'),
                ElevatedButton(
                  onPressed: () {
                    updateScreen();
                  },
                  child: Text('Обновить'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
