import 'package:cgk/menu.dart';
import 'package:cgk/message_exception.dart';
import 'package:cgk/signup.dart';
import 'package:cgk/union_state.dart';
import 'package:cgk/value_union_state_listener.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

extension TypeCast<T> on T? {
  R safeCast<R>() {
    final value = this;
    if (value is R) return value;
    throw Exception('не удалось привести тип $runtimeType к типу $R');
  }
}

String? userEmail;
bool rememberMe = false;

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
  final loginState = UnionStateNotifier<void>(UnionState$Content(null));
  final supabase = Supabase.instance.client;
  final isPressState = ValueNotifier<bool>(false);

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
      prefs.setBool("remember", rememberMe);
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          child: Row(
                            children: [
                              Text(
                                'Запомнить меня:',
                                style: TextStyle(color: Colors.white),
                              ),
                              Checkbox(
                                checkColor: Colors.black,
                                activeColor: Colors.black26,
                                side:
                                    BorderSide(color: Colors.black, width: 1.5),
                                value: rememberMe,
                                onChanged: (value) {
                                  setState(
                                    () {
                                      rememberMe = value!;
                                    },
                                  );
                                },
                              )
                            ],
                          ),
                        ),
                        Align(
                          child: TextButton(
                            onPressed: () {},
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
                            onPressed: login,
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
                            onPressed: login,
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
