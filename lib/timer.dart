import 'dart:async';
import 'package:cgk/timer1.dart';
import 'package:cgk/timer2.dart';
import 'package:cgk/timer3.dart';
import 'package:flutter/material.dart';

class StateTimerPage extends StatelessWidget {
  const StateTimerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;
    return Center(
        child: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Theme
                    .of(context)
                    .colorScheme
                    .inversePrimary,
                centerTitle: true,
                title: const Text("Timers"),
                bottom: const TabBar(
                    padding: EdgeInsets.all(1),
                    tabs: [
                      Tab(
                        icon: Icon(Icons.timelapse),
                      ),
                      Tab(
                        icon: Icon(Icons.timelapse_outlined),
                      ),
                      Tab(
                        icon: Icon(Icons.timelapse_rounded),
                      )
                    ]
                ),
              ),
              body: TabBarView(
                children: [
                  Container(
                    child: StateTimer1Page(),
                  ),
                  Container(
                    child: StateTimer2Page(),
                  ),
                  Container(
                    child: StateTimer3Page(),
                  )
                ],
              ),
            )
        )
    );
  }
}