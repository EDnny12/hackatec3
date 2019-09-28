import 'package:flutter/services.dart';
import 'package:local_auth/auth_strings.dart';
import 'dart:io';
import 'package:local_auth/local_auth.dart';
class Metodos{
  Future<bool> authorizeNow() async {

    const strings=AndroidAuthMessages(
      cancelButton: "Cancelar",
      goToSettingsButton: "Configuración",
      goToSettingsDescription: "",
      signInTitle: "ADMINISTRADOR",


    );
    bool isAuthorized = false;
    try {
      isAuthorized = await LocalAuthentication().authenticateWithBiometrics(

        localizedReason: "Auntenticación requerida",
        androidAuthStrings: strings,

        stickyAuth: true,
      );
    } on PlatformException catch (e) {}

    return isAuthorized;
  }
}