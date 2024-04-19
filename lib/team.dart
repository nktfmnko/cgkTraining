import 'package:cgk/makeTeam.dart';
import 'package:cgk/menu.dart';
import 'package:flutter/material.dart';

extension TypeCast<T> on T? {
  R safeCast<R>() {
    final value = this;
    if (value is R) return value;
    throw Exception('не удалось привести тип $runtimeType к типу $R');
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
        child: haveTeam!.isEmpty
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
                    )
                  ],
                ),
              )
            : Column(),
      ),
    );
  }
}
