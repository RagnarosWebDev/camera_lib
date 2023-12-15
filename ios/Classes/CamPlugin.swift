import Flutter
import UIKit
import CoreServices
import UniformTypeIdentifiers
import AVFoundation
import AVKit

@available(iOS 14.0, *)
@objc
public class CamPlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
  var resultGlobal: FlutterResult?

  public static func register(with registrar: FlutterPluginRegistrar) {
      UIApplication.shared.isIdleTimerDisabled = true
    let channel = FlutterMethodChannel(name: "file_picker", binaryMessenger: registrar.messenger())
    let instance = CamPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

      let factory = CamerVieewFactory(messenger: registrar.messenger())
      registrar.register(factory, withId: "plugins/video_view")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      resultGlobal = result
    switch call.method {
    case "getDirectory":
      getDirectory()
    case "getVideos":
        result(getPath())
    case "getImage":
        let args = call.arguments as? Dictionary<String, Any>
        result(FlutterStandardTypedData(bytes: getImage(path: args!["path"] as! String)))
    case "play":
        let args = call.arguments as? Dictionary<String, Any>
        omImageTapped(url: URL(string:args!["path"] as! String)!)
        result(nil)
    case "share":
        let args = call.arguments as? Dictionary<String, Any>
        share(url: URL(string:args!["path"] as! String)!)
        result(nil)
    case "delete":
        let args = call.arguments as? Dictionary<String, Any>
        deleteImage(url: URL(string:args!["path"] as! String)!)
        result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
    
    func omImageTapped(url: URL) {
        let playerViewController = AVPlayerViewController()
        let player = AVPlayer(url: url)
        playerViewController.player = player
        
        UIApplication.shared.keyWindow?.rootViewController!.present(playerViewController, animated: true) {
            player.play()
        }
    }
    
    func share(url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView
        
        UIApplication.shared.keyWindow?.rootViewController!.present(activityViewController, animated: true, completion: nil)
    }
    
    func deleteImage(url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        }
        catch {
            print(error)
        }
    }
    
    public func getImage(path: String) -> Data {
        do {
            let url = URL(string: path)!
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            
            generator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.5, preferredTimescale: 1000)
            let imageRef = try generator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: imageRef)
            
            return uiImage.pngData()!
        }
        catch {
            return Data(bytes: [], count: 1);
        }
    }
    
    
    public func getPath() -> [String] {
        var filesList: [String] = [];
        do{
            var b = true
            let data = UserDefaults.standard.data(forKey: "file")
            var url = try URL(resolvingBookmarkData: data!, bookmarkDataIsStale: &b);
            
            let urls = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [], options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])
            for case var url as URL in urls! {
                let mimeType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType
                
                if (mimeType?.starts(with: "video/") ?? false) {
                    filesList.append(url.absoluteString)
                }
            }
        }
        catch {
            debugPrint(error)
        }
        return filesList;
    }

    public func getDirectory() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeFolder)], in: .open)
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        UIApplication.shared.keyWindow?.rootViewController?.present(documentPicker, animated: true, completion: nil)

    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        do{
            if (!urls.isEmpty && urls[0] != nil) {
                urls[0].startAccessingSecurityScopedResource()
                let data = try urls[0].bookmarkData(includingResourceValuesForKeys: nil, relativeTo: nil)
                UserDefaults.standard.set(data, forKey: "file")
                urls[0].stopAccessingSecurityScopedResource()
                resultGlobal!(urls[0].absoluteString)
                return
            }
        }
        catch {
            debugPrint(error)
            return
        }
        resultGlobal!(nil)
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        resultGlobal!(nil)
    }
}
