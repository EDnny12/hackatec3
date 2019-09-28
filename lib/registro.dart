import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hackatec2/providers/usuario.dart';
import 'package:provider/provider.dart';
class Registro extends StatefulWidget {
   var _PrincipalState;
   Registro(this._PrincipalState);
  @override
  _RegistroState createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {

  TextEditingController correo=TextEditingController();
  TextEditingController pass=TextEditingController();
  TextEditingController cuentas=TextEditingController();
  TextEditingController codigo=TextEditingController();
  bool oscuro=true;
  @override
  void dispose() {
    correo.dispose();
    pass.dispose();
    cuentas.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
       appBar: AppBar(
         title: const Text("Administración de usuarios"),
         actions: <Widget>[IconButton(
           icon: Icon(Icons.add_circle),
           onPressed: ()async{

             await Firestore.instance
                 .collection('usuarios')
                 .where('email',
                 isEqualTo: Provider.of<Usuario>(context).email)
                 .getDocuments()
                 .then((result)async {
               await Firestore.instance
                   .collection('usuarios')
                   .where('padre',
                   isEqualTo: Provider.of<Usuario>(context).email)
                   .getDocuments()
                   .then((results) {
                 if(results.documents.length<result.documents[0].data["users"]){
                  widget._PrincipalState.addUser(false,null,null,null);
                 }else{
                   showDialog(context: context,builder: (context){
                     return AlertDialog(
                       title: const Text("Limite de Usuarios",textAlign: TextAlign.center,),
                       shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(15.0)),
                       content: SingleChildScrollView(
                         child:  Text("Su licencia actual no permite más de "+results.documents.length.toString()+" dispositivos, actualize su licencia si requiere más cuentas",textAlign: TextAlign.justify,),

                       ),
                       actions: <Widget>[
                         FlatButton(child: const Text("Actualizar"),onPressed: (){

                         },)
                       ],
                     );
                   });
                 }
               });

             });
           },
         )],
       ),
      body: StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection("usuarios").where("padre",isEqualTo: Provider.of<Usuario>(context).email)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
      if (snapshot.hasError) return const Text('ERROR AL CARGAR LOS USUARIOS');
      switch (snapshot.connectionState) {
      case ConnectionState.waiting:
      return  const CircularProgressIndicator();
      

      default:
      return lista(snapshot.data.documents, context);
      }
      },
      ),
    );

  }
  Widget lista(List<DocumentSnapshot> document, BuildContext context){
         return ListView.separated(padding: EdgeInsets.only(top: 10.0),itemCount: document.length,itemBuilder:(context,int d){
           return Card(
             shape:RoundedRectangleBorder(
                 borderRadius:  BorderRadius.circular(12.0)),
             margin: const EdgeInsets.only(left: 13.0, right: 13.0),
             child:Container(
                 child:  Center(
                   child:  Row(
                     children: <Widget>[

                       Expanded(
                         child:  Padding(
                             padding: const EdgeInsets.all(8.0),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: <Widget>[
                                 ListTile(title: Text(document[d].data["email"]),leading: const Icon(Icons.person),),
                                 document[d].data["permisos"][0]=="1"?const Text("Luces"):const SizedBox(),
                                 document[d].data["permisos"][1]=="1"?const Text("Puertas"):const SizedBox(),



                               ],
                             ),
                         ),
                       ),

                       IconButton(

                           icon: const Icon(

                               Icons.edit,
                               color: const Color(0xFF167F67)),
                           onPressed: () {

                                  widget._PrincipalState.addUser(true,document[d].data["email"],document[d].data["permisos"],document[d].reference);

                           }

                       ),

                     ],
                   ),
                 ),
                 padding: const EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0)),
           );
         },separatorBuilder: (context,int a){
           return const SizedBox(height: 15.0,);
         },);
  }
}

/*

 */


/*
 SingleChildScrollView(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width/1.1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 15.0,),
                TextFormField(
                  controller: correo,
                  obscureText: false,
                  decoration: InputDecoration(
                      border: const UnderlineInputBorder(),
                      filled: true,
                      hintText: "Correo",


                  ),
                ),
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
                          setState(() {

                          });
                        },
                        icon: Icon(oscuro ? Icons.visibility_off : Icons.visibility) ,
                      )

                  ),

                ),
                const SizedBox(height: 10,),
                TextFormField(
                  controller: codigo,
                  obscureText: false,
                  decoration: InputDecoration(
                      border: const UnderlineInputBorder(),
                      filled: true,
                      hintText: "Código de acceso",


                  ),

                ),
                const SizedBox(height: 15,),
                RaisedButton(child: const Text("Registrarse"),onPressed: (){

                },)
              ],
            ),
          ),
        ),
      ),
 */