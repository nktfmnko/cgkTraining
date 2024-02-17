import 'package:cgk/qa.dart';
import 'package:flutter/material.dart';

double selected = 1;

class SelectQuestion extends StatefulWidget {
  const SelectQuestion({super.key});

  @override
  State<SelectQuestion> createState() => _SelectQuestionState();
}

class _SelectQuestionState extends State<SelectQuestion> {
  @override
  void initState() {
    hideBar();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff3987c8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Выберите количество вопросов:',
              style: TextStyle(fontSize: 22),
            ),
            SizedBox(
              height: 20,
            ),
            Slider(
              value: selected,
              max: 10,
              min: 1,
              label: selected.round().toString(),
              divisions: 9,
              onChanged: (double value) {
                setState(
                  () {
                    selected = value;
                  },
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Игра со временем:",
                  style: TextStyle(fontSize: 20),
                ),
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: timeGame,
                    onChanged: (bool? value) {
                      setState(
                        () {
                          timeGame = value!;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            ElevatedButton(
              style: ButtonStyle(

              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Training(),
                  ),
                  (route) => false,
                );
              },
              child: Text("Начать"),
            )
          ],
        ),
      ),
    );
  }
}
