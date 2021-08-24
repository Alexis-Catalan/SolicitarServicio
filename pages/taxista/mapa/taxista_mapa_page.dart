import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radio_taxi_alfa_app/src/widgets/button_app.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;
import 'package:radio_taxi_alfa_app/src/pages/taxista/mapa/taxista_mapa_controlador.dart';

class TaxistaMapaPage extends StatefulWidget {
  @override
  _TaxistaMapaPageState createState() => _TaxistaMapaPageState();
}

class _TaxistaMapaPageState extends State<TaxistaMapaPage> {
  TaxistaMapaControlador _con = new TaxistaMapaControlador();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _con.init(context, refresh);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    print('SE EJECUTO EL DISPOSE MAPA TAXISTA');
    _con.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _con.key,
        drawer: _drawer(),
        body: Stack(
          children: [
            _googleMapsWidget(),
            SafeArea(
                child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_btnDrawer(), _btnPosicionCentral()],
                ),
                Expanded(child: Container()),
                _btnConectarse()
              ],
            ))
          ],
        ));
  }

  Widget _googleMapsWidget() {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _con.initialPosition,
      onMapCreated: _con.onMapCreated,
      markers: Set<Marker>.of(_con.marcadores.values),
      mapToolbarEnabled: false,
    );
  }

  Widget _drawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 270,
            child: DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      backgroundImage: _con.taxista?.imagen != null
                          ? NetworkImage(_con.taxista?.imagen)
                          : AssetImage('assets/img/profile.jpg'),
                      radius: 45,
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Container(
                      child: Text(
                        _con.taxista?.nombreUsuario ?? 'Nombre de usuario',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      child: Text(
                        _con.taxista?.correo ?? 'correo@dominio.com',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      child: Text(
                        _con.taxista?.telefono ?? '7474747474',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      child: Text(
                        _con.taxista?.placas ?? 'AAA-123-A',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
              decoration: BoxDecoration(color: utils.Colors.temaColor),
            ),
          ),
          ListTile(
            title: Text('Editar perfil'),
            leading: Icon(Icons.edit_outlined, color: utils.Colors.Azul),
            onTap: _con.abrirEditar,
          ),
          ListTile(
            title: Text('Historial de viajes'),
            leading: Icon(Icons.history,color: utils.Colors.temaColor),
            onTap: _con.abrirHistorial,
          ),
          ListTile(
            title: Text('Cerrar sesión'),
            leading: Icon(
              Icons.logout,
              color: utils.Colors.Rojo,
            ),
            onTap: _con.showAlertDialog,
          ),
        ],
      ),
    );
  }

  Widget _btnDrawer() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.all(0),
      child: IconButton(
        onPressed: _con.abrirDrawer,
        icon: Icon(
          Icons.menu,
          color: utils.Colors.degradadoColor,
        ),
      ),
    );
  }

  Widget _btnPosicionCentral() {
    return GestureDetector(
      onTap: _con.CentrarPosicion,
      child: Container(
        alignment: Alignment.centerRight,
        margin: EdgeInsets.symmetric(horizontal: 10),
        child: Card(
          shape: CircleBorder(),
          color: Colors.white,
          elevation: 5.0,
          child: Container(
            padding: EdgeInsets.all(12),
            child: Icon(
              Icons.my_location,
              color: utils.Colors.azul,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _btnConectarse() {
    return Container(
      height: 50,
      alignment: Alignment.bottomCenter,
      margin: EdgeInsets.symmetric(horizontal: 60, vertical: 30),
      child: ButtonApp(
        onPressed: _con.Conectarse,
        text: _con.estadoConectarse ? 'DESCONECTARSE' : 'CONECTARSE',
        color: _con.estadoConectarse
            ? utils.Colors.conRojo
            : utils.Colors.conVerde,
        icon: _con.estadoConectarse ? Icons.location_off : Icons.location_on,
        iconColor: _con.estadoConectarse
            ? utils.Colors.conRojo
            : utils.Colors.conVerde,
      ),
    );
  }

  void refresh() {
    setState(() {});
  }
}
