import Flutter
import AVFoundation

class CameraView: NSObject, FlutterPlatformView, AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if(error != nil){
            debugPrint(error)
            return
        }
        
                
        debugPrint("startaaa");

    }

    private var _view: UIView
    var captureSession: AVCaptureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var backCamera: AVCaptureDeviceInput?
    var frontCamera: AVCaptureDeviceInput?
    var isFront = false
    var methodChannel: FlutterMethodChannel?
    var output: AVCaptureMovieFileOutput?
    let sessionQueue = DispatchQueue(label: "session queue")

    func getCamera(position: AVCaptureDevice.Position) -> AVCaptureDevice {
        if #available(iOS 13.0, *), let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: position) {
            return device
        }
        else if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: position) {
            return device;
        }
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)!
    }

    init(
            frame: CGRect,
            viewIdentifier viewId: Int64,
            arguments args: Any?,
            binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        methodChannel = FlutterMethodChannel(name: "plugins/video_view_\(viewId)", binaryMessenger: messenger!)


        _view = UIView()

        super.init()
        methodChannel!.setMethodCallHandler(onMethodCall)


        do {
            try backCamera = AVCaptureDeviceInput(device: getCamera(position: .back))
            try frontCamera = AVCaptureDeviceInput(device: getCamera(position: .front))
        } catch { return }

        sessionQueue.async {
            self.setUpView();
        }
    
    }

    func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        
            switch (call.method) {
            case "changeCamera":
                changeCamera()
                result(nil)
            case "focus":
                result(nil)
            case "start":
                if let args = call.arguments as? Dictionary<String, Any> {
                    output = AVCaptureMovieFileOutput()
                    captureSession.addOutput(output!)
                    
                    do {
                        var b = true
                        let data = UserDefaults.standard.data(forKey: "file")
                        var url = try URL(resolvingBookmarkData: data!, bookmarkDataIsStale: &b);
                        let name = args["name"]! as! String;
                    
                        
                        url = url.appendingPathComponent("\(name).mp4");
                        
                        output!.startRecording(to: url, recordingDelegate: self)
                    }
                    catch {
                        result("request")
                        
                    }
                    
                }
                else{
                    result(FlutterMethodNotImplemented)
                }
            case "stop":
                captureSession.beginConfiguration()
                captureSession.removeOutput(output!)
                captureSession.commitConfiguration()
                output!.stopRecording()
                output = nil
                result(nil)
            default:
                debugPrint(call.method);
                result(FlutterMethodNotImplemented)
            }

    }

    func view() -> UIView { _view }

    private func changeCamera(){
        captureSession.beginConfiguration()

        captureSession.removeInput(isFront ? frontCamera!: backCamera!)
        captureSession.addInput(isFront ? backCamera! : frontCamera!)

        captureSession.commitConfiguration()

        isFront = !isFront
    }


    private func setUpView(){
        captureSession.addInput(backCamera!)

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        previewLayer.videoGravity = .resizeAspectFill
        _view.layer.addSublayer(previewLayer)

        do{
            try captureSession.addInput(AVCaptureDeviceInput(device: AVCaptureDevice.default(for: .audio)!))
        }
        catch{
            
        }
        captureSession.startRunning()
    }
}
