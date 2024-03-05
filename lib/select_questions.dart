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
              activeColor: Colors.black,
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
                    checkColor: Colors.black,
                    activeColor: Colors.black26,
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
            SizedBox(
              height: 45,
              width: 120,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(const Color(0xff418ecd)),
                  shadowColor:
                      MaterialStateProperty.all(const Color(0xff418ecd)),
                  overlayColor: MaterialStateProperty.all(Colors.black12),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        color: Colors.black,
                        width: 1.5,
                      ),
                    ),
                  ),
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
                child: Text(
                  "Начать",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
