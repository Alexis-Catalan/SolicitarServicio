import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as ubicacion;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:radio_taxi_alfa_app/src/models/cliente.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radio_taxi_alfa_app/src/api/environment.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:radio_taxi_alfa_app/src/providers/push_notificaciones_provider.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;
import 'package:radio_taxi_alfa_app/src/providers/auth_provider.dart';
import 'package:radio_taxi_alfa_app/src/utils/snackbar.dart' as utils;
import 'package:radio_taxi_alfa_app/src/providers/cliente_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/geofire_provider.dart';

class ClienteMapaControlador {
  BuildContext context;
  Function refresh;

  GlobalKey<ScaffoldState> key = new GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _mapController = Completer();

  CameraPosition initialPosition = CameraPosition(target: LatLng(17.5694024, -99.5181556), zoom: 14.0);

  AuthProvider _authProvider;
  ClienteProvider _clienteProvider;
  GeofireProvider _geofireProvider;
  PushNotificacionesProvider _pushNotificacionesProvider;

  Cliente cliente;
  Position _posicion;

  BitmapDescriptor marcadorTaxista;

  Map<MarkerId, Marker> marcadores = <MarkerId, Marker>{};

  StreamSubscription<DocumentSnapshot> _clienteInfoSuscription;
  StreamSubscription<List<DocumentSnapshot>> _taxisDisponiblesSuscription;

  String origen;
  String destino;
  LatLng origenLatLng;
  LatLng destinoLatLng;

  places.GoogleMapsPlaces _places = places.GoogleMapsPlaces(apiKey: Environment.API_KEY_MAPS);

  bool estadoSeleccion = true;

  Future init(BuildContext context, Function refresh) async {
    print('Se Inicio Mapa Cliente Controlador');
    this.context = context;
    this.refresh = refresh;
    _authProvider = new AuthProvider();
    _clienteProvider = new ClienteProvider();
    _geofireProvider = new GeofireProvider();
    _pushNotificacionesProvider = new PushNotificacionesProvider();
    marcadorTaxista = await crearMarcadorImagen('assets/img/icon_taxi.png');
    comprobarGPS();
    guardarToken();
    obtenerInfoCliente();
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);
  }

  void guardarToken(){
    _pushNotificacionesProvider.guardarToken(_authProvider.obtenerUsuario().uid, 'Cliente');
  }

  void obtenerInfoCliente() {
    Stream<DocumentSnapshot> clienteStream = _clienteProvider.obtenerIdStream(_authProvider.obtenerUsuario().uid);
    _clienteInfoSuscription = clienteStream.listen((DocumentSnapshot document) {
      cliente = Cliente.fromJson(document.data());
      refresh();
    });
  }

  void abrirDrawer() {
    key.currentState.openDrawer();
  }

  void abrirEditar() {
    Navigator.pushNamed(context, 'cliente/editar');
  }

  void abrirHistorial() {
    Navigator.pushNamed(context, 'cliente/historial');
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
    await _authProvider.cerrarSesion();
    Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
  }

  void dispose() {
    _clienteInfoSuscription?.cancel();
    _taxisDisponiblesSuscription?.cancel();
  }

  Future<Null> showGoogleAutoComplete(bool isFrom) async {
    places.Prediction p = await PlacesAutocomplete.show(
        context: context,
        apiKey: Environment.API_KEY_MAPS,
        language: 'es',
        strictbounds: true,
        radius: 5000,
        location: places.Location(17.5431918, -99.5040298));

    if (p != null) {
      places.PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId, language: 'es');
      double lat = detail.result.geometry.location.lat;
      double lng = detail.result.geometry.location.lng;
      List<Address> address = await Geocoder.local.findAddressesFromQuery(p.description);
      if (address != null) {
        if (address.length > 0) {
          if (detail != null) {
            String calle = detail.result.name;
            String colonia = address[0].subLocality;
            String localidad = address[0].locality;

            if (isFrom) {
              origen = '$calle, $colonia, $localidad';
              origenLatLng = new LatLng(lat, lng);
            } else {
              destino = '$calle, $colonia, $localidad';
              destinoLatLng = new LatLng(lat, lng);
            }
            animarCamaraPosicion(lat, lng);
            refresh();
          }
        }
      }
    }
  }

  void CentrarPosicion() {
    if (_posicion != null) {
      animarCamaraPosicion(_posicion.latitude, _posicion.longitude);
    } else {
      utils.Snackbar.showSnackbar(context, key, Colors.red, 'Activa el GPS para obtener la posición');
    }
  }

  void CambioDireccion() {
    estadoSeleccion = !estadoSeleccion;

    if (estadoSeleccion) {
      utils.Snackbar.showSnackbar(context, key, utils.Colors.origen, 'Estas seleccionando el lugar de Origen.');
    } else {
      utils.Snackbar.showSnackbar(context, key, utils.Colors.destino, 'Estas seleccionando el lugar de Destino.');
    }
    refresh();
  }

  Future<Null> setDireccionDraggableInfo() async {
    if (initialPosition != null) {
      double lat = initialPosition.target.latitude;
      double lng = initialPosition.target.longitude;

      List<Placemark> direccion = await placemarkFromCoordinates(lat, lng);

      if (direccion != null) {
        if (direccion.length > 0) {
          String calle = direccion[0].street;
          String colonia = direccion[0].subLocality;
          String localidad = direccion[0].locality;

          if (estadoSeleccion) {
            origen = '$calle, $colonia, $localidad';
            origenLatLng = new LatLng(lat, lng);
          } else {
            destino = '$calle, $colonia, $localidad';
            destinoLatLng = new LatLng(lat, lng);
          }
          refresh();
        }
      }
    }
  }

  void SolicitarTaxista() {
    if (origenLatLng != null && destinoLatLng != null) {
      Navigator.pushNamed(context, 'cliente/ruta/info', arguments: {
        'origen': origen,
        'destino': destino,
        'origenLatLng': origenLatLng,
        'destinoLatLng': destinoLatLng,
      });
    }
    else {
      utils.Snackbar.showSnackbar(context, key, utils.Colors.Rojo, 'Seleccionar el lugar de Origen y Destino.');
    }
  }

  void comprobarGPS() async {
    bool activoUbicacion = await Geolocator.isLocationServiceEnabled();
    if (activoUbicacion) {
      print('GPS ACTIVADO');
      actualizarUbicacion();
    } else {
      print('GPS DESACTIVADO');
      bool ubicacionGPS = await ubicacion.Location().requestService();
      if (ubicacionGPS) {
        actualizarUbicacion();
        print('ACTIVO EL GPS');
      }
    }
  }

  void actualizarUbicacion() async {
    try {
      await _determinarPosicion();
      _posicion = await Geolocator.getLastKnownPosition();//Obtener la ultima posicion de la ubicacion
      CentrarPosicion();
      obtenerTaxistasCercanos();
    } catch (error) {
      print('Error en la localizacion: $error');
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

  void obtenerTaxistasCercanos() {//Dudas
    Stream<List<DocumentSnapshot>> taxistasStream = _geofireProvider.obtenerTaxistasCercanos(_posicion.latitude, _posicion.longitude, 1);
    _taxisDisponiblesSuscription = taxistasStream.listen((List<DocumentSnapshot> documentList) {

      for (DocumentSnapshot d in documentList) {
        print('DOCUMENT: $d');
      }
      for (MarkerId m in marcadores.keys) {
        bool retirar = true;

        for (DocumentSnapshot d in documentList) {
          if (m.value == d.id) {
            retirar = false;
          }
        }
        if (retirar) {
          marcadores.remove(m);
          refresh();
        }
      }
      for (DocumentSnapshot d in documentList) {
        GeoPoint point = d.data()['posicion']['geopoint'];
        double rotacion = d.data()['rotacion'];
        agregarMarcador(d.id, point.latitude, point.longitude,
            'Taxista disponible', '', marcadorTaxista);
      }
      refresh();
    });
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
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          bearing: 0, target: LatLng(latitude, longitude), zoom: 16.8)));
    }
  }

  void agregarMarcador(String marcadorId, double lat, double lng, String titulo, String content, BitmapDescriptor iconMarcador) {
    MarkerId id = MarkerId(marcadorId);
    Marker marcador = Marker(
        markerId: id,
        icon: iconMarcador,
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: titulo, snippet: content));

    marcadores[id] = marcador;
  }
}
