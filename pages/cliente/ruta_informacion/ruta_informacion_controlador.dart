import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:radio_taxi_alfa_app/src/api/environment.dart';
import 'package:radio_taxi_alfa_app/src/models/directions.dart';
import 'package:radio_taxi_alfa_app/src/utils/colors.dart' as utils;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:radio_taxi_alfa_app/src/providers/google_provider.dart';

class RutaInformacionControlador {
  BuildContext context;
  Function refresh;

  GlobalKey<ScaffoldState> key = new GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _mapController = Completer();

  CameraPosition initialPosition = CameraPosition(target: LatLng(17.5694024, -99.5181556), zoom: 14.0);

  String origen;
  String destino;
  LatLng origenLatLng;
  LatLng destinoLatLng;

  Set<Polyline> polylines = {};
  List<LatLng> points = new List();

  Map<MarkerId, Marker> marcadores = <MarkerId, Marker>{};

  BitmapDescriptor origenMarcador;
  BitmapDescriptor destinoMarcador;

  GoogleProvider _googleProvider;

  Direction _directions;
  String min;
  String km;

  Future init(BuildContext context, Function refresh) async {
    print('Se Inicio Mapa Informacion Cliente Controlador');
    this.context = context;
    this.refresh = refresh;

    Map<String, dynamic> arguments = ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
    origen = arguments['origen'];
    destino = arguments['destino'];
    origenLatLng = arguments['origenLatLng'];
    destinoLatLng = arguments['destinoLatLng'];

    _googleProvider = new GoogleProvider();

    origenMarcador = await crearMarcadorImagen('assets/img/map_pin_blue.png');
    destinoMarcador = await crearMarcadorImagen('assets/img/map_pin_red.png');
    
    animarCamaraPosicion(origenLatLng.latitude, origenLatLng.longitude);
    getGoogleMapsDirections(origenLatLng, destinoLatLng);
  }

  void getGoogleMapsDirections(LatLng origen, LatLng destino) async {
    _directions = await _googleProvider.getGoogleMapsDirections(
        origen.latitude,
        origen.longitude,
        destino.latitude,
        destino.longitude
    );
    min = _directions.duration.text;
    km = _directions.distance.text;
    refresh();
  }

  void onMapCreated(GoogleMapController controller) async {
    _mapController.complete(controller);
    await setPolylines();
  }

  void Regresar() {
    Navigator.of(context).pop();
  }

  void SolicitarViaje() {
    Navigator.pushNamed(context, 'cliente/solicitud/viaje', arguments: {
      'origen': origen,
      'destino': destino,
      'origenLatLng': origenLatLng,
      'destinoLatLng': destinoLatLng,
    });
  }

  Future<void> setPolylines() async {
    PointLatLng pointOrigenLatLng = PointLatLng(origenLatLng.latitude, origenLatLng.longitude);
    PointLatLng pointDestinoLatLng = PointLatLng(destinoLatLng.latitude, destinoLatLng.longitude);

    PolylineResult result = await PolylinePoints().getRouteBetweenCoordinates(
        Environment.API_KEY_MAPS,
        pointOrigenLatLng,
        pointDestinoLatLng
    );

    for (PointLatLng point in result.points) {
      points.add(LatLng(point.latitude, point.longitude));
    }

    Polyline polyline = Polyline(
        polylineId: PolylineId('poly'),
        color: utils.Colors.temaColor,
        points: points,
        width: 6
    );

    polylines.add(polyline);

    agregarMarcador('origen', origenLatLng.latitude, origenLatLng.longitude, 'Origen', origen, origenMarcador);
    agregarMarcador('destino', destinoLatLng.latitude, destinoLatLng.longitude, 'Destino', destino, destinoMarcador);

    refresh();
  }

  Future animarCamaraPosicion(double latitude, double longitude) async {
    GoogleMapController controller = await _mapController.future;
    if (controller != null) {
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          bearing: 0, target: LatLng(latitude, longitude), zoom: 15)));
    }
  }

  Future<BitmapDescriptor> crearMarcadorImagen(String path) async {
    ImageConfiguration configuration = ImageConfiguration();
    BitmapDescriptor bitmapDescriptor =
    await BitmapDescriptor.fromAssetImage(configuration, path);
    return bitmapDescriptor;
  }

  void agregarMarcador(String marcadorId, double lat, double lng, String titulo, String content, BitmapDescriptor iconMarcador) {
    MarkerId id = MarkerId(marcadorId);
    Marker marcador = Marker(
        markerId: id,
        icon: iconMarcador,
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: titulo, snippet: content),
        );

    marcadores[id] = marcador;
  }
}
