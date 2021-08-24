import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GeofireProvider {
  CollectionReference _ref;
  Geoflutterfire _geo;

  GeofireProvider() {
    _ref = FirebaseFirestore.instance.collection('Ubicaciones');
    _geo = Geoflutterfire();
  }

  Future<void> crearDisponible(String id, double lat, double lng, double rotacion) {
    GeoFirePoint miUbicacion = _geo.point(latitude: lat, longitude: lng);
    return _ref.doc(id).set({'status': 'taxistas_disponibles', 'posicion': miUbicacion.data, 'rotacion': rotacion});
  }

  Future<void> crearTrabajando(String id, double lat, double lng) {
    GeoFirePoint myLocation = _geo.point(latitude: lat, longitude: lng);
    return _ref.doc(id).set({'status': 'taxistas_trabajando', 'posicion': myLocation.data});
  }

  Future<void> eliminarUbicacion(String id) {
    return _ref.doc(id).delete();
  }

  Stream<DocumentSnapshot> obtenerUbicacionIdStream(String id) {
    return _ref.doc(id).snapshots(includeMetadataChanges: true);
  }

  Stream<List<DocumentSnapshot>> obtenerTaxistasCercanos(double lat, double lng, double radio) {
    GeoFirePoint puntoCentral = _geo.point(latitude: lat, longitude: lng);
    return _geo.collection(
        collectionRef: _ref.where('status', isEqualTo: 'taxistas_disponibles')
    ).within(center: puntoCentral, radius: radio, field: 'posicion');
  }

}
