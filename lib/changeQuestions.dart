import 'package:cgk/message_exception.dart';
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
  final addQuestionState = UnionStateNotifier<void>(UnionState$Content(null));
  final deleteQuestionState =
      UnionStateNotifier<void>(UnionState$Content(null));
  final isPressAddState = ValueNotifier<bool>(false);
  final isPressDeleteState = ValueNotifier<bool>(false);
  final questionController = TextEditingController();
  final answerController = TextEditingController();

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

  bool correctFields(String question, String answer) {
    return question.isNotEmpty && answer.isNotEmpty;
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

  Future<void> addQuestion(List<QA> q) async {
    try {
      final isFieldsValid =
          correctFields(questionController.text, answerController.text);
      if (!isFieldsValid) {
        addQuestionState.error(MessageException('Поля неверно заполнены'));
        return;
      }
      isPressAddState.value = !isPressAddState.value;
      setState(() {});
      if (q.any((element) => element.question == questionController.text)) {
        addQuestionState.error(MessageException('Такой вопрос уже есть'));
        isPressAddState.value = !isPressAddState.value;
        return;
      }
      await Supabase.instance.client.from('questions').insert({
        'question': questionController.text,
        'answer': answerController.text
      });
      isPressAddState.value = !isPressAddState.value;
      addQuestionState.value = UnionState$Content(null);
      questionController.text = "";
      answerController.text = "";
      updateScreen();
      Navigator.pop(context);
    } on Exception {
      addQuestionState.error(MessageException('Произошла ошибка, повторите'));
      isPressAddState.value = !isPressAddState.value;
    }
  }

  Future<void> deleteQuestion(String question, List<QA> list, int index) async {
    try {
      isPressDeleteState.value = !isPressDeleteState.value;
      await Supabase.instance.client.from('questions').delete().match(
        {'question': '${question}'},
      );
      deleteQuestionState.value = UnionState$Content(null);
      isPressDeleteState.value = !isPressDeleteState.value;
      list.removeAt(index);
      setState(() {});
      Navigator.pop(context, true);
    } on Exception {
      deleteQuestionState
          .error(MessageException('Произошла ошибка, повторите'));
      isPressDeleteState.value = !isPressDeleteState.value;
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
    addQuestionState.dispose();
    deleteQuestionState.dispose();
    isPressAddState.dispose();
    isPressDeleteState.dispose();
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
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 7,
                    ),
                    SizedBox(
                      height: 450,
                      width: MediaQuery.of(context).size.width - 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(width: 1.5, color: Colors.black),
                          borderRadius: BorderRadius.all(
                            Radius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: ListView.builder(
                              itemCount: content.length,
                              itemBuilder: (context, index) {
                                return Dismissible(
                                  key: UniqueKey(),
                                  direction: DismissDirection.endToStart,
                                  background: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: const ColoredBox(
                                      color: Colors.red,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  confirmDismiss:
                                      (DismissDirection direction) async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: Color(0xff4397de),
                                          title: const Text(
                                            'Вы уверены, что хотите удалить?',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          actions: [
                                            ValueUnionStateListener(
                                                unionListenable:
                                                    deleteQuestionState,
                                                contentBuilder: (_) {
                                                  return TextButton(
                                                    onPressed: () {
                                                      deleteQuestion(
                                                          content[index]
                                                              .question,
                                                          content,
                                                          index);
                                                    },
                                                    child:
                                                        ValueListenableBuilder<
                                                            bool>(
                                                      valueListenable:
                                                          isPressDeleteState,
                                                      builder:
                                                          (_, isPress, __) {
                                                        return isPress
                                                            ? CircularProgressIndicator(
                                                                color: Colors
                                                                    .white,
                                                              )
                                                            : Text(
                                                                'Да',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              );
                                                      },
                                                    ),
                                                  );
                                                },
                                                loadingBuilder: () {
                                                  return TextButton(
                                                    onPressed: null,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (exception) {
                                                  return TextButton(
                                                    onPressed: () {
                                                      deleteQuestion(
                                                          content[index]
                                                              .question,
                                                          content,
                                                          index);
                                                    },
                                                    child:
                                                        ValueListenableBuilder<
                                                            bool>(
                                                      valueListenable:
                                                          isPressDeleteState,
                                                      builder:
                                                          (_, isPress, __) {
                                                        return isPress
                                                            ? CircularProgressIndicator(
                                                                color: Colors
                                                                    .white,
                                                              )
                                                            : Text(
                                                                exception
                                                                    .toString(),
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              );
                                                      },
                                                    ),
                                                  );
                                                }),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context, false);
                                              },
                                              child: const Text(
                                                'Нет',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ).then((val) {
                                      deleteQuestionState.value =
                                          UnionState$Content(null);
                                    });
                                    return confirmed;
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.black, width: 1.5),
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
                                                contentPadding:
                                                    const EdgeInsets.all(24),
                                                content: SingleChildScrollView(
                                                  child: Text(
                                                    '${content[index].question} \n\n Ответ: ${content[index].answer}',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                                backgroundColor:
                                                    Color(0xff4397de),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              }),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          const Color(0xff3987C8),
                        ),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                            side: const BorderSide(color: Colors.black),
                          ),
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: const Color(0xff4397de),
                              title: Column(
                                children: [
                                  TextFormField(
                                    maxLines: 3,
                                    cursorColor: Colors.white,
                                    style: TextStyle(color: Colors.white),
                                    controller: questionController,
                                    keyboardType: TextInputType.text,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'Вопрос',
                                      labelStyle:
                                          TextStyle(color: Colors.white),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.black, width: 1.5),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.black, width: 1.5),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 15,
                                  ),
                                  TextFormField(
                                    maxLines: 3,
                                    cursorColor: Colors.white,
                                    style: TextStyle(color: Colors.white),
                                    controller: answerController,
                                    keyboardType: TextInputType.text,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'Ответ',
                                      labelStyle:
                                          TextStyle(color: Colors.white),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.black, width: 1.5),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.black, width: 1.5),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 15,
                                  ),
                                  ValueUnionStateListener(
                                    unionListenable: addQuestionState,
                                    contentBuilder: (_) {
                                      return ElevatedButton(
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all(
                                            const Color(0xff3987C8),
                                          ),
                                          shape: MaterialStateProperty.all<
                                              RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                              side: const BorderSide(
                                                  color: Colors.black),
                                            ),
                                          ),
                                        ),
                                        onPressed: isPressAddState.value
                                            ? null
                                            : () => addQuestion(content),
                                        child: ValueListenableBuilder<bool>(
                                          valueListenable: isPressAddState,
                                          builder: (_, isPress, __) {
                                            return isPress
                                                ? CircularProgressIndicator(
                                                    color: Colors.white,
                                                  )
                                                : Text(
                                                    'Добавить',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  );
                                          },
                                        ),
                                      );
                                    },
                                    loadingBuilder: () {
                                      return ElevatedButton(
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStatePropertyAll<Color>(
                                                  Color(0xff1b588c)),
                                        ),
                                        onPressed: null,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                    errorBuilder: (exception) {
                                      return ElevatedButton(
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStatePropertyAll<Color>(
                                                  Color(0xff1b588c)),
                                        ),
                                        onPressed: isPressAddState.value
                                            ? null
                                            : () => addQuestion(content),
                                        child: ValueListenableBuilder<bool>(
                                          valueListenable: isPressAddState,
                                          builder: (_, isPress, __) {
                                            return isPress
                                                ? CircularProgressIndicator(
                                                    color: Colors.white,
                                                  )
                                                : Text(
                                                    exception.toString(),
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  );
                                          },
                                        ),
                                      );
                                    },
                                  )
                                ],
                              ),
                            );
                          },
                        ).then((value) {
                          addQuestionState.value = UnionState$Content(null);
                        });
                      },
                      child: Text(
                        'Добавить вопрос',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
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
