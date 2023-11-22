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
                children: [
                  Text(content[0].question),
                ],
              ),
            );
          },
          loadingBuilder: () {
            return SafeArea(
                child: Scaffold(
                  backgroundColor: Color.fromARGB(200, 29, 82, 117),
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white60,
                    ),
                  ),
                ));
          },
          errorBuilder: () {
            return Scaffold(
              backgroundColor: Color.fromARGB(200, 29, 82, 117),
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
