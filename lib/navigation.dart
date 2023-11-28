import 'package:flutter/material.dart';

class Navigation extends StatelessWidget {
  const Navigation({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xff235d8c),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 15, top: 60),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.black),
                    title: const Text("Профиль"),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/profile');
                    },

                  ),
                  ListTile(
                    leading: const Icon(Icons.data_saver_off, color: Colors.black),
                    title: const Text("Статистика"),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/statistic');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer, color: Colors.black),
                    title: const Text("Таймер"),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/timer');
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
