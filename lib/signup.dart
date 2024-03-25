import 'dart:io';

import 'package:cgk/login.dart';
import 'package:cgk/message_exception.dart';
import 'package:cgk/select_questions.dart';
import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final registerState = UnionStateNotifier<void>(UnionState$Content(null));
  final obscureTextState = ValueNotifier<bool>(true);

  final nameController = TextEditingController();
  final mailController = TextEditingController();
  final passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  
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

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    await supabase
        .from('users')
        .insert({'name': name, 'email': email, 'password': password});
  }

  Future<List<String>> readMails() async {
    final response = await supabase.from('users').select('email');
    return response
        .safeCast<List<Object?>>()
        .map((e) => e.safeCast<Map<String, Object?>>())
        .map(
          (e) => e['email'].safeCast<String>(),
        )
        .toList();
  }

  Future<void> authorize() async {
    try {
      final isFieldsValid = correctFields(
          mailController.text, passwordController.text, nameController.text);
      if (!isFieldsValid) {
        registerState.error(MessageException('Поля неверно заполнены'));
        return;
      }
      final mailsList = await readMails();
      if (mailsList.contains(mailController.text)) {
        registerState.error(MessageException('Пользователь с такой почтой уже существует'));
        return;
      }

      await createUser(
          name: nameController.text,
          email: mailController.text,
          password: passwordController.text);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SelectQuestion()),
        (route) => false,
      );
    } on Exception {
      registerState.error(MessageException('Произошла ошибка, повторите'));
    }
  }

  @override
  void dispose() {
    registerState.dispose();
    obscureTextState.dispose();
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
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
                    ValueListenableBuilder<bool>(
                      valueListenable: obscureTextState,
                      builder: (_, obscureText, __) {
                        return TextFormField(
                          obscureText: obscureText,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (input) =>
                              validatePassword(passwordController.text),
                          controller: passwordController,
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
                                obscureTextState.value =
                                    !obscureTextState.value;
                              },
                              icon: Icon(Icons.remove_red_eye_sharp),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ValueUnionStateListener<void>(
                        unionListenable: registerState,
                        contentBuilder: (_) {
                          return ElevatedButton(
                            onPressed: authorize,
                            child: Text('Зарегистрироваться'),
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
                            onPressed: authorize,
                            child: Text(exception.toString()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
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
