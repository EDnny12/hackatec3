import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

import 'package:hackatec2/conexion.dart';
import 'package:hackatec2/login.dart';
import 'package:hackatec2/providers/metodos.dart';
import 'package:hackatec2/providers/usuario.dart';
import 'package:hackatec2/registro.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
class Principal extends StatefulWidget {
  @override
  _PrincipalState createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
     TextEditingController correo=TextEditingController();
     bool luces=false;
     bool puerta=false;
  void addUser(bool edit,String mail,var per,final re){
    if(edit && per!=null){
      luces=per[0]=="1"?true:false;
      puerta=per[1]=="1"?true:false;
    }
    showDialog(context: context,builder: (context){
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0)),
          title: Text(!edit?"Nuevo Usuario":"Editar Usuario",textAlign: TextAlign.center,),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                !edit?TextFormField(

                  controller: correo,
                  decoration: InputDecoration(
                      border: const UnderlineInputBorder(),
                    filled: true,
                    hintText: "Correo"
                  ),
                ): ListTile(title: Text(mail),),
              CheckboxListTile(value: luces, onChanged: (luz){
                setState(() {
                  luces=luz;
                });
                Navigator.of(context).pop();
                addUser(edit,mail,null,re);

              },title: const Text("Luces"),),
                CheckboxListTile(
                  value: puerta,
                  onChanged: (puert){
                    setState(() {
                      puerta=puert;
                    });
                    Navigator.of(context).pop();
                    addUser(edit,mail,null,re);
                  },
                  title: const Text("Puerta"),
                ),
                RaisedButton(child: Text(!edit?"Aceptar":"Editar"),onPressed: (){
                  if(edit){
                    Firestore.instance.runTransaction((transaction) async {
                      DocumentSnapshot snapshot =
                      await transaction.get(re);
                      transaction.update(re, {
                      "permisos":[luces?"1":"0",puerta?"1":"0"]
                      });
                    });
                    Navigator.of(context).pop();
                  }else{

                    FirebaseAuth.instance.createUserWithEmailAndPassword(email: correo.text, password: "123abc").then((user){
                      Firestore.instance.runTransaction((Transaction transaccion) async {
                        CollectionReference referencesx = Firestore.instance.collection('usuarios');
                        print(user.user.email.toString());
                        print(Provider.of<Usuario>(context).email);
                        await referencesx.add({
                       "email":user.user.email.toString(),
                          "imei":null,
                          "root":"0",
                          "padre": Provider.of<Usuario>(context).email,
                          "permisos":[luces?"1":"0",puerta?"1":"0"]
                        });

                      });
                    });

                  }

                },),
              ],
            ),
          ),
        );
    });
  }
  @override
  Widget build(BuildContext context) {
   return Scaffold(
      appBar:AppBar(
     automaticallyImplyLeading: false,
     title: const Text("Seguridad"),

        leading:Provider.of<Usuario>(context).root? IconButton(icon: Icon(Icons.menu),onPressed: (){
          showModalBottomSheet(
              shape: const RoundedRectangleBorder(borderRadius: const BorderRadius.only(topLeft: const Radius.circular(15.0),topRight: const Radius.circular(15.0))),
              context: context,builder: (context){
            return SingleChildScrollView(
              child: Column(children: <Widget>[
                ListTile(leading: const Icon(Icons.security),title: const Text("Sistema de seguridad IoT"),),
                Divider(),
                ListTile(leading: Icon(Icons.supervised_user_circle),title: const Text("Administración de usuarios"),onTap: (){
                  Navigator.of(context).pop();
                  Navigator.push(context, CupertinoPageRoute(builder:(context)=>Registro(this)));
                },),

                ListTile(leading: const Icon(Icons.exit_to_app),title: const Text("Cerrar sesión"),onTap: (){
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).pop();
                  Navigator.push(context, CupertinoPageRoute(builder:(context)=>Login()));
                },),
              ],),
            );
          });
        },):const SizedBox(),
        actions: <Widget>[
          !Provider.of<Usuario>(context).root?IconButton(icon: const Icon(Icons.exit_to_app),onPressed: (){
            FirebaseAuth.instance.signOut();
            Navigator.of(context).pop();
            Navigator.push(context, CupertinoPageRoute(builder:(context)=>Login()));
          },):const SizedBox(),

        ],
   ),
     body:Acceso(this),
   );
  }
}

class User extends StatefulWidget {
  var device;
  User(this.device);
  @override
  _UserState createState() => _UserState();
}

class _UserState extends State<User> {
  bool luces=false;
  bool puerta=false;
  BluetoothConnection connection;
  bool msj=false;
  void conexion()async{
    await BluetoothConnection.toAddress(widget.device.address).then((conect){

      setState(() {
        connection=conect;
        msj=conect.isConnected;
      });
      /*conect.input.listen((data){

        setState(() {
          msj=data.toString();
        });

      });

       */
    });

  }
  @override
  void initState() {
    conexion();// TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
         title: const Text("Controles"),
       ),
      body: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection("usuarios")
            .where("email",isEqualTo: Provider.of<Usuario>(context).email)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return const Text('ERROR AL CARGAR LOS AVISOS');
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Container(
                alignment: Alignment.center,
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height / 2 - 50),
                child: const CircularProgressIndicator(),
              );

            default:
              return lista(snapshot.data.documents, context);
          }
        },
      ),
    );
  }
  Widget lista(List<DocumentSnapshot> document, BuildContext contexta){
        return ListView.separated(padding: EdgeInsets.only(top: 30.0),itemBuilder: (context,int d){
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SwitchListTile(
             title: msj?Text("Conectado"):Text("Esperando conexión"),
                value: msj,
              ),
            document[d].data["permisos"][0]=="1"?  Card(

                elevation: 1.6,
                shape:  RoundedRectangleBorder(
                    borderRadius:  BorderRadius.circular(12.0)),
                margin: const EdgeInsets.only(left: 15.0, right: 15.0),
                child:
                SwitchListTile(secondary: !luces?Icon(Icons.lightbulb_outline):Icon(Icons.wb_incandescent,color: Colors.yellow,),title: const Text("Luces"),value: luces,onChanged: (sa){

                 Metodos().authorizeNow().then((value)async{
                    if(value){
                      connection.output.add(ascii.encode(sa?"l":"j"));
                      await connection.output.allSent;
                      setState(() {
                        luces=sa;
                      });

                    }
                  });
                },),


              ):const SizedBox(),
              const SizedBox(height: 20.0,),
              document[d].data["permisos"][1]=="1"?    Card(

                elevation: 1.6,
                shape:  RoundedRectangleBorder(
                    borderRadius:  BorderRadius.circular(12.0)),
                margin: const EdgeInsets.only(left: 15.0, right: 15.0),
                child:
                SwitchListTile(secondary: puerta?const Icon(Icons.lock_open,color: Colors.green,):const Icon(Icons.lock_outline),title: const Text("Puerta"),value: puerta,onChanged: (sa){
                 Metodos().authorizeNow().then((value)async{
                    if(value){
                      connection.output.add(ascii.encode(sa?"p":"f"));
                      await connection.output.allSent;
                      setState(() {
                        puerta=sa;
                      });

                    }
                  });
                },),

              ):const SizedBox(),
            ],
          );

        }, separatorBuilder: (context,int d){
          return SizedBox(height: 20,);
        }, itemCount: document.length);
  }
}

class Acceso extends StatelessWidget {
  var _PrincipalState;
  Acceso(this._PrincipalState);
  @override
  Widget build(BuildContext context) {
    return Blue();
  }
}
class Blue extends StatefulWidget {
  @override
  _BlueState createState() => _BlueState();
}

class _BlueState extends State<Blue> {

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  bool si=false;
  @override
  void initState() {
    // Listen for futher state changes
    FlutterBluetoothSerial.instance.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled

      });
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Center(child: Container(

      child:
      Column(
        children: <Widget>[
          SwitchListTile(
            title: const Text('Activar Bluetooth'),
            value: _bluetoothState.isEnabled,
            onChanged: (bool value) {
              // Do the request and update with the true value then
              future() async { // async lambda seems to not working
                if (value)
                  await FlutterBluetoothSerial.instance.requestEnable();
                else
                  await FlutterBluetoothSerial.instance.requestDisable();
              }
              future().then((_) {
                setState(() {});
              });
            },
          ),

      SwitchListTile(title: const Text("¿Aún no ha configurado su dispositivo?"),value: si,onChanged: (sa){
        setState(() {
          si=sa;
        });
      },),
      !(si) ? RaisedButton(
        child: const Text("Configurar"),
        onPressed: (){
          FlutterBluetoothSerial.instance.openSettings();
        },
      ):const SizedBox(),

          _bluetoothState.isEnabled && si?RaisedButton(child: Text("Iniciar"),onPressed: (){
            Navigator.push(
                context,
                CupertinoPageRoute(builder: (context)=>SelectBondedDevicePage()));
          },):const SizedBox(),
        ],
      ),

    ));

  }
}

/*
FabCircularMenu(
        child: Provider.of<Usuario>(context).ventana==0?SelectBondedDevicePage():Registro(_PrincipalState),
        ringColor: Colors.blue,
        options: <Widget>[
          IconButton(icon: const Icon(Icons.exit_to_app), onPressed: () {
            FirebaseAuth.instance.signOut();
            Navigator.of(context).pop();
            Navigator.push(context, CupertinoPageRoute(builder:(context)=>Login()));
          }, iconSize: 48.0, color: Colors.white),


          IconButton(icon: const Icon(Icons.person_add), onPressed: () {
          Provider.of<Usuario>(context).ventana=1;
          }, iconSize: 48.0, color: Colors.white),
          IconButton(icon: const Icon(Icons.home), onPressed: () {
            Provider.of<Usuario>(context).ventana=0;
          }, iconSize: 48.0, color: Colors.white),
        ],
      );
 */
class Dashboard extends StatefulWidget {
  var device;
  Dashboard(this.device);
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

  bool luces=false;
  bool puerta=false;
  BluetoothConnection connection;
  bool msj=false;
  void conexion()async{
    await BluetoothConnection.toAddress(widget.device.address).then((conect){

      setState(() {
        connection=conect;
        msj=conect.isConnected;
      });



    });

  }
  @override
  void initState() {
    conexion();// TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Controles"),
        ),
      body: Container(
        child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[

               SwitchListTile(
                 title: msj?Text("Conectado"):Text("Esperando conexión"),
                 value: msj,
               ),
                Card(

                  elevation: 1.6,
                  shape:  RoundedRectangleBorder(
                      borderRadius:  BorderRadius.circular(12.0)),
                  margin: const EdgeInsets.only(left: 15.0, right: 15.0),
                  child:
                    SwitchListTile(secondary: !luces?Icon(Icons.lightbulb_outline):Icon(Icons.wb_incandescent,color: Colors.yellow,),title: const Text("Luces"),value: luces,onChanged: (sa)async{

                      Metodos().authorizeNow().then((value) async {
                        if(value){
                          if(connection!=null){
                            connection.output.add(ascii.encode(sa?"l":"j"));
                            await connection.output.allSent;
                          }

                          setState(() {

                            luces=sa;
                          });

                        }
                      });
                    },),


                                ),
                const SizedBox(height: 20.0,),
                Card(

                  elevation: 1.6,
                  shape:  RoundedRectangleBorder(
                      borderRadius:  BorderRadius.circular(12.0)),
                  margin: const EdgeInsets.only(left: 15.0, right: 15.0),
                    child:
                      SwitchListTile(secondary: puerta?const Icon(Icons.lock_open,color: Colors.green,):const Icon(Icons.lock_outline),title: const Text("Puerta"),value: puerta,onChanged: (sa){
                        Metodos().authorizeNow().then((value) async {
                          if(value){
                            connection.output.add(ascii.encode(sa?"p":"f"));
                            await connection.output.allSent;
                            setState(() {
                              puerta=sa;
                            });

                          }
                        });
                      },),

                ),
              ],
            )
        ),
    );
  }
}
