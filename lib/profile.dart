import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';

Padding getTextField(IconData iccon, txtxt, height_sc, context) {
  return Padding(
    padding: const EdgeInsets.all(10),
    child: Align(
      alignment: Alignment.topCenter,
      child: TextFormField(
        validator: (email) => (txtxt == 'Почта'
            ? EmailValidator.validate(email.toString())
                ? null
                : "Пожалуйста введите корректную почту"
            : null),
        autocorrect: false,
        keyboardType: TextInputType.visiblePassword,
        decoration: InputDecoration(
          prefixIcon: Icon(iccon, size: height_sc / 15, color: Colors.white),
          labelText: txtxt,
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(20.0),
            ),
            borderSide: BorderSide(
              color: Colors.black38,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(color: Colors.black),
          ),
        ),
      ),
    ),
  );
}

class profile extends StatelessWidget {
  profile({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    double height_sc = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xff3987c8),
      appBar: AppBar(
        backgroundColor: const Color(0xff418ecd),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Профиль',
                      style: TextStyle(
                        fontSize: 30,
                      ),
                      textAlign: TextAlign.center),
                ],
              ),
              CircleAvatar(
                backgroundImage: const AssetImage('assets/avatar_image.png'),
                radius: 60,
                backgroundColor: const Color(0xff3987c8),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 75, vertical: 75),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt,
                        size: 40, color: Colors.lightBlue),
                  ),
                ),
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 10),
                    getTextField(Icons.person_outline_outlined, 'Имя Фамилия',
                        height_sc, context),
                    const SizedBox(height: 10),
                    getTextField(
                        Icons.email_sharp, 'Почта', height_sc, context),
                    const SizedBox(height: 10),
                    getTextField(Icons.lock, 'Пароль', height_sc, context),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  final form = _formKey.currentState!;
                  if (form.validate()) {}
                },
                child: const Text(
                  'Подтвердить',
                  style: TextStyle(fontSize: 15, color: Colors.black),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
