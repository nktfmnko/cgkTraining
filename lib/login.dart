import 'dart:convert';
import 'package:cgk/menu.dart';
import 'package:cgk/message_exception.dart';
import 'package:cgk/signup.dart';
import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

extension TypeCast<T> on T? {
  R safeCast<R>() {
    final value = this;
    if (value is R) return value;
    throw Exception('не удалось привести тип $runtimeType к типу $R');
  }
}

String? userEmail;
bool isLogin = false;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class UserInfo {
  final String mail;
  final String password;

  const UserInfo({
    required this.mail,
    required this.password,
  });
}

class _LoginScreenState extends State<LoginScreen> {
  final obscureTextState = ValueNotifier<bool>(true);
  final mailController = TextEditingController();
  final passwordController = TextEditingController();
  final forgotPasswordController = TextEditingController();
  final forgotState = UnionStateNotifier<void>(UnionState$Content(null));
  final loginState = UnionStateNotifier<void>(UnionState$Content(null));
  final supabase = Supabase.instance.client;
  final isPressState = ValueNotifier<bool>(false);
  final pressForgot = ValueNotifier<bool>(false);

  Future<List<UserInfo>> readLogins() async {
    final response = await supabase.from('users').select('email, password');
    return TypeCast(response)
        .safeCast<List<Object?>>()
        .map((e) => TypeCast(e).safeCast<Map<String, Object?>>())
        .map(
          (e) => UserInfo(
              mail: TypeCast(e['email']).safeCast<String>(),
              password: TypeCast(e['password']).safeCast<String>()),
        )
        .toList();
  }

  bool correctFields({required String mail, required String password}) {
    return mail.isNotEmpty && password.isNotEmpty;
  }

  bool correctLogin(List<UserInfo> users) {
    for (final user in users) {
      if (user.mail == mailController.text &&
          user.password == passwordController.text) return true;
    }
    return false;
  }

  Future<void> login() async {
    try {
      setState(() {});
      final isFieldsValid = correctFields(
          mail: mailController.text, password: passwordController.text);
      if (!isFieldsValid) {
        loginState.error(MessageException('Поля неверно заполнены'));
        return;
      }
      isPressState.value = !isPressState.value;

      final userInfo = await readLogins();
      if (!correctLogin(userInfo)) {
        loginState.error(MessageException('Неверный логин или пароль'));
        isPressState.value = !isPressState.value;
        return;
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("mail", mailController.text);
      prefs.setBool("isLogin", true);
      userEmail = mailController.text;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const menu()),
        (route) => false,
      );
    } on Exception {
      loginState.error(MessageException('Произошла ошибка, повторите'));
      isPressState.value = !isPressState.value;
    }
  }

  Future<void> sendEmail() async {
    try {
      if (forgotPasswordController.text.isEmpty) {
        forgotState.error(MessageException('Поле неверно заполнено'));
        return;
      }
      pressForgot.value = !pressForgot.value;
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final password = await supabase
          .from('users')
          .select('password')
          .eq('email', '${forgotPasswordController.text}');
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
              'to_email': '${forgotPasswordController.text}',
              'message': '${password}',
            }
          },
        ),
      );
      pressForgot.value = !pressForgot.value;
      forgotState.value = UnionState$Content(null);
      forgotPasswordController.text = "";
      Navigator.of(context, rootNavigator: true).pop();
    } on Exception {
      forgotState.error(MessageException('Произошла ошибка, повторите'));
      pressForgot.value = !pressForgot.value;
    }
  }

  @override
  void dispose() {
    loginState.dispose();
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
                  height: MediaQuery.of(context).size.height / 4.5,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      cursorColor: Colors.white,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      controller: mailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.person_outline_outlined,
                          color: Colors.white,
                        ),
                        labelText: 'E-Mail',
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
                    const SizedBox(
                      height: 30,
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: obscureTextState,
                      builder: (_, obscureText, __) {
                        return TextFormField(
                          cursorColor: Colors.white,
                          style: TextStyle(color: Colors.white),
                          obscureText: obscureText,
                          controller: passwordController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.password_outlined,
                              color: Colors.white,
                            ),
                            labelText: 'Пароль',
                            labelStyle: TextStyle(color: Colors.white),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.black, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.black, width: 1.7),
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
                    const SizedBox(
                      height: 1,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Align(
                          child: TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Color(0xff4397de),
                                    title: Text(
                                      'Введите почту',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: SizedBox(
                                      height: 150,
                                      width: 300,
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            cursorColor: Colors.white,
                                            style:
                                                TextStyle(color: Colors.white),
                                            controller:
                                                forgotPasswordController,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            decoration: InputDecoration(
                                              labelText: 'Почта',
                                              labelStyle: TextStyle(
                                                  color: Colors.white),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.black,
                                                    width: 1.5),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.black,
                                                    width: 1.5),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 20,
                                          ),
                                          ValueUnionStateListener<void>(
                                            unionListenable: forgotState,
                                            contentBuilder: (_) {
                                              return ElevatedButton(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      MaterialStatePropertyAll<
                                                              Color>(
                                                          Color(0xff1b588c)),
                                                ),
                                                onPressed: pressForgot.value
                                                    ? null
                                                    : sendEmail,
                                                child: ValueListenableBuilder<
                                                    bool>(
                                                  valueListenable: pressForgot,
                                                  builder: (_, isPress, __) {
                                                    return isPress
                                                        ? CircularProgressIndicator(
                                                            color: Colors.white,
                                                          )
                                                        : Text(
                                                            'Отправить пароль',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 17),
                                                          );
                                                  },
                                                ),
                                              );
                                            },
                                            loadingBuilder: () {
                                              return ElevatedButton(
                                                onPressed: null,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                ),
                                              );
                                            },
                                            errorBuilder: (exception) {
                                              return ElevatedButton(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      MaterialStatePropertyAll<
                                                              Color>(
                                                          Color(0xff1b588c)),
                                                ),
                                                onPressed: pressForgot.value
                                                    ? null
                                                    : sendEmail,
                                                child: ValueListenableBuilder<
                                                    bool>(
                                                  valueListenable: pressForgot,
                                                  builder: (_, isPress, __) {
                                                    return isPress
                                                        ? CircularProgressIndicator(
                                                            color: Colors.white,
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
                                            },
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ).then((value) {
                                forgotState.value = UnionState$Content(null);
                              });
                            },
                            child: Text(
                              'Забыли пароль?',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ValueUnionStateListener(
                        unionListenable: loginState,
                        contentBuilder: (_) {
                          return ElevatedButton(
                            onPressed: isPressState.value ? null : login,
                            child: ValueListenableBuilder<bool>(
                              valueListenable: isPressState,
                              builder: (_, isPress, __) {
                                return isPress
                                    ? CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        'Войти',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 17),
                                      );
                              },
                            ),
                            style: ButtonStyle(
                              backgroundColor: MaterialStatePropertyAll<Color>(
                                  Color(0xff1b588c)),
                            ),
                          );
                        },
                        loadingBuilder: () {
                          return ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStatePropertyAll<Color>(
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
                              backgroundColor: MaterialStatePropertyAll<Color>(
                                  Color(0xff1b588c)),
                            ),
                            onPressed: isPressState.value ? null : login,
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
                const SizedBox(
                  height: 20,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignUpScreen(),
                      ),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      text: 'Нет аккаунта? ',
                      style: TextStyle(color: Colors.white),
                      children: [
                        TextSpan(
                          text: 'Зарегистрироваться',
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
