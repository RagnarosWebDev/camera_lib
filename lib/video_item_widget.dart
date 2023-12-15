import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class VideoItemWidget extends StatefulWidget {
  String path;
  int size;
  VideoItemWidgetController controller;

  VideoItemWidget(this.path, this.controller, this.size);

  @override
  State<StatefulWidget> createState() => VideoItemWidgetState();
}

class VideoItemWidgetState extends State<VideoItemWidget> {
  int currentWidth = 0;

  @override
  Widget build(BuildContext context) {
    return buildNativeWidget(context);
  }

  Widget buildNativeWidget(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: 'plugins/video_item_view',
        surfaceFactory: (BuildContext context,
            PlatformViewController controller,) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <
                Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          final AndroidViewController controller =
          PlatformViewsService.initExpensiveAndroidView(
            id: params.id,
            viewType: 'plugins/video_item_view',
            layoutDirection: TextDirection.ltr,
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () => params.onFocusChanged(true),
          );
          controller.addOnPlatformViewCreatedListener(
            params.onPlatformViewCreated,
          );
          controller.addOnPlatformViewCreatedListener(
            _onPlatformViewCreated,
          );

          return controller;
        },
      );
    }
    else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
          viewType: 'plugins/video_item_view',
          layoutDirection: TextDirection.ltr,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: (id) {
            _onPlatformViewCreated(id);
          });
    }
    throw UnimplementedError();
  }

  void _onPlatformViewCreated(int id) {
    widget.controller.channel = MethodChannel("plugins/video_item_view_$id");

    widget.controller.channel.invokeMethod('load', {"file": widget.path}).then((
        value) =>
    {
      debugPrint("khgkhgk: " + value.toString())
    });
  }
}

class VideoItemWidgetController {
  late MethodChannel channel;
  void Function() onDelete;

  VideoItemWidgetController(this.onDelete);

  void play() {
    channel.invokeMethod('play');
  }

  void share() {
    debugPrint(channel.toString());
    channel.invokeMethod("share");
  }

  void delete() {
    channel.invokeMethod("delete").
    then((value) => onDelete());
  }
}
