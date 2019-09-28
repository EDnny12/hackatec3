import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hackatec2/principal.dart';
import 'package:hackatec2/providers/usuario.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:imei_plugin/imei_plugin.dart';
final FirebaseAuth _auth = FirebaseAuth.instance;
class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {

  TextEditingController correo=TextEditingController();
  TextEditingController pass=TextEditingController();
  bool oscuro=true;
  void login()async{
    if(correo.text!="" || pass.text!=""){

      await _auth
          .signInWithEmailAndPassword(
          email: correo.text, password: pass.text)
          .then((user) async {
        assert(user.user.email != null);

        await _auth.currentUser().then((user) {
          Provider.of<Usuario>(context).email = user.email;
          verificarImei(user.email);

        });
      }).catchError((error){
        correo.text="";
        pass.text="";
        msj();
      });
    }else{
      msj();
    }
  }
  void actualizar(){

    setState(() {});
  }
  void verificarImei(String email)async{
   await ImeiPlugin.getImei().then((imei)async{
     if(Provider.of<Usuario>(context).email!=null){



       await Firestore.instance
           .collection('usuarios')
           .where('email',
           isEqualTo: email)
           .getDocuments()
           .then((result) async{
             Provider.of<Usuario>(context).root= result.documents[0].data["root"]=="1"?true:false;
             //print(result.documents.length);
             if(result.documents[0].data["imei"]==null){

               await Firestore.instance
                   .collection('usuarios')
                   .where('imei',
                   isEqualTo: imei)
                   .getDocuments()
                   .then((results) {
                     if(!(results.documents.length!=0)){
                       Firestore.instance.runTransaction((transaction) async {
                         DocumentSnapshot snapshot =
                         await transaction.get(result.documents[0].reference);
                         await transaction.update(result.documents[0].reference, {
                           "imei": imei,


                         });
                       });
                       Navigator.of(context).pop();
                       Navigator.push(
                         context,
                         CupertinoPageRoute(builder: (context)=>Principal()),
                       );
                     }else{
                       _auth.signOut();
                       correo.text="";
                       pass.text="";
                       msj();
                     }
               });


             }else{
               if(result.documents[0].data["imei"]==imei){
                 Navigator.of(context).pop();
                 Navigator.push(
                   context,
                   CupertinoPageRoute(builder: (context)=>Principal()),
                 );
               }else{
                 correo.text="";
                 pass.text="";

                 _auth.signOut();
                 msj();
               }
             }
       });
     }
    });

  }
  @override
  void dispose() {
    correo.dispose();
    pass.dispose();
    super.dispose();
  }
  final GlobalKey<ScaffoldState> sca = GlobalKey<ScaffoldState>();
  void msj() {
    sca.currentState.showSnackBar(const SnackBar(
      content: const Text("Error"),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: sca,
      body:
     SingleChildScrollView(
       child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width/1.2,
              child: Column(

                mainAxisAlignment: MainAxisAlignment.center,
       //         crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[

                  const Icon(Icons.person,size: 350,),


                     Correo(correo),
                  const SizedBox(height: 10,),
              TextFormField(
                controller: pass,
                obscureText: oscuro,
                decoration: InputDecoration(
                    border: const UnderlineInputBorder(),
                    filled: true,
                    hintText: "Contraseña",
                    suffixIcon: IconButton(
                      onPressed: (){
                     oscuro=!oscuro;
                     actualizar();
                      },
                      icon: Icon(oscuro ? Icons.visibility_off : Icons.visibility) ,
                    )

                ),
              ),
                  const SizedBox(height: 20.0,),

                  RaisedButton(onPressed:()async{

                    login();
                  },child: const Text("Iniciar Sesión"),),

                  /*FlatButton(child:
                    const Text("Registrarse")
                    ,
                  onPressed: (){
                    Navigator.push(
                      context,
                        CupertinoPageRoute(builder: (context)=>Registro()),
                    );

                  },
                  ),

                   */
                ],
              ),
            ),
          ),
     ),

    );
  }
}

class Correo extends StatelessWidget {
   TextEditingController correo;
   Correo(this.correo);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
     controller: this.correo,
      decoration: InputDecoration(
        border: const UnderlineInputBorder(),
        filled: true,
        hintText: "Correo",
      ),
    );
  }
}
