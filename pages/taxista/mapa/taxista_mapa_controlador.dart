import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as ubicacion;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:radio_taxi_alfa_app/src/models/taxista.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radio_taxi_alfa_app/src/providers/auth_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/push_notificaciones_provider.dart';
import 'package:radio_taxi_alfa_app/src/utils/snackbar.dart' as utils;
import 'package:radio_taxi_alfa_app/src/utils/my_progress_dialog.dart';
import 'package:radio_taxi_alfa_app/src/providers/geofire_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/taxista_provider.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;

class TaxistaMapaControlador {
  BuildContext context;
  Function refresh;

  GlobalKey<ScaffoldState> key = new GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _mapController = Completer();

  CameraPosition initialPosition = CameraPosition(
      target: LatLng(17.5694024, -99.5181556), zoom: 14.0);

  AuthProvider _authProvider;
  TaxistaProvider _taxistaProvider;
  GeofireProvider _geofireProvider;
  PushNotificacionesProvider _pushNotificacionesProvider;
  ProgressDialog _progressDialog;

  Taxista taxista;
  Position _posicion;

  BitmapDescriptor marcadorTaxista;

  Map<MarkerId, Marker> marcadores = <MarkerId, Marker>{};

  StreamSubscription<DocumentSnapshot> _taxistaInfoSuscription;
  StreamSubscription<DocumentSnapshot> _statusSuscription;
  StreamSubscription<Position> _posicionStream;

  bool estadoConectarse = false;

  Future init(BuildContext context, Function refresh) async {
    print('Se Inicio Mapa Taxista Controlador');
    this.context = context;
    this.refresh = refresh;
    _authProvider = new AuthProvider();
    _taxistaProvider = new TaxistaProvider();
    _geofireProvider = new GeofireProvider();
    _pushNotificacionesProvider = new PushNotificacionesProvider();
    _progressDialog = MyProgressDialog.createProgressDialog(context, 'Conectandose...');
    marcadorTaxista = await crearMarcadorImagen('assets/img/taxi_icon.png');
    comprobarGPS();
    guardarToken();
    obtenerInfoTaxista();
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);
  }

  void guardarToken(){
    _pushNotificacionesProvider.guardarToken(_authProvider.obtenerUsuario().uid, 'Taxista');
  }

  void obtenerInfoTaxista() {
    Stream<DocumentSnapshot> taxistaStream = _taxistaProvider.obtenerIdStream(_authProvider.obtenerUsuario().uid);
    _taxistaInfoSuscription = taxistaStream.listen((DocumentSnapshot document) {
      taxista = Taxista.fromJson(document.data());
      refresh();
    });
  }

  void abrirDrawer() {
    key.currentState.openDrawer();
  }

  void abrirEditar() {
    Navigator.pushNamed(context, 'taxista/editar');
  }

  void abrirHistorial() {
    Navigator.pushNamed(context, 'taxista/historial');
  }

  void showAlertDialog() {
    Widget btnSi = TextButton(
        onPressed: CerrarSesion,
        child: Text('Si',style: TextStyle(color: utils.Colors.Azul,fontWeight: FontWeight.bold))
    );
    Widget btnNo = TextButton(
        onPressed: ()  => Navigator.pop(context, 'No'),
        child: Text('No',style: TextStyle(color: utils.Colors.Rojo,fontWeight: FontWeight.bold))
    );
    AlertDialog alertDialog = AlertDialog(
      title: Text('Cerrar Sesión',style: TextStyle(color: utils.Colors.degradadoColor)),
      content: Text('¿Está seguro de cerrar sesión?',style: TextStyle(color: utils.Colors.degradadoColor)),
      actions: [
        btnNo,
        btnSi
      ],
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return alertDialog;
        }
    );
  }

  void CerrarSesion() async {
    _geofireProvider.eliminarUbicacion(_authProvider.obtenerUsuario().uid);
    await _authProvider.cerrarSesion();
    Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
  }

  void dispose() {
    _taxistaInfoSuscription?.cancel();
    _posicionStream?.cancel();
    _statusSuscription?.cancel();
  }

  void CentrarPosicion() {
    if (_posicion != null) {
      animarCamaraPosicion(_posicion.latitude, _posicion.longitude);
    } else {
      utils.Snackbar.showSnackbar(context, key,Colors.red, 'Activa el GPS para obtener la posición.');
    }
  }

  void comprobarGPS() async {
    bool activoUbicacion = await Geolocator.isLocationServiceEnabled();
    if (activoUbicacion) {
      print('GPS ACTIVADO');
      actualizarUbicacion();
      comprobarConexion();
    } else {
      print('GPS DESACTIVADO');
      bool ubicacionGPS = await ubicacion.Location().requestService();
      if (ubicacionGPS) {
        actualizarUbicacion();
        comprobarConexion();
        print('ACTIVO EL GPS');
      }
    }
  }

  void actualizarUbicacion() async  {
    try {
      await _determinarPosicion();
      _posicion = await Geolocator.getLastKnownPosition();//Obtener la ultima posicion de la ubicación.
      CentrarPosicion();
      guardarUbicacion();

      agregarMarcador('Taxista', _posicion.latitude, _posicion.longitude, 'Tu posicion', taxista.nombreUsuario, marcadorTaxista);
      refresh();

      _posicionStream = Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.best, distanceFilter: 1).listen((Position position) {
        _posicion = position;
        agregarMarcador('Taxista', _posicion.latitude, _posicion.longitude, 'Tu posicion', taxista.nombreUsuario, marcadorTaxista);
        animarCamaraPosicion(_posicion.latitude, _posicion.longitude);
        guardarUbicacion();
        refresh();
      });
    } catch(error) {
      print('Error en la localización: $error');
    }
  }

  Future<Position> _determinarPosicion() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permantly denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error(
            'Location permissions are denied (actual value: $permission).');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  void comprobarConexion() {
    Stream<DocumentSnapshot> status = _geofireProvider.obtenerUbicacionIdStream(_authProvider.obtenerUsuario().uid);
    _statusSuscription = status.listen((DocumentSnapshot document) {
      if (document.exists) {
        estadoConectarse = true;
      } else {
        estadoConectarse = false;
      }
      refresh();
    });
  }

  void guardarUbicacion() async {
    await _geofireProvider.crearDisponible(_authProvider.obtenerUsuario().uid, _posicion.latitude, _posicion.longitude,_posicion.heading);
    _progressDialog.hide();
  }

  void Conectarse() {
    if (estadoConectarse) {
      desconectarse();
    } else {
      _progressDialog.show();
      actualizarUbicacion();
    }
  }

  void desconectarse() {
    _posicionStream?.cancel();
    _geofireProvider.eliminarUbicacion(_authProvider.obtenerUsuario().uid);
  }

  Future<BitmapDescriptor> crearMarcadorImagen(String path) async {
    ImageConfiguration configuration = ImageConfiguration();
    BitmapDescriptor bitmapDescriptor =
    await BitmapDescriptor.fromAssetImage(configuration, path);
    return bitmapDescriptor;
  }

  Future animarCamaraPosicion(double latitude, double longitude) async {
    GoogleMapController controller = await _mapController.future;
    if (controller != null) {
      controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              bearing: 0,
              target: LatLng(latitude, longitude),
              zoom: 16.8
          )
      ));
    }
  }

  void agregarMarcador (String marcadorId, double lat, double lng, String titulo, String content, BitmapDescriptor iconMarcador) {
    MarkerId id = MarkerId(marcadorId);

    Marker marcador = Marker(
        markerId: id,
        icon: iconMarcador,
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: titulo, snippet: content),
        draggable: false,
        zIndex: 2,
        flat: true,
        anchor: Offset(0.5, 0.5),
        rotation: _posicion.heading
    );

    print(_posicion.heading);
    marcadores[id] = marcador;

  }
}
