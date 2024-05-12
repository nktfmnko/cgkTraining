import 'package:cgk/qa.dart';
import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

double selected = 1;

class ListQuestions extends StatefulWidget {
  const ListQuestions({super.key});

  @override
  State<ListQuestions> createState() => _ListQuestionsState();
}

class _ListQuestionsState extends State<ListQuestions> {
  final questionsState =
      ValueNotifier<UnionState<List<QA>>>(UnionState$Loading());

  Future<List<QA>> readData() async {
    final response = await Supabase.instance.client.from('questions').select();
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
    return ValueUnionStateListener(
      unionListenable: questionsState,
      contentBuilder: (content) {
        return SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: ListView.builder(
                    itemCount: content.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(1.5),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(width: 1.3, color: Colors.black),
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              '${content[index].question}',
                              style: TextStyle(color: Colors.white),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext builder) {
                                  return AlertDialog(
                                    contentPadding: const EdgeInsets.all(24),
                                    content: SingleChildScrollView(
                                      child: Text(
                                        '${content[index].question} \n\n Ответ: ${content[index].answer}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    backgroundColor: Color(0xff4397de),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loadingBuilder: () {
        return Center(
          child: CircularProgressIndicator(
            color: Colors.white60,
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
    );
  }
}

class SelectQuestion extends StatefulWidget {
  const SelectQuestion({super.key});

  @override
  State<SelectQuestion> createState() => _SelectQuestionState();
}

class _SelectQuestionState extends State<SelectQuestion> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff4397de),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Выберите количество вопросов:',
              style: TextStyle(fontSize: 22, color: Colors.white),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.015,
            ),
            Slider(
              activeColor: Colors.black,
              value: selected,
              max: 10,
              min: 1,
              label: selected.round().toString(),
              divisions: 9,
              onChanged: (double value) {
                setState(
                  () {
                    selected = value;
                  },
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Игра со временем:",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    checkColor: Colors.black,
                    activeColor: Colors.black26,
                    side: BorderSide(color: Colors.black, width: 1.5),
                    value: timeGame,
                    onChanged: (bool? value) {
                      setState(
                        () {
                          timeGame = value!;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.015,
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
              width: MediaQuery.of(context).size.width * 0.32,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(const Color(0xff1b588c)),
                  shadowColor:
                      MaterialStateProperty.all(const Color(0xff418ecd)),
                  overlayColor: MaterialStateProperty.all(Colors.black12),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        color: Colors.black,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Training(),
                    ),
                    (route) => true,
                  );
                },
                child: Text(
                  "Начать",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.015,
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      insetPadding: EdgeInsets.all(5),
                      backgroundColor: const Color(0xff4397de),
                      content: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: ListQuestions(),
                      ),
                    );
                  },
                );
              },
              child: Text(
                'Показать cписок вопросов',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
