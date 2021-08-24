import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:radio_taxi_alfa_app/src/models/taxista.dart';
import 'package:radio_taxi_alfa_app/src/providers/auth_provider.dart';
import 'package:radio_taxi_alfa_app/src/utils/snackbar.dart' as utils;
import 'package:radio_taxi_alfa_app/src/utils/my_progress_dialog.dart';
import 'package:radio_taxi_alfa_app/src/providers/taxista_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/storage_provider.dart';

class TaxistaEditarControlador {

  BuildContext context;
  Function refresh;
  GlobalKey<ScaffoldState> key = new GlobalKey<ScaffoldState>();

  TextEditingController pin1Controlador = new TextEditingController();
  TextEditingController pin2Controlador = new TextEditingController();
  TextEditingController pin3Controlador = new TextEditingController();
  TextEditingController pin4Controlador = new TextEditingController();
  TextEditingController pin5Controlador = new TextEditingController();
  TextEditingController pin6Controlador = new TextEditingController();
  TextEditingController pin7Controlador = new TextEditingController();

  TextEditingController nombreUsuarioControlador = new TextEditingController();
  TextEditingController telefonoControlador = new TextEditingController();

  AuthProvider _authProvider;
  TaxistaProvider _taxistaProvider;
  StorageProvider _storageProvider;
  ProgressDialog _progressDialog;

  PickedFile eleccionFile;
  File imagenFile;

  Taxista taxista;

  Future init (BuildContext context, Function refresh) {
    this.context = context;
    this.refresh = refresh;

    _authProvider = new AuthProvider();
    _taxistaProvider = new TaxistaProvider();
    _storageProvider = new StorageProvider();
    _progressDialog = MyProgressDialog.createProgressDialog(context, 'Espere un momento...');

    obtenerInfoUsuario();
  }

  void obtenerInfoUsuario() async {
    taxista = await _taxistaProvider.obtenerId(_authProvider.obtenerUsuario().uid);
    nombreUsuarioControlador.text = taxista.nombreUsuario;
    telefonoControlador.text = taxista.telefono;
    if(taxista?.imagen == null){
      imagenFile = null;
    } else {
      imagenFile = File(taxista?.imagen);
    }
    pin1Controlador.text = taxista.placas[0];
    pin2Controlador.text = taxista.placas[1];
    pin3Controlador.text = taxista.placas[2];
    pin4Controlador.text = taxista.placas[4];
    pin5Controlador.text = taxista.placas[5];
    pin6Controlador.text = taxista.placas[6];
    pin7Controlador.text = taxista.placas[8];
    refresh();
  }

  void showAlertDialog() {

    Widget btnGaleria = TextButton(
        onPressed: () {
          obtenerImagen(ImageSource.gallery);
        },
        child: Text('GALERIA')
    );

    Widget btnCamara = TextButton(
        onPressed: () {
          obtenerImagen(ImageSource.camera);
        },
        child: Text('CAMARA')
    );

    AlertDialog alertDialog = AlertDialog(
      title: Text('Selecciona tu imagen'),
      actions: [
        btnGaleria,
        btnCamara
      ],
    );

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return alertDialog;
        }
    );

  }

  Future obtenerImagen(ImageSource imageSource) async {
    eleccionFile = await ImagePicker().getImage(source: imageSource);
    if (eleccionFile != null) {
      imagenFile = File(eleccionFile.path);
    }
    else {
      print('No selecciono ninguna imagen');
    }
    Navigator.pop(context);
    refresh();
  }

  void actualizar() async {

    String pin1 = pin1Controlador.text.trim();
    String pin2 = pin2Controlador.text.trim();
    String pin3 = pin3Controlador.text.trim();
    String pin4 = pin4Controlador.text.trim();
    String pin5 = pin5Controlador.text.trim();
    String pin6 = pin6Controlador.text.trim();
    String pin7 = pin7Controlador.text.trim();

    String placas = '$pin1$pin2$pin3-$pin4$pin5$pin6-$pin7';
    String nombreUsuario = nombreUsuarioControlador.text;
    String telefono = telefonoControlador.text.trim();


    if (placas.isEmpty || nombreUsuario.isEmpty || telefono.isEmpty) {
      utils.Snackbar.showSnackbar(context, key, Colors.red, 'Debes rellenar todos los campos.');
      return;
    }

    if(telefono.length < 10){
      utils.Snackbar.showSnackbar(context, key, Colors.red, 'El número de teléfono debe tener 10 digitos.');
      return;
    }

    if (eleccionFile == null) {
      Map<String, dynamic> data = {
        'imagen': taxista?.imagen ?? null,
        'nombreUsuario': nombreUsuario,
        'telefono': telefono,
        'placas': placas
      };

      await _taxistaProvider.actualizar(data, _authProvider.obtenerUsuario().uid);
    } else {
      _progressDialog.show();
      TaskSnapshot snapshot = await _storageProvider.subirArchivo(eleccionFile,taxista.id);
      String imagenUrl = await snapshot.ref.getDownloadURL();

      Map<String, dynamic> data = {
        'imagen': imagenUrl,
        'nombreUsuario': nombreUsuario,
        'telefono': telefono,
        'placas': placas
      };

      await _taxistaProvider.actualizar(data, _authProvider.obtenerUsuario().uid);
      _progressDialog.hide();
    }
    utils.Snackbar.showSnackbar(context, key, Colors.cyan, 'Los datos se actualizaron');
  }

}