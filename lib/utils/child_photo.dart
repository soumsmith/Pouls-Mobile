import 'dart:io';
import 'package:flutter/widgets.dart';

/// `Child.photoUrl` peut désormais être soit une URL distante (ancien
/// chemin legacy, publique et directement affichable), soit un chemin de
/// fichier local (photo téléchargée et mise en cache depuis l'API de
/// consultation, dont l'endpoint est protégé par un Bearer token
/// incompatible avec un simple widget réseau). On distingue les deux par la
/// présence d'un schéma http(s) — jamais présent dans un chemin de fichier.
bool isLocalChildPhotoPath(String photoUrl) =>
    !photoUrl.startsWith('http://') && !photoUrl.startsWith('https://');

/// [ImageProvider] correspondant, pour les widgets qui acceptent un
/// provider générique (`Image(image: ...)`, `CircleAvatar.backgroundImage`).
ImageProvider childPhotoProvider(String photoUrl) {
  if (isLocalChildPhotoPath(photoUrl)) {
    return FileImage(File(photoUrl));
  }
  return NetworkImage(photoUrl);
}
