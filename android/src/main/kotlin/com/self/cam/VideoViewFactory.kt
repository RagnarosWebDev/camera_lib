package com.self.cam

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class VideoViewFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(
    StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, id: Int, o: Any?): PlatformView {
        return VideoView(context = context, id = id, messenger = messenger)
    }
}