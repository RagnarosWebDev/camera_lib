import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';


class FilePicker {
  @visibleForTesting
  static const methodChannel = MethodChannel('file_picker');
  static Map<String, Uint8List> items = {};


  static Future<String?> pickDirectory() {
    return methodChannel.invokeMethod<String>('getDirectory');
  }

  static Future<List<Object?>?> getVideos(String path) {
    return methodChannel.invokeMethod<List<Object?>>('getVideos', {
      "path": path
    });
  }

  static Future<Uint8List?> getImageData(String path) async {
    if (items.containsKey(path)) {
      return items[path];
    }
    var res = await methodChannel.invokeMethod<Uint8List>('getImage', {
      "path": path,
    });
    debugPrint('asdasd' + (res != null ? res!.length.toString() : 'asd'));
    items[path] = res!;
    return res;
  }

  static void delete(String path) {
    methodChannel.invokeMethod('delete', {
      "path": path,
    });
  }

  static void share(String path) {
    methodChannel.invokeMethod('share', {
      "path": path,
    });
  }

  static void play(String path) {
    methodChannel.invokeMethod('play', {
      "path": path,
    });
  }
}
