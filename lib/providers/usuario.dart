import 'package:flutter/material.dart';
class Usuario with ChangeNotifier{

     String _email=null;
     bool _root=null;
     int _ventana=0;


     get email{
       return _email;

     }
     get root{
       return _root;
     }
     get ventana{
       return _ventana;
     }
     set root(bool root){
       this._root=root;
       notifyListeners();
     }
     set ventana(int vent){
       this._ventana=vent;
       notifyListeners();
     }

     set email(String user){
        this._email=user;
        notifyListeners();
     }



}