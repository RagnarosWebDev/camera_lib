package com.self.cam

import android.annotation.SuppressLint
import android.content.Context
import android.net.Uri
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.Toast
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.FocusMeteringAction
import androidx.camera.core.MeteringPointFactory
import androidx.camera.core.Preview
import androidx.camera.core.SurfaceOrientedMeteringPointFactory
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.*
import androidx.camera.video.VideoCapture
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.documentfile.provider.DocumentFile
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformView

@SuppressLint("ResourceType", "InflateParams")
class VideoView internal constructor(context: Context, id: Int, messenger: BinaryMessenger): PlatformView, MethodCallHandler {
    private val view: View

    private var videoCapture: VideoCapture<Recorder>? = null
    private var recording: Recording? = null
    private var context: Context

    private val methodChannel: MethodChannel
    private var isFrontCamera = true

    init {
        view = LayoutInflater.from(context).inflate(R.layout.video_view, null)

        this.context = context
        startCamera()


        methodChannel = MethodChannel(messenger, "plugins/video_view_$id")
        methodChannel.setMethodCallHandler(this)
    }

    private fun startCamera(){
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)


        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()

            val preview = Preview.Builder()
                .build()
                .also {
                    it.setSurfaceProvider(view.findViewById<PreviewView>(R.id.previewView).surfaceProvider)
                }

            val recorder = Recorder.Builder()
                .setQualitySelector(
                    QualitySelector.from(
                        Quality.HIGHEST,
                        FallbackStrategy.higherQualityOrLowerThan(Quality.SD)
                    )
                )
                .build()

            videoCapture = VideoCapture.withOutput(recorder)
            try {
                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(context as LifecycleOwner, if(isFrontCamera) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA, preview, videoCapture)
            } catch (exc: Exception) {
                Log.e("", "Use case binding failed", exc)
            }
        }, ContextCompat.getMainExecutor(context))
    }

    @SuppressLint("MissingPermission", "Recycle")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when(call.method){
            "start" -> {
                val capture = videoCapture?: return
                val path = call.argument<String>("path")
                val directory = DocumentFile.fromTreeUri(view.context, Uri.parse(path))


                val name = "/" + call.argument<String>("name")
                val file1 = directory!!.createFile("video/mp4", name)
                val pfd = view.context.contentResolver.openFileDescriptor(file1!!.uri, "w")


                val fileOutputOptions = FileDescriptorOutputOptions.Builder(pfd!!).build()
                recording = capture.output
                    .prepareRecording(view.context, fileOutputOptions)
                    .apply {
                        withAudioEnabled()
                    }
                    .start(ContextCompat.getMainExecutor(view.context)) { recordEvent ->
                        when (recordEvent) {
                            is VideoRecordEvent.Start -> {
                                Toast.makeText(view.context, "Запись видео начата", Toast.LENGTH_LONG).show()
                            }
                            is VideoRecordEvent.Finalize -> {
                                Toast.makeText(view.context, if (!recordEvent.hasError()) "Видео записано успешно" else "Ошибка записи видео" , Toast.LENGTH_LONG).show()
                            }
                        }
                    }
            }
            "stop" -> {
                if(recording != null){
                    recording!!.stop()
                    recording = null
                }
            }
            "changeCamera" -> {
                isFrontCamera = !isFrontCamera
                startCamera()
            }
            "focus" -> {
                val x = call.argument<Int>("x")
                val y = call.argument<Int>("y")


                val factory: MeteringPointFactory = SurfaceOrientedMeteringPointFactory(
                    view.width.toFloat(), view.height.toFloat()
                )
                val point = FocusMeteringAction.Builder(
                    factory.createPoint(x!!.toFloat(), y!!.toFloat()),
                    FocusMeteringAction.FLAG_AF
                ).build()

                videoCapture!!.camera!!.cameraControl.startFocusAndMetering(point)
            }
        }
        result.success(null)
    }

    override fun getView(): View {
        return view
    }

    override fun dispose() {}
}