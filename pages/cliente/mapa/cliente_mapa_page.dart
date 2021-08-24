import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radio_taxi_alfa_app/src/widgets/button_app.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;
import 'package:radio_taxi_alfa_app/src/pages/cliente/mapa/cliente_mapa_controlador.dart';

class ClienteMapaPage extends StatefulWidget {
  @override
  _ClienteMapaPageState createState() => _ClienteMapaPageState();
}

class _ClienteMapaPageState extends State<ClienteMapaPage> {
  ClienteMapaControlador _con = new ClienteMapaControlador();

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
    print('SE EJECUTO EL DISPOSE MAPA CLIENTE');
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
                  _btnDrawer(),
                  _buscadorGooglePlaces(),
                  _btnPosicionCentral(),
                  _btnCambiarDireccion(),
                  Expanded(child: Container()),
                  _btnSolicitar()
                ],
              ),
            ),
            Align(alignment: Alignment.center, child: _iconMiUbicacion())
          ],
        ));
  }

  Widget _googleMapsWidget() {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _con.initialPosition,
      onMapCreated: _con.onMapCreated,
      markers: Set<Marker>.of(_con.marcadores.values),
      onCameraMove: (position) {
        _con.initialPosition = position;
      },
      onCameraIdle: () async {
        await _con.setDireccionDraggableInfo();
      },
      mapToolbarEnabled: false,
    );
  }

  Widget _iconMiUbicacion() {
    return Image.asset(
      'assets/img/my_location.png',
      width: 40,
      height: 46,
    );
  }

  Widget _drawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 260,
            child: DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      backgroundImage: _con.cliente?.imagen != null
                          ? NetworkImage(_con.cliente?.imagen)
                          : AssetImage('assets/img/profile.jpg'),
                      radius: 45,
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Container(
                      child: Text(
                        _con.cliente?.nombreUsuario ?? 'Nombre de usuario',
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
                        _con.cliente?.correo ?? 'Correo electrónico',
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
                        _con.cliente?.telefono ?? '7474747474',
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

  Widget _buscadorGooglePlaces() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.94,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoCardLocation('Origen:', _con.origen ?? 'Lugar de Origen',
                  utils.Colors.origen, () async {
                    await _con.showGoogleAutoComplete(true);
                  }),
              SizedBox(height: 5),
              Container(
                // width: double.infinity,
                  child: Divider(color: utils.Colors.temaColor, height: 10)),
              SizedBox(height: 5),
              _infoCardLocation('Destino:', _con.destino ?? 'Lugar de Destino',
                  utils.Colors.destino, () async {
                    await _con.showGoogleAutoComplete(false);
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCardLocation(String title, String value, Color color, Function function) {
    return GestureDetector(
      onTap: function,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.start,
          ),
          Text(
            value,
            style: TextStyle(
                color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _btnPosicionCentral() {
    return GestureDetector(
      onTap: _con.CentrarPosicion,
      child: Container(
        alignment: Alignment.centerRight,
        margin: EdgeInsets.symmetric(horizontal: 18),
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

  Widget _btnCambiarDireccion() {
    return GestureDetector(
      onTap: _con.CambioDireccion,
      child: Container(
        alignment: Alignment.centerRight,
        margin: EdgeInsets.symmetric(horizontal: 18),
        child: Card(
          shape: CircleBorder(),
          color:
          _con.estadoSeleccion ? utils.Colors.origen : utils.Colors.destino,
          elevation: 5.0,
          child: Container(
            padding: EdgeInsets.all(12),
            child: Icon(
              Icons.directions,
              color: Colors.white,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _btnSolicitar() {
    return Container(
      height: 50,
      alignment: Alignment.bottomCenter,
      margin: EdgeInsets.symmetric(horizontal: 60, vertical: 30),
      child: ButtonApp(
        onPressed: _con.SolicitarTaxista,
        text: 'SOLICITAR',
        icon: Icons.hail,
      ),
    );
  }

  void refresh() {
    setState(() {});
  }
}
