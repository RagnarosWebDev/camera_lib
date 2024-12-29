import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class VideoWidget extends StatefulWidget {
  VideoWidgetController controller;

  VideoWidget(this.controller);

  @override
  State<StatefulWidget> createState() => VideoWidgetState();
}

class VideoWidgetState extends State<VideoWidget> {
  @override
  Widget build(BuildContext context) {
    return buildNativeWidget(context);
  }

  Widget buildNativeWidget(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: 'plugins/video_view',
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
            viewType: 'plugins/video_view',
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
        viewType: 'plugins/video_view', layoutDirection: TextDirection.ltr,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) {
          _onPlatformViewCreated(id);
        });
    }
    throw UnimplementedError();
  }

  void _onPlatformViewCreated(int id) {
    widget.controller.channel = MethodChannel("plugins/video_view_$id");
  }
}

class VideoWidgetController {
  late MethodChannel channel;

  void start(String path, String name) {
    channel.invokeMethod('start', {"path": path, "name": name});
  }

  void stop() {
    channel.invokeMethod('stop');
  }

  void changeCamera() {
    channel.invokeListMethod('changeCamera');
  }

  void focus(double x, double y) {
    channel.invokeListMethod('focus', {'x': x.toInt(), 'y': y.toInt()});
  }
}


