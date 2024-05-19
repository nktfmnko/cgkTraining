import 'dart:convert';

import 'package:cgk/makeTeam.dart';
import 'package:cgk/menu.dart';
import 'package:cgk/message_exception.dart';
import 'package:cgk/statistics.dart';
import 'package:cgk/type_cast.dart';
import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class TeamScore {
  final String name;
  final int score;
  final String photo;

  const TeamScore(
      {required this.name, required this.score, required this.photo});
}

class SendInvite extends StatefulWidget {
  const SendInvite({super.key});

  @override
  State<SendInvite> createState() => _SendInviteState();
}

class _SendInviteState extends State<SendInvite> {
  late List<bool> _isChecked;
  final teamState = ValueNotifier<UnionState<List<user>>>(UnionState$Loading());
  final isPressState = ValueNotifier<bool>(false);
  final createState = UnionStateNotifier<void>(UnionState$Content(null));

  Future<List<user>> readUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final response = await Supabase.instance.client
        .from('users')
        .select('name, rightAnswers, time, timeAnswered, picture, email')
        .neq('name', 'admin')
        .neq('email', '${prefs.getString("mail")}')
        .eq('team_id', 0);
    return response
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

  Future<void> sendInvites(List<user> list, String code, String team) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    for (int i = 0; i <= list.length - 1; i++) {
      if (_isChecked[i]) {
        await http.post(
          url,
          headers: {
            'origin': 'http://localhost',
            'Content-Type': 'application/json',
          },
          body: json.encode(
            {
              'service_id': 'service_23bd6wb',
              'template_id': 'template_8hairan',
              'user_id': 'RK2JAm99g7P7VusxQ',
              'template_params': {
                'to_email': list[i].email,
                'message': 'Код вступления в команду ${team} : ${code}',
              }
            },
          ),
        );
      }
    }
  }

  Future<void> addMembers(List<user> list) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      isPressState.value = !isPressState.value;
      setState(() {});
      final code = await Supabase.instance.client
          .from('teams')
          .select('team_name, code')
          .eq('capitan', '${prefs.getString('mail')}');
      sendInvites(list, code.last.values.last, code.last.values.first);
      isPressState.value = !isPressState.value;
      Navigator.pop(context);
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
  Widget build(BuildContext context) {
    return ValueUnionStateListener(
      unionListenable: teamState,
      contentBuilder: (content) {
        return Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.07,
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.width,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: content[index].picture.isEmpty
                                    ? Image.asset("assets/avatar_image.png")
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
                                      color: Colors.white, fontSize: 18),
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
            ValueUnionStateListener(
              unionListenable: createState,
              contentBuilder: (_) {
                return ElevatedButton(
                  onPressed:
                      isPressState.value ? null : () => addMembers(content),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isPressState,
                    builder: (_, isPress, __) {
                      return isPress
                          ? CircularProgressIndicator()
                          : Text(
                              'Пригласить',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            );
                    },
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll<Color>(
                      Color(0xff1b588c),
                    ),
                  ),
                );
              },
              loadingBuilder: () {
                return ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll<Color>(
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
                        MaterialStatePropertyAll<Color>(Color(0xff1b588c)),
                  ),
                  onPressed:
                      isPressState.value ? null : () => addMembers(content),
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
            )
          ],
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
    );
  }
}

class TeamsLeaderboard extends StatefulWidget {
  const TeamsLeaderboard({super.key});

  @override
  State<TeamsLeaderboard> createState() => _TeamsLeaderboardState();
}

class _TeamsLeaderboardState extends State<TeamsLeaderboard> {
  final teamsState =
      ValueNotifier<UnionState<List<TeamScore>>>(UnionState$Loading());

  Future<List<TeamScore>> readTeams() async {
    final response =
        await Supabase.instance.client.rpc<List<Object?>>('teams_leaderboard');
    return response
        .map((e) => e.safeCast<Map<String, Object?>>())
        .map(
          (e) => TeamScore(
            name: e['team_name'].safeCast<String>(),
            score: e['total_points'].safeCast<int>(),
            photo: e['photo'].safeCast<String>(),
          ),
        )
        .toList();
  }

  Future<void> updateScreen() async {
    try {
      teamsState.value = UnionState$Loading();
      final data = await readTeams();
      teamsState.value = UnionState$Content(data);
    } on Exception catch (e) {
      teamsState.value = UnionState$Error(e);
    }
  }

  @override
  void initState() {
    updateScreen();
    super.initState();
  }

  @override
  void dispose() {
    teamsState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueUnionStateListener(
          unionListenable: teamsState,
          contentBuilder: (content) {
            return Column(
              children: [
                Text(
                  'Рейтинг команд',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 15,
                    ),
                    const Text(
                      "Ранг",
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    const Spacer(),
                    const Text(
                      "Имя",
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    const Spacer(),
                    const Text(
                      "Очки",
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    SizedBox(
                      width: 15,
                    ),
                  ],
                ),
                const Divider(),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 2.7,
                  child: ListView.separated(
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
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.06,
                            child: content[index].photo.isEmpty
                                ? Image.asset("assets/teamIcon.png")
                                : Image(
                                    fit: BoxFit.cover,
                                    image: NetworkImage(content[index].photo),
                                  ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.61,
                            child: Text(
                              content[index].name,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.15,
                            child: Center(
                              child: Text(
                                content[index].score.toString(),
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
                        indent: 10,
                        endIndent: 10,
                      );
                    },
                    itemCount: content.length,
                  ),
                )
              ],
            );
          },
          loadingBuilder: () {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                    height: MediaQuery.of(context).size.height / 2.7,
                  ),
                ],
              ),
            );
          },
          errorBuilder: (_) {
            return SizedBox(
              height: MediaQuery.of(context).size.height / 2.7,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
              ),
            );
          },
        ),
      ],
    );
  }
}

class HaveTeamScreen extends StatefulWidget {
  const HaveTeamScreen({super.key});

  @override
  State<HaveTeamScreen> createState() => _HaveTeamScreenState();
}

class _HaveTeamScreenState extends State<HaveTeamScreen> {
  final teamState = ValueNotifier<UnionState<List<user>>>(UnionState$Loading());

  late String teamName;
  late String capitan;
  late SharedPreferences prefs;
  late String photo;

  Future<List<user>> readUsers() async {
    final name = await Supabase.instance.client
        .from('teams')
        .select('team_name, capitan')
        .eq('id', haveTeam);

    teamName = name.last.values.first;
    capitan = name.last.values.last;
    photo = (await Supabase.instance.client
            .from('teams')
            .select('photo')
            .eq('id', haveTeam))
        .last
        .values
        .first;

    final response = await Supabase.instance.client
        .from('users')
        .select('name, rightAnswers, time, timeAnswered, picture, email')
        .eq('team_id', haveTeam);
    prefs = await SharedPreferences.getInstance();
    return response
        .safeCast<List<Object?>>()
        .map((e) => TypeCast(e).safeCast<Map<String, Object?>>())
        .map(
          (e) => user(
              email: e['email'].safeCast<String>(),
              name: e['name'].safeCast<String>(),
              answered: e['rightAnswers'].safeCast<int>(),
              time: e['time'].safeCast<int>(),
              timeAnswered: e['timeAnswered'].safeCast<int>(),
              picture: e['picture'].safeCast<String>()),
        )
        .toList();
  }

  Future<void> updateScreen() async {
    try {
      teamState.value = UnionState$Loading();
      final data = await readUsers();
      teamState.value = UnionState$Content(data);
    } on Exception catch (e) {
      teamState.value = UnionState$Error(e);
    }
  }

  Future<void> deleteMember(String memberMail) async {
    await Supabase.instance.client
        .from('users')
        .update({'team_id': 0}).eq('email', memberMail);
    Navigator.pop(context);
    Navigator.pop(context);
    updateScreen();
  }

  Future<void> teamLeave(String newCapitan) async {
    await Supabase.instance.client
        .from('users')
        .update({'team_id': 0}).eq('email', '${prefs.getString('mail')}');
    if (capitan == prefs.getString('mail')) {
      final checkEmptyTeam = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('team_id', haveTeam);
      if (checkEmptyTeam.isNotEmpty) {
        await Supabase.instance.client
            .from('teams')
            .update({'capitan': newCapitan}).eq('team_name', teamName);
      } else {
        await Supabase.instance.client
            .from('teams')
            .delete()
            .match({'id': haveTeam});
      }
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const menu()),
      (route) => false,
    );
  }

  @override
  void initState() {
    updateScreen();
    super.initState();
  }

  @override
  void dispose() {
    teamState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          ValueUnionStateListener<List<user>>(
            unionListenable: teamState,
            contentBuilder: (content) {
              content.sort((p1, p2) => p2.answered.compareTo(p1.answered));
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      prefs.getString('mail') == capitan
                          ? SizedBox(
                              width: 28,
                              height: 28,
                              child: IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        contentPadding: EdgeInsets.zero,
                                        insetPadding: EdgeInsets.only(
                                            bottom: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.1,
                                            top: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.1,
                                            left: 20,
                                            right: 20),
                                        backgroundColor: Color(0xff4397de),
                                        content: SendInvite(),
                                      );
                                    },
                                  );
                                },
                                icon: Icon(Icons.add),
                                iconSize: 28,
                                padding: EdgeInsets.all(0.0),
                                color: Colors.black,
                              ),
                            )
                          : SizedBox(
                              width: 28,
                            ),
                      Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.1,
                            child: photo.isEmpty
                                ? Image.asset("assets/teamIcon.png")
                                : Image(
                                    fit: BoxFit.cover,
                                    image: NetworkImage(photo),
                                  ),
                          ),
                          Text(
                            '${teamName}',
                            style: TextStyle(color: Colors.white, fontSize: 25),
                          ),
                        ],
                      ),
                      SizedBox(
                        child: IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext builder) {
                                return AlertDialog(
                                  backgroundColor: Color(0xff4397de),
                                  title: Text(
                                    'Вы действительно хотите покинуть команду?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          teamLeave(content.length == 1
                                              ? ''
                                              : content[1].email);
                                        },
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
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          icon: Icon(
                            Icons.exit_to_app,
                            color: Colors.white70,
                            size: 28,
                          ),
                          padding: EdgeInsets.all(0.0),
                        ),
                        height: 28,
                        width: 28,
                      )
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 15,
                      ),
                      const Text(
                        "Ранг",
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                      const Spacer(),
                      const Text(
                        "Имя",
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                      const Spacer(),
                      const Text(
                        "Очки",
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                      SizedBox(
                        width: 15,
                      ),
                    ],
                  ),
                  const Divider(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 2.7,
                    child: ListView.separated(
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Color(0xff4397de),
                                  content: SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.27,
                                    width:
                                        MediaQuery.of(context).size.width / 5,
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 100,
                                              height: 100,
                                              child: content[index]
                                                      .picture
                                                      .isEmpty
                                                  ? Image.asset(
                                                      "assets/avatar_image.png")
                                                  : Image(
                                                      fit: BoxFit.cover,
                                                      image: NetworkImage(
                                                          content[index]
                                                              .picture),
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
                                                      content[index].name,
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
                                            'Взятых вопросов: ${content[index].answered}',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Среднее время: ${content[index].timeAnswered == 0 ? 0 : (content[index].time / content[index].timeAnswered).toStringAsFixed(1)}',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20),
                                          ),
                                        ),
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.02,
                                        ),
                                        prefs.getString('mail') == capitan &&
                                                content[index].email != capitan
                                            ? Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: TextButton(
                                                  onPressed: () {
                                                    showDialog(
                                                      barrierDismissible: false,
                                                      context: context,
                                                      builder: (BuildContext
                                                          builder) {
                                                        return AlertDialog(
                                                          backgroundColor:
                                                              Color(0xff4397de),
                                                          title: Text(
                                                            'Вы уверены, что хотите удалить ${content[index].name}?',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                          content: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  deleteMember(
                                                                      content[index]
                                                                          .email);
                                                                },
                                                                child: Text(
                                                                  'Да',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ),
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child: Text(
                                                                  'Нет',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                  child: Text(
                                                    'Удалить игрока',
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xffb13318),
                                                        fontSize: 15),
                                                  ),
                                                ),
                                              )
                                            : SizedBox.shrink()
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Row(
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
                                backgroundImage: content[index].picture.isEmpty
                                    ? Image.asset("assets/avatar_image.png")
                                        .image
                                    : Image(
                                            image: NetworkImage(
                                                content[index].picture))
                                        .image,
                                backgroundColor: Colors.black,
                                radius: 12,
                              ),
                              SizedBox(
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
                                    content[index].answered.toString(),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 17),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const Divider(
                          height: 10,
                          indent: 10,
                          endIndent: 10,
                        );
                      },
                      itemCount: content.length,
                    ),
                  )
                ],
              );
            },
            loadingBuilder: () {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                      height: MediaQuery.of(context).size.height / 2.7,
                    ),
                  ],
                ),
              );
            },
            errorBuilder: (_) {
              return SizedBox(
                height: MediaQuery.of(context).size.height / 2.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
          TeamsLeaderboard()
        ],
      ),
    );
  }
}

class TeamCode extends StatefulWidget {
  const TeamCode({super.key});

  @override
  State<TeamCode> createState() => _TeamCodeState();
}

class _TeamCodeState extends State<TeamCode> {
  final codeController = TextEditingController();
  final codeState = UnionStateNotifier<void>(UnionState$Content(null));
  final pressJoin = ValueNotifier<bool>(false);

  Future<void> checkCode() async {
    try {
      if (codeController.text.isEmpty) {
        codeState.error(MessageException('Поле неверно заполнено'));
        return;
      }
      pressJoin.value = !pressJoin.value;
      setState(() {});
      final team = await Supabase.instance.client
          .from('teams')
          .select('id, code')
          .eq('code', '${codeController.text}');
      if (team.isEmpty) {
        codeState.error(MessageException('Неверно введен код'));
        pressJoin.value = !pressJoin.value;
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await Supabase.instance.client
          .from('users')
          .update({'team_id': team.last.values.first}).eq(
              'email', '${prefs.getString('mail') ?? ""}');

      pressJoin.value = !pressJoin.value;
      codeState.value = UnionState$Content(null);
      codeController.text = "";
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const menu()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Вы присоединились к команде!'),
        ),
      );
    } on Exception {
      codeState.error(MessageException('Произошла ошибка, повторите'));
      pressJoin.value = !pressJoin.value;
    }
  }

  @override
  void dispose() {
    codeState.dispose();
    pressJoin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.19,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          TextFormField(
            cursorColor: Colors.white,
            style: TextStyle(color: Colors.white),
            controller: codeController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: 'Код',
              labelStyle: TextStyle(color: Colors.white),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.035,
          ),
          ValueUnionStateListener(
            unionListenable: codeState,
            contentBuilder: (_) {
              return ElevatedButton(
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStatePropertyAll<Color>(Color(0xff1b588c)),
                ),
                onPressed: pressJoin.value ? null : checkCode,
                child: ValueListenableBuilder<bool>(
                  valueListenable: pressJoin,
                  builder: (_, isPress, __) {
                    return isPress
                        ? CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            'Присоединиться',
                            style: TextStyle(color: Colors.white, fontSize: 17),
                          );
                  },
                ),
              );
            },
            loadingBuilder: () {
              return ElevatedButton(
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
                      MaterialStatePropertyAll<Color>(Color(0xff1b588c)),
                ),
                onPressed: pressJoin.value ? null : checkCode,
                child: ValueListenableBuilder<bool>(
                  valueListenable: pressJoin,
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
          )
        ],
      ),
    );
  }
}

class Team extends StatefulWidget {
  const Team({super.key});

  @override
  State<Team> createState() => _TeamState();
}

class _TeamState extends State<Team> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff4397de),
      body: SafeArea(
        child: haveTeam == 0
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'У вас еще нет команды',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const makeTeam(),
                          ),
                        );
                      },
                      child: Text(
                        'Создать команду',
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          const Color(0xff1b588c),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Color(0xff4397de),
                              title: Text(
                                'Введите код',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: TeamCode(),
                            );
                          },
                        );
                      },
                      child: Text(
                        'Присоединиться по коду',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              )
            : HaveTeamScreen(),
      ),
    );
  }
}
