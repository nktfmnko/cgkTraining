import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

extension TypeCast<T> on T? {
  R safeCast<R>() {
    final value = this;
    if (value is R) return value;
    throw Exception('не удалось привести тип $runtimeType к типу $R');
  }
}

class QA {
  final String question;
  final String answer;

  const QA({
    required this.question,
    required this.answer,
  });
}

class adminChange extends StatefulWidget {
  const adminChange({super.key});

  @override
  State<adminChange> createState() => _adminChangeState();
}

class _adminChangeState extends State<adminChange> {
  final questionsState =
      ValueNotifier<UnionState<List<QA>>>(UnionState$Loading());

  Future<List<QA>> readData() async {
    final response = await Supabase.instance.client.from('questions').select();
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

  Future<void> updateScreen() async {
    try {
      questionsState.value = UnionState$Loading();
      final data = await readData();
      questionsState.value = UnionState$Content(data);
    } on Exception catch (e) {
      questionsState.value = UnionState$Error(e);
    }
  }

  @override
  void initState() {
    updateScreen();
    super.initState();
  }

  @override
  void dispose() {
    questionsState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff4397de),
      body: ValueUnionStateListener(
        unionListenable: questionsState,
        contentBuilder: (content) {
          return SafeArea(
            child: Center(
              child: Column(
                children: [
                  SizedBox(
                    height: 400,
                    width: 400,
                    child: ListView.builder(
                        itemCount: content.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: Colors.black, width: 1.5),
                              ),
                              child: ListTile(
                                title: Text(
                                  '${content[index].question}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        }),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('title'),
                          );
                        },
                      );
                    },
                    child: Text('Добавить вопрос'),
                  )
                ],
              ),
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
