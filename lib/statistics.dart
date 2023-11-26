import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

var alq = 23; //Общее кол-во вопросов
var vzq = 18; //Кол-во взятых вопросов

class stat extends StatelessWidget {
  stat({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(200, 29, 82, 117),
      appBar: AppBar(elevation: 0),
      body: Column(
        children: <Widget>[
          Center(child: Center(child:Text('Статистика:', style: TextStyle(fontSize: 30,),),)),
          Center(child:Text('Общее кол-во вопросов: $alq', style: TextStyle(fontSize: 20),),),
          Padding(
            padding: EdgeInsets.all(15.0),
            child:LinearPercentIndicator(
              width: MediaQuery.of(context).size.width - 50,
              animation: true,
              lineHeight: 25.0,
              animationDuration: 1600,
              percent: vzq / alq,
              center: Text('${(vzq / alq * 100).round()}%', style: TextStyle(fontSize: 20),),
              progressColor: Colors.greenAccent,
              backgroundColor: Colors.red,
              barRadius: Radius.circular(20),
            ),
          ),
          Center(child:Text('Кол-во взятых вопросов: $vzq.', style: TextStyle(fontSize: 20),),),
          SizedBox(height: 65),
          CircularPercentIndicator(
            radius: 85.0,
            lineWidth: 20.0,
            animation: true,
            animationDuration: 1000,
            percent: 0.7,
            center:Text('${(vzq / alq * 100).round()}%', style: TextStyle(fontSize: 30),),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: Colors.yellow,
            backgroundColor: Colors.black,
          ),],
      ),);
  }
}