import 'package:flutter/material.dart';
import 'package:cgk/gender_icons.dart';

Padding getTextField(IconData iccon, txtxt, height_sc){
  return Padding(
      padding: EdgeInsets.all(10),
  child: Align(
  alignment: Alignment.topCenter,
  child: TextField(
    decoration: new InputDecoration(
      prefixIcon: Icon(iccon, size: height_sc / 10, color: Colors.white),
      labelText: txtxt,
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
        borderSide: const BorderSide(
          color: Color(0xff5c85ff),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        borderSide: BorderSide(color: Colors.black),
      ),
    ),
  )
  )
  );
}
void main() => runApp(MaterialApp(
  home: profil()
));

class profil extends StatelessWidget {
  profil({super.key});
  @override
  Widget build(BuildContext context){
    //double width_sc = MediaQuery.of(context).size.width;
    double height_sc = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color(0xff3987c8),
      appBar: new AppBar(
        elevation: 0,
        backgroundColor: Color(0xff418ecd),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Row(children: <Widget>[
              Text('Профиль', style: TextStyle(fontSize: 30, decoration: TextDecoration.underline), textAlign: TextAlign.center),
            ],
            mainAxisAlignment: MainAxisAlignment.center,
            ),

            CircleAvatar(
              backgroundImage: AssetImage('assets/avatar_image.png'),
              radius: 60,
              backgroundColor: Color(0xff3987c8),
              child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 75, vertical: 75),
                  child: IconButton(onPressed: (){}, icon: Icon(Icons.camera_alt, size: 40, color: Colors.lightBlue))
              ),
            ),
          SizedBox(height: 10),
          getTextField(Icons.person_outline_outlined, 'Имя Фамилия', height_sc),
          SizedBox(height: 10),
          getTextField(Gender.gender_6qiraf8z69nw, 'Пол', height_sc),
          SizedBox(height: 10),
          getTextField(Icons.email_sharp, 'Почта или номер телефона', height_sc),
          SizedBox(height: 10),
          getTextField(Icons.lock, 'Пароль', height_sc),
          ],
        ),
      ),
    );
  }
}
