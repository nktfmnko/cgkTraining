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
  final String question;
  final String answer;

  const QA({required this.question, required this.answer});
}

class Training extends StatefulWidget {
  const Training({super.key});

  @override
  State<Training> createState() => _TrainingState();
}

class _TrainingState extends State<Training> {
  final qaState = ValueNotifier<UnionState<List<QA>>>(UnionState$Loading());

  //чтение данных из бд
  Future<List<QA>> readData() async {
    final response =
        await Supabase.instance.client.from('QA').select('question, answer');
    if (response is! Object) throw Exception('результат равен null');
    return response
        .safeCast<List<Object?>>()
        .map((e) => e.safeCast<Map<String, Object?>>())
        .map(
          (e) => QA(
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
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(200, 29, 90, 130),
      ),
      body: ValueUnionStateListener<List<QA>>(
          unionListenable: qaState,
          contentBuilder: (content) {
            return Scaffold(
              backgroundColor: const Color.fromARGB(200, 29, 82, 117),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    // mainAxisSize: MainAxisSize.min,
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
                      ),
                      Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 200,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(2)),
                              ),
                              child: SingleChildScrollView(
                                key: ValueKey(i),
                                scrollDirection: Axis.vertical,
                                child: Text(content[i].question),
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
                          icon: Icon(Icons.arrow_forward_ios_rounded))
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 45,
                        child: ElevatedButton(
                            onPressed: () {}, child: Text('Вопрос взят')),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loadingBuilder: () {gi
            return SafeArea(
                child: Scaffold(
              backgroundColor: const Color.fromARGB(200, 29, 82, 117),
              body: Center(
                child: CircularProgressIndicator(
                  color: Colors.white60,
                ),
              ),
            ));
          },
          errorBuilder: () {
            return Scaffold(
              backgroundColor: const Color.fromARGB(200, 29, 82, 117),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ошибка, перезагрузите страницу'),
                    ElevatedButton(
                        onPressed: () {
                          updateScreen();
                        },
                        child: Text('Обновить'))
                  ],
                ),
              ),
            );
          }),
    );
  }
}
