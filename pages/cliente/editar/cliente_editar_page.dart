import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:radio_taxi_alfa_app/src/widgets/button_app.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:radio_taxi_alfa_app/src/pages/cliente/editar/cliente_editar_controlador.dart';

class ClienteEditarPage extends StatefulWidget {
  @override
  _ClienteEditarPageState createState() => _ClienteEditarPageState();
}

class _ClienteEditarPageState extends State<ClienteEditarPage> {
  ClienteEditarControlador _con = new ClienteEditarControlador();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _con.init(context, refresh);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _con.key,
      appBar: AppBar(
        brightness: Brightness.dark,
        elevation: 0,
        centerTitle: true,
        title: Text('Editar Perfil'),
      ),
      bottomNavigationBar: _btnActualizar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _appEncabezado(),
            _txtEditar(),
            _edtCampoNombreUsuario(),
            _edtCampoTelefono()
          ],
        ),
      ),
    );
  }

  Widget _appEncabezado() {
    return ClipPath(
      clipper: WaveClipperTwo(),
      child: Container(
        color: utils.Colors.temaColor,
        height: MediaQuery.of(context).size.height * 0.22,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: _con.showAlertDialog,
              child: Container(
                width: 120,
                height: 120,
                child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(100)),
                    child: _getImage(_con.imagenFile?.path)
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 30),
              child: Text(
                _con.cliente?.correo ?? 'correo@dominio.com',
                style: TextStyle(
                    fontFamily: 'Pacifico',
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _getImage(String picture) {
    if (picture == null) {
      return Image(
        image: AssetImage('assets/img/profile.jpg'),
        fit: BoxFit.cover,
      );
    }

    if (picture.startsWith('https')) {
      return FadeInImage(
        image: NetworkImage(picture),
        placeholder: AssetImage('assets/img/profile.jpg'),
        fit: BoxFit.cover,
      );
    }

    return Image.file(
      File(picture),
      fit: BoxFit.cover,
    );
  }

  Widget _txtEditar() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Text(
        'Editar perfil',
        style: TextStyle(
            color: utils.Colors.degradadoColor,
            fontWeight: FontWeight.bold,
            fontSize: 25),
      ),
    );
  }

  Widget _edtCampoNombreUsuario() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: TextField(
        controller: _con.nombreUsuarioControlador,
        cursorColor: utils.Colors.temaColor,
        decoration: InputDecoration(
            hintText: 'Nombre(s) Apellidos',
            labelText: 'Nombre de usuario:',
            suffixIcon: Icon(
              Icons.person,
              color: utils.Colors.temaColor,
            )),
      ),
    );
  }

  Widget _edtCampoTelefono() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: TextField(
        controller: _con.telefonoControlador,
        cursorColor: utils.Colors.temaColor,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        decoration: InputDecoration(
            hintText: 'Tel??fono',
            labelText: 'N??mero de tel??fono:',
            suffixIcon: Icon(
              Icons.phone,
              color: utils.Colors.temaColor,
            )),
      ),
    );
  }

  Widget _btnActualizar() {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 30, vertical: 25),
      child: ButtonApp(
        onPressed: _con.actualizar,
        text: 'Actualizar ahora',
        icon: Icons.update,
      ),
    );
  }

  void refresh() {
    setState(() {});
  }
}
