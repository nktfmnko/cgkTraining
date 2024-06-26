import 'dart:convert';
import 'dart:io';
import 'package:cgk/menu.dart';
import 'package:cgk/message_exception.dart';
import 'package:cgk/statistics.dart';
import 'package:cgk/type_cast.dart';
import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

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
  File? _selectedImage;

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

  Future<void> createTeam(List<user> list) async {
    try {
      if (teamName.text.isEmpty) {
        createState.error(MessageException('Поле неверно заполнено'));
        return;
      }

      isPressState.value = !isPressState.value;
      setState(() {});
      final response = await Supabase.instance.client
          .from('teams')
          .select()
          .eq('team_name', teamName.text);
      if (response.isNotEmpty) {
        createState.error(
          MessageException('Команда с таким названием уже есть'),
        );
        isPressState.value = !isPressState.value;
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();

      final randomUuid = const Uuid().v4();
      final encodedUuid = base64Encode(randomUuid.codeUnits);

      await Supabase.instance.client.from('teams').insert({
        'team_name': teamName.text,
        'capitan': '${prefs.getString('mail') ?? ""}',
        'code': encodedUuid
      });

      Future.delayed(Duration(seconds: 1));

      final teamId = await Supabase.instance.client
          .from('teams')
          .select('id')
          .eq('team_name', teamName.text);

      await Supabase.instance.client
          .from('users')
          .update({'team_id': teamId.last.values.last}).eq(
              'email', '${prefs.getString('mail') ?? ""}');

      if (_selectedImage != null) {
        await Supabase.instance.client.storage
            .from('pictures')
            .upload(_selectedImage?.path ?? '', _selectedImage!);
        await Supabase.instance.client.from('teams').update({
          'photo':
              '${await Supabase.instance.client.storage.from('pictures').getPublicUrl('${_selectedImage?.path}')}'
        }).eq('id', teamId.last.values.last);
      }

      sendInvites(list, encodedUuid, teamName.text);
      isPressState.value = !isPressState.value;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const menu()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Команда создана!'),
        ),
      );
    } on Exception {
      createState.error(MessageException('Произошла ошибка, повторите'));
      isPressState.value = !isPressState.value;
    }
  }

  Future<void> takeTeamPicture() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      setState(() {
        _selectedImage = File(image!.path);
      });
    } on Exception catch (e) {
      throw new Exception(e);
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
                      height: MediaQuery.of(context).size.height * 0.055,
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.35,
                            height: MediaQuery.of(context).size.width * 0.35,
                            child: InkWell(
                              onTap: () {
                                takeTeamPicture();
                              },
                              child: _selectedImage != null
                                  ? Image.file(_selectedImage!)
                                  : Image.asset('assets/teamIcon.png'),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
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
                                  borderSide: BorderSide(
                                      color: Colors.black, width: 1.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.black, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
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
