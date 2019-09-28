import 'package:flutter/material.dart';
import 'package:hackatec2/providers/usuario.dart';
import 'login.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(builder: (context)=>Usuario(),)
      ],
      child: MaterialApp(
        home: Login(),

      ),
    );
  }
}
