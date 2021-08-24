import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radio_taxi_alfa_app/src/widgets/button_app.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;
import 'package:radio_taxi_alfa_app/src/pages/cliente/ruta_informacion/ruta_informacion_controlador.dart';

class RutaInformacionPage extends StatefulWidget {
  @override
  _RutaInformacionPageState createState() => _RutaInformacionPageState();
}

class _RutaInformacionPageState extends State<RutaInformacionPage> {
  RutaInformacionControlador _con = new RutaInformacionControlador();

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
      body: Stack(
        children: [
          Align(
            child: _googleMapsWidget(),
            alignment: Alignment.topCenter,
          ),
          Align(
            child: _cardInformacionViaje(),
            alignment: Alignment.bottomCenter,
          ),
          Align(
            child: _btnRegregar(),
            alignment: Alignment.topLeft,
          ),
          Align(
            child: _cardKmInfo(_con.km ?? '0 km'),
            alignment: Alignment.topRight,
          )
        ],
      ),
    );
  }

  Widget _googleMapsWidget() {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _con.initialPosition,
      onMapCreated: _con.onMapCreated,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      markers: Set<Marker>.of(_con.marcadores.values),
      polylines: _con.polylines,
    );
  }

  Widget _btnRegregar() {
    return SafeArea(
      child: GestureDetector(
        onTap: _con.Regresar,
        child: Container(
          margin: EdgeInsets.only(left: 10),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: utils.Colors.degradadoColor,
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardInformacionViaje() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Container(
        margin: EdgeInsets.only(left: 0, top: 5 , right: 0, bottom: 0),
        child: Column(
          children: [
            ListTile(
              title: Text(
                'Origen',
                style: TextStyle(fontSize: 15),
              ),
              subtitle: Text(
                _con.origen ?? 'Dirección de Origen' ,
                maxLines: 2,
                style: TextStyle(fontSize: 13),
              ),
              leading: Icon(Icons.my_location, color: utils.Colors.origen),
            ),
            ListTile(
              title: Text(
                'Destino',
                style: TextStyle(fontSize: 15),
              ),
              subtitle: Text(
                _con.destino ?? 'Dirección de Destino',
                maxLines: 2,
                style: TextStyle(fontSize: 13),
              ),
              leading: Icon(
                Icons.location_on,
                color: utils.Colors.destino,
              ),
            ),
            ListTile(
              title: Text(
                'Tiempo',
                style: TextStyle(fontSize: 15),
              ),
              subtitle: Text(
                _con.min ?? '0 min',
                style: TextStyle(fontSize: 13),
                maxLines: 1,
              ),
              leading: Icon(Icons.watch_later, color: Colors.black),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 30),
              child: ButtonApp(
                onPressed: _con.SolicitarViaje,
                text: 'CONFIRMAR',
                icon: Icons.local_taxi,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _cardKmInfo(String km) {
    return SafeArea(
        child: Container(
      width: 120,
      padding: EdgeInsets.symmetric(horizontal: 30),
      margin: EdgeInsets.only(right: 10, top: 10),
      decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.all(Radius.circular(20))),
      child: Text(
        '$km Km'  ?? '0 Km',
        maxLines: 1,
      ),
    ));
  }

  void refresh() {
    setState(() {});
  }
}
