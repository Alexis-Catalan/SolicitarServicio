import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:radio_taxi_alfa_app/src/providers/administrador_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/cliente_provider.dart';
import 'package:radio_taxi_alfa_app/src/providers/taxista_provider.dart';
import 'package:http/http.dart' as http;
import 'package:radio_taxi_alfa_app/src/utils/shared_pref.dart';

class PushNotificacionesProvider {

  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();
  StreamController _streamController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get message => _streamController.stream;

  void initPushNotificaciones() async {

    //ON LAUNCH
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage message){
      if(message != null){
        Map<String, dynamic> data = message.data;
        SharedPref sharedPref = new SharedPref();
        sharedPref.guardar('esNotificacion', 'true');
        _streamController.sink.add(data);
      }
    });

    //ON MESSAGE
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      Map<String, dynamic> data = message.data;

      print('Cuando estamos en primer plano');
      print('OnMessage: $data');
      _streamController.sink.add(data);

    });

    //ON RESUME
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      Map<String, dynamic> data = message.data;
      print('OnResume $data');
      _streamController.sink.add(data);
    });

  }

  void guardarToken(String idUsuario, String tipoUsuario) async {
    String token = await _firebaseMessaging.getToken();
    Map<String, dynamic> data = {
      'token': token
    };

    if (tipoUsuario == 'Cliente') {
      ClienteProvider clienteProvider = new ClienteProvider();
      clienteProvider.actualizar(data, idUsuario);
    } else if(tipoUsuario == 'Taxista') {
      TaxistaProvider taxistaProvider = new TaxistaProvider();
      taxistaProvider.actualizar(data, idUsuario);
    } else if(tipoUsuario == 'Administrador') {
      AdministradorProvider administradorProvider = new AdministradorProvider();
      administradorProvider.actualizar(data, idUsuario);
    }
  }

  Future<void> enviarMensaje(String to, Map<String, dynamic> data, String title, String body) async {
    await http.post(
        'https://fcm.googleapis.com/fcm/send',
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=AAAAoWEPbPo:APA91bF-19w767WcMk1m5mlLWoa6lLDckc03l3oE8rsP6K-6TtsGW2eDeSFza19eAczd3zfegbmkpzTiQEdCara3Q8XKi8NqjRZmn6940HdpC9jWsyC_oArvtr5-dTSOqWbF_bzZ2pdl'
        },
        body: jsonEncode(
            <String, dynamic>{
              'notification': <String, dynamic>{
                'body': body,
                'title': title,
              },
              'priority': 'high',
              'ttl': '4500s',
              'data': data,
              'to': to
            }
        )
    );
  }

  void dispose() {
    _streamController?.onCancel;
  }

}