import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class StorageProvider {

  Future<TaskSnapshot> subirArchivo(PickedFile file,idUsuario) async {
    String name = '${idUsuario}.jpg';

    Reference ref = FirebaseStorage.instance.ref().child('images').child('/$name');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'picked-file-path': file.path}
    );

    UploadTask uploadTask = ref.putFile(File(file.path), metadata);
    return uploadTask;
  }

}