package com.self.cam

import android.app.Activity
import android.content.Intent
import android.content.Intent.FLAG_ACTIVITY_NEW_TASK
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import org.w3c.dom.DocumentType
import java.io.ByteArrayOutputStream
import java.lang.Exception

class CamPlugin : MethodChannel.MethodCallHandler, PluginRegistry.ActivityResultListener,
    FlutterPlugin, ActivityAware {
    private var result: MethodChannel.Result? = null
    private var channel: MethodChannel? = null
    private var activity: Activity? = null

    @RequiresApi(Build.VERSION_CODES.Q)
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        this.result = result
        if (call.method.equals("getDirectory")) {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
            activity!!.startActivityForResult(intent, 1)
        } else if (call.method.equals("getVideos")) {
            Log.println(Log.ERROR, "asdasd", call.argument<String>("path")!!)
            val path = Uri.parse(call.argument<String>("path"))
            val files = DocumentFile.fromTreeUri(activity!!.applicationContext, path)
            if(files == null) {
                result.success(listOf<String>())
                return
            }
            result.success(
                files.listFiles()
                    .filter { it.type != null && it.type!!.startsWith("video/") }.map { it.uri.toString() })
        } else if (call.method.equals("delete")) {
            val path = Uri.parse(call.argument<String>("path"));
            DocumentFile.fromSingleUri(activity!!.applicationContext, path!!)!!.delete()
            result.success(1)
            return;
        } else if (call.method.equals("share")) {
            val path = Uri.parse(call.argument<String>("path"));
            val intent = Intent(
                Intent.ACTION_SEND,
                MediaStore.getMediaUri(activity!!.applicationContext, path!!)
            )
            intent.setFlags(FLAG_ACTIVITY_NEW_TASK);
            activity!!.applicationContext.startActivity(intent)
            result.success(1)
            return;
        } else if (call.method.equals("play")) {
            val path = Uri.parse(call.argument<String>("path"));
            val intent = Intent(
                Intent.ACTION_VIEW,
                MediaStore.getMediaUri(activity!!.applicationContext, path!!)
            )
            intent.setFlags(FLAG_ACTIVITY_NEW_TASK);
            activity!!.applicationContext.startActivity(intent)
            result.success(1)
            return;
        } else if (call.method.equals("getImage")) {
            try {
                val path = Uri.parse(call.argument<String>("path"))
                val mediaMetadataRetriever = MediaMetadataRetriever()
                mediaMetadataRetriever.setDataSource(activity!!.applicationContext, path)
                var image = mediaMetadataRetriever.getFrameAtTime(
                    0,
                    MediaMetadataRetriever.OPTION_CLOSEST
                )

                image = Bitmap.createScaledBitmap(image!!, image.width / 2, image.height / 2, false)

                val stream = ByteArrayOutputStream()
                image!!.compress(Bitmap.CompressFormat.PNG, 100, stream)
                image.recycle();


                result.success(stream.toByteArray())
                stream.close()
                mediaMetadataRetriever.close()
            }
            catch (_: Exception) {
                result.success(null)
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (resultCode != Activity.RESULT_OK) {
            result!!.success(null)
            return false
        }
        val uri: Uri = data!!.data!!
        activity!!.contentResolver.takePersistableUriPermission(
            uri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        )
        result!!.success(uri.toString())
        return false
    }


    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "file_picker")
        channel!!.setMethodCallHandler(this)

        binding.platformViewRegistry
            .registerViewFactory(
                "plugins/video_view",
                VideoViewFactory(binding.binaryMessenger)
            )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel!!.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {}
}