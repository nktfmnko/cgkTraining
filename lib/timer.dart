import 'package:cgk/timer1.dart';
import 'package:cgk/timer2.dart';
import 'package:cgk/timer3.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StateTimerPage extends StatefulWidget {
  const StateTimerPage({Key? key}) : super(key: key);

  @override
  _StateTimerPageState createState() => _StateTimerPageState();
}

class _StateTimerPageState extends State<StateTimerPage> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                title: const Text("Таймеры"),
                automaticallyImplyLeading: false,
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
                  StateTimer1Page(),
                  StateTimer2Page(),
                  StateTimer3Page(),
                ],
              ),
            )
        )
    );
  }
}