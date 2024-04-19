import 'package:cgk/menu.dart';
import 'package:cgk/message_exception.dart';
import 'package:cgk/statistics.dart';
import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class makeTeam extends StatefulWidget {
  const makeTeam({super.key});

  @override
  State<makeTeam> createState() => _makeTeamState();
}

class _makeTeamState extends State<makeTeam> {
  final teamState = ValueNotifier<UnionState<List<user>>>(UnionState$Loading());
  final isPressState = ValueNotifier<bool>(false);
  final createState = UnionStateNotifier<void>(UnionState$Content(null));
  final teamName = TextEditingController();

  Future<List<user>> readUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await Supabase.instance.client
        .from('users')
        .select('name, rightAnswers, time, timeAnswered, picture')
        .neq('name', 'admin')
        .neq('email', '${prefs.getString("mail")}')
        .eq('team', '');
    return TypeCast(response)
        .safeCast<List<Object?>>()
        .map((e) => TypeCast(e).safeCast<Map<String, Object?>>())
        .map(
          (e) => user(
              name: TypeCast(e['name']).safeCast<String>(),
              answered: TypeCast(e['rightAnswers']).safeCast<int>(),
              time: TypeCast(e['time']).safeCast<int>(),
              timeAnswered: TypeCast(e['timeAnswered']).safeCast<int>(),
              picture: TypeCast(e['picture']).safeCast<String>()),
        )
        .toList();
  }

  late List<bool> _isChecked;

  Future<void> updateTeamList() async {
    try {
      teamState.value = UnionState$Loading();
      final data = await readUsers();
      _isChecked = List<bool>.filled(data.length, false);
      teamState.value = UnionState$Content(data);
    } on Exception catch (e) {
      teamState.value = UnionState$Error(e);
    }
  }

  Future<void> createTeam(List<user> list) async {
    try {
      if (teamName.text.isEmpty) {
        createState.error(MessageException('Поле неверно заполнено'));
        return;
      }
      isPressState.value = !isPressState.value;
      setState(() {});
    } on Exception {
      createState.error(MessageException('Произошла ошибка, повторите'));
      isPressState.value = !isPressState.value;
    }
  }

  @override
  void initState() {
    updateTeamList();
    super.initState();
  }

  @override
  void dispose() {
    teamState.dispose();
    createState.dispose();
    isPressState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff4397de),
      body: ValueUnionStateListener(
        unionListenable: teamState,
        contentBuilder: (content) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      height: 50,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: TextFormField(
                        controller: teamName,
                        keyboardType: TextInputType.text,
                        cursorColor: Colors.white,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.person_outline_outlined,
                            color: Colors.white,
                          ),
                          labelText: 'Название команды',
                          labelStyle: TextStyle(color: Colors.white),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.black, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.black, width: 1.5),
                          ),
                        ),
                      ),
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
                          padding: const EdgeInsets.all(4.5),
                          child: ListView.separated(
                            separatorBuilder: (context, index) {
                              return const Divider(
                                height: 15,
                              );
                            },
                            itemCount: content.length,
                            itemBuilder: (context, index) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: content[index]
                                                .picture
                                                .isEmpty
                                            ? Image.asset(
                                                    "assets/avatar_image.png")
                                                .image
                                            : Image(
                                                image: NetworkImage(
                                                    content[index].picture),
                                              ).image,
                                        backgroundColor: Colors.black,
                                        radius: 16,
                                      ),
                                      SizedBox(
                                        width: 7,
                                      ),
                                      SizedBox(
                                        child: Text(
                                          content[index].name,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Checkbox(
                                    value: _isChecked[index],
                                    onChanged: (bool? value) {
                                      _isChecked[index] = value!;
                                      setState(() {});
                                    },
                                  )
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 10,
                        child: ValueUnionStateListener(
                          unionListenable: createState,
                          contentBuilder: (_) {
                            return ElevatedButton(
                              onPressed: isPressState.value
                                  ? null
                                  : () => createTeam(content),
                              child: ValueListenableBuilder<bool>(
                                valueListenable: isPressState,
                                builder: (_, isPress, __) {
                                  return isPress
                                      ? CircularProgressIndicator()
                                      : Text(
                                          'Создать команду',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18),
                                        );
                                },
                              ),
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStatePropertyAll<Color>(
                                  Color(0xff1b588c),
                                ),
                              ),
                            );
                          },
                          loadingBuilder: () {
                            return ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStatePropertyAll<Color>(
                                  Color(0xff1b588c),
                                ),
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
                              onPressed: isPressState.value
                                  ? null
                                  : () => createTeam(content),
                              child: ValueListenableBuilder<bool>(
                                valueListenable: isPressState,
                                builder: (_, isPress, __) {
                                  return isPress
                                      ? CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          exception.toString(),
                                          style: TextStyle(color: Colors.white),
                                        );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
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
                      updateTeamList();
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
