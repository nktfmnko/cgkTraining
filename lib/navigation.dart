import 'package:flutter/material.dart';

class Navigation extends StatelessWidget {
  const Navigation({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: SingleChildScrollView(
            child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(left:15, top: 50), 
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("профиль"),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/profile');
                },
              ),
               ListTile(
                leading: const Icon(Icons.data_saver_off),
                title: const Text("статистика"),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/statistic');
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer), 
                title: const Text("таймер"),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/timer');
                },
                )
            ],
          ),
        ),
      ],
    )));
  }
}