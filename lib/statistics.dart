// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

var alq = 23; //Общее кол-во вопросов
var vzq = 18; //Кол-во взятых вопросов

class stat extends StatelessWidget {
  const stat({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff3987c8),
      appBar: AppBar(backgroundColor: const Color(0xff418ecd),),
      body:Center(child:Column(
        children: <Widget>[
          const Text('Статистика:', style: TextStyle(fontSize: 30,),),
          Text('Общее кол-во вопросов: $alq', style: const TextStyle(fontSize: 20),),
          const SizedBox(height: 25),
          CircularPercentIndicator(
            radius: 85.0,
            lineWidth: 20.0,
            animation: true,
            animationDuration: 1000,
            percent: 0.7,
            center:Text('${(vzq / alq * 100).round()}%', style: const TextStyle(fontSize: 30),),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: Colors.yellow,
            backgroundColor: Colors.black,
          ),
          const SizedBox(height: 25),
          Text('Кол-во взятых вопросов: $vzq.', style: const TextStyle(fontSize: 20),),
          ],),),);
  }
}