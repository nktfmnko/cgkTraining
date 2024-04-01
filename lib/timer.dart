import 'dart:async';
import 'package:cgk/timer1.dart';
import 'package:cgk/timer2.dart';
import 'package:cgk/timer3.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
                backgroundColor: const Color(0xff4397de),
                centerTitle: true,
                title: const Text("Timers"),
                bottom: TabBar(
                    indicatorColor: const Color(0xff418ecd),
                    padding: EdgeInsets.all(1),
                    tabs: [
                      Tab(
                        icon: SvgPicture.asset(
                            'assets/Group 1.svg',
                            width: 25.0,
                            height: 25.0,
                        ),
                      ),
                      Tab(
                          icon: SvgPicture.asset(
                              'assets/Group 2.svg',
                              width: 25.0,
                              height: 25.0,
                          )
                      ),
                      Tab(
                          icon: SvgPicture.asset(
                              'assets/Group 3.svg',
                              width: 25.0,
                              height: 25.0,
                          )
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