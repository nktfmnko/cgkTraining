import 'package:cgk/login.dart';
import 'package:cgk/menu.dart';
import 'package:cgk/message_exception.dart';
import 'package:cgk/type_cast.dart';
import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final registerState = UnionStateNotifier<void>(UnionState$Content(null));
  final obscureTextState = ValueNotifier<bool>(true);
  final isPressState = ValueNotifier<bool>(false);
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
        .map((e) => e['email'].safeCast<String>())
        .toList();
  }

  Future<void> authorize() async {
    try {
      setState(() {});
      final isFieldsValid = correctFields(
          mailController.text, passwordController.text, nameController.text);
      if (!isFieldsValid) {
        registerState.error(MessageException('Поля неверно заполнены'));
        return;
      }
      isPressState.value = !isPressState.value;
      final mailsList = await readMails();
      if (mailsList.contains(mailController.text)) {
        registerState
            .error(MessageException('Такой пользователь уже существует'));
        isPressState.value = !isPressState.value;
        return;
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("mail", mailController.text);
      prefs.setBool("isLogin", true);
      await createUser(
          name: nameController.text,
          email: mailController.text,
          password: passwordController.text);
      userEmail = mailController.text;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const menu()),
        (route) => false,
      );
    } on Exception {
      registerState.error(MessageException('Произошла ошибка, повторите'));
      isPressState.value = !isPressState.value;
    }
  }

  @override
  void dispose() {
    registerState.dispose();
    obscureTextState.dispose();
    isPressState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff4397de),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height / 5,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      cursorColor: Colors.white,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      controller: nameController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.person_outline_outlined,
                          color: Colors.white,
                        ),
                        label: Text('Имя Фамилия'),
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 2,
                            color: Colors.black,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.025,
                    ),
                    TextFormField(
                      cursorColor: Colors.white,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      controller: mailController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (input) =>
                          EmailValidator.validate(mailController.text)
                              ? null
                              : 'Введите корректную почту',
                      decoration: InputDecoration(
                        label: Text('Почта'),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.white,
                        ),
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            width: 1.5,
                            color: Colors.black,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.025,
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: obscureTextState,
                      builder: (_, obscureText, __) {
                        return TextFormField(
                          cursorColor: Colors.white,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                          obscureText: obscureText,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (input) =>
                              validatePassword(passwordController.text),
                          controller: passwordController,
                          decoration: InputDecoration(
                            label: Text('Пароль'),
                            prefixIcon: Icon(
                              Icons.password_outlined,
                              color: Colors.white,
                            ),
                            border: OutlineInputBorder(),
                            labelStyle: TextStyle(color: Colors.white),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 1.5,
                                color: Colors.black,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.black, width: 1.5),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                obscureTextState.value =
                                    !obscureTextState.value;
                              },
                              icon: Icon(
                                Icons.remove_red_eye_sharp,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.025,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.05,
                      width: double.infinity,
                      child: ValueUnionStateListener<void>(
                        unionListenable: registerState,
                        contentBuilder: (_) {
                          return ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStatePropertyAll<Color>(
                                  Color(0xff1b588c)),
                            ),
                            onPressed: isPressState.value ? null : authorize,
                            child: ValueListenableBuilder<bool>(
                              valueListenable: isPressState,
                              builder: (_, isPress, __) {
                                return isPress
                                    ? CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        'Зарегистрироваться',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 17),
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
                              backgroundColor: MaterialStatePropertyAll<Color>(
                                  Color(0xff1b588c)),
                            ),
                            onPressed: isPressState.value ? null : authorize,
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
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text.rich(
                    TextSpan(
                      text: 'Уже есть аккаунт? ',
                      style: TextStyle(color: Colors.white),
                      children: [
                        TextSpan(
                          text: 'Войти',
                          style: TextStyle(color: Colors.white70),
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
