import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pirov2_app/pages/device_list_page.dart';

void main() { 
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) =>
      runApp(Pirov2App())
    );
}

class Pirov2App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return (
          new MaterialApp(
          debugShowCheckedModeBanner: false,
          home: new DeviceListPage(),
          theme: new ThemeData(
            // Define the default brightness and colors.
            brightness: Brightness.light,
            primaryColor: Colors.deepPurple,
            accentColor: Colors.amber,

            // Define the default font family.
            fontFamily: 'Montserrat'
          )
        )
    );
  }
}