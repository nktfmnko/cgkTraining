import 'dart:io';

import 'package:cgk/login.dart';
import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class User {
  final int id;
  final String name;
  final String mail;
  final String password;

  const User({
    required this.id,
    required this.name,
    required this.mail,
    required this.password,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          mail == other.mail &&
          password == other.password;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ mail.hashCode ^ password.hashCode;
}

bool seePassword = true;
bool isPress = false;
List<User> users = <User>[];

bool hasEmail(List<String> u, String s) {
  for (var value in u) {
    if (value == s) return true;
  }
  return false;
}

bool correctFields(String mail, String password, String user) {
  return !mail.isEmpty &&
      !password.isEmpty &&
      !user.isEmpty &&
      EmailValidator.validate(mail) &&
      validatePassword(password) == null;
}

String? validatePassword(String value) {
  RegExp regex =
      RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#$&*~+]).{8,}$');
  if (value.isEmpty) {
    return 'Введите пароль';
  } else {
    if (!regex.hasMatch(value)) {
      return 'Пароль должен содержать '
          '\n1.минимум 8 символов '
          '\n2.латинские буквы в верхнем и нижнем регистре '
          '\n3.цифры '
          '\n4.специальные символы(!@#\$&*~+)';
    } else {
      return null;
    }
  }
}

extension TypeCast<T> on T? {
  R safeCast<R>() {
    final value = this;
    if (value is R) return value;
    throw Exception('не удалось привести тип $runtimeType к типу $R');
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final mailState =
      ValueNotifier<UnionState<List<String>>>(UnionState$Loading());

  final nameController = TextEditingController();
  final mailController = TextEditingController();
  final passwordController = TextEditingController();
  final supabase = Supabase.instance.client;

  Future<void> insertUser(User user) async {
    await supabase.from('users').insert(
        {'name': user.name, 'email': user.mail, 'password': user.password});
  }

  Future<List<String>> readMails() async {
    final response =
        await Supabase.instance.client.from('users').select('email');
    if (response is! Object) throw Exception('результат равен null');
    return response
        .safeCast<List<Object?>>()
        .map((e) => e.safeCast<Map<String, Object?>>())
        .map(
          (e) => e['email'].safeCast<String>(),
        )
        .toList();
  }

  Future<void> updateButton() async {
    try {
      mailState.value = UnionState$Loading();
      final data = await readMails();
      data.shuffle();
      mailState.value = UnionState$Content(data);
    } on Exception {
      mailState.value = UnionState$Error();
    }
  }

  @override
  void dispose() {
    mailState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  height: 100,
                ),
                Form(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        onChanged: (String value) async {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          label: Text('Имя Фамилия'),
                          prefixIcon: Icon(Icons.person_outline_outlined),
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 2,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        controller: mailController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (input) =>
                            EmailValidator.validate(mailController.text)
                                ? null
                                : 'Введите корректную почту',
                        onChanged: (String value) async {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          label: Text('Почта'),
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 2,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        obscureText: seePassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (input) =>
                            validatePassword(passwordController.text),
                        controller: passwordController,
                        onChanged: (String value) async {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          label: Text('Пароль'),
                          prefixIcon: Icon(Icons.password_outlined),
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 2,
                              color: Colors.black,
                            ),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              seePassword
                                  ? seePassword = false
                                  : seePassword = true;
                              setState(
                                () {},
                              );
                            },
                            icon: Icon(Icons.remove_red_eye_sharp),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: !isPress
                            ? ElevatedButton(
                                onPressed: correctFields(
                                        mailController.text,
                                        passwordController.text,
                                        nameController.text)
                                    ? () {
                                        isPress = !isPress;
                                        updateButton();
                                        setState(() {});
                                      }
                                    : null,
                                child: Text('Зарегистрироваться'),
                              )
                            : ValueUnionStateListener<List<String>>(
                                unionListenable: mailState,
                                loadingBuilder: () {
                                  return ElevatedButton(
                                    onPressed: null,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  );
                                },
                                contentBuilder: (content) {
                                  hasEmail(content, mailController.text) ||
                                          !correctFields(
                                              mailController.text,
                                              passwordController.text,
                                              nameController.text)
                                      ? null
                                      : insertUser(
                                          new User(
                                              id: 0,
                                              name: nameController.text,
                                              mail: mailController.text,
                                              password:
                                                  passwordController.text),
                                        );
                                  return ElevatedButton(
                                    onPressed: () {
                                      updateButton();
                                    },
                                    child: Text(
                                        'Пользователь с такой почтой уже есть'),
                                  );
                                },
                                errorBuilder: () {
                                  return ElevatedButton(
                                    onPressed: () {
                                      updateButton();
                                    },
                                    child: Text('Ошибка, обновите страницу'),
                                  );
                                },
                              ),
                      )
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    isPress ? isPress = false : null;
                    Navigator.pop(context);
                  },
                  child: Text.rich(
                    TextSpan(
                      text: 'Уже есть аккаунт? ',
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Войти',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
