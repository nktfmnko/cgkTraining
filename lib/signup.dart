import 'package:cgk/login.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

class User {
  final String name;
  final String mail;
  final String password;

  const User({
    required this.name,
    required this.mail,
    required this.password,
  });
}

bool seePassword = true;
List<User> users = <User>[];

bool hasEmail(List<User> u, String s) {
  for (var value in u) {
    if (value.mail == s) return true;
  }
  return false;
}

bool correctFields(String mail, String password, String user) {
  return !hasEmail(users, mail) &&
      !mail.isEmpty &&
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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final mailController = TextEditingController();
  final passwordController = TextEditingController();

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
                        onChanged: (String value) async {
                          setState(() {});
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (input) =>
                            EmailValidator.validate(mailController.text)
                                ? (hasEmail(users, mailController.text)
                                    ? 'Пользователь с такой почтой уже есть'
                                    : null)
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
                        child: ElevatedButton(
                          onPressed: correctFields(mailController.text,
                                  passwordController.text, nameController.text)
                              ? () {
                                  hasEmail(users, mailController.text)
                                      ? showDialog(
                                          context: context,
                                          builder: (BuildContext) {
                                            return AlertDialog(
                                              title: Text(
                                                  'Пользователь с такой почтой уже есть'),
                                            );
                                          },
                                        )
                                      : users.add(
                                          new User(
                                              name: nameController.text,
                                              mail: mailController.text,
                                              password:
                                                  passwordController.text),
                                        );
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext) {
                                      return AlertDialog(
                                        title:
                                            Text('Вы успешно зарегистрированы'),
                                        content: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const LoginScreen(),
                                                ),
                                                (route) => false);
                                          },
                                          child: Text('Войти'),
                                        ),
                                      );
                                    },
                                  );
                                  setState(() {});
                                }
                              : null,
                          child: Text('Зарегистрироваться'),
                        ),
                      )
                    ],
                  ),
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
