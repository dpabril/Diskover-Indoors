//
//  QRCodeScannerController.swift
//  CS 198 Final
//
//  Created by Abril & Aquino on 11/12/2018.
//  Copyright © 2018 Abril & Aquino. All rights reserved.
//

import UIKit
import SceneKit
import Foundation
import AVFoundation
import GRDB

class QRCodeScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var captureFrame: UIImageView!
    
    var captureSession = AVCaptureSession()
    
    var videoPreviewLayer : AVCaptureVideoPreviewLayer?
    var qrCodeFrameView : UIView?
    var qrCodeFrameThreshold : CGSize?
    
    var floorPlanTexture : UIImage!
    var locs : [IndoorLocation] = []
    var rooms : [String] = []
    
    private let supportedCodeTypes = [AVMetadataObject.ObjectType.qr]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the back-facing camera for capturing videos
        var deviceDiscoverySession : AVCaptureDevice.DiscoverySession
        
        if (AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDualCamera, for: AVMediaType.video, position: AVCaptureDevice.Position.back) != nil) {
            deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .back)
        } else {
            deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        }
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("ERROR: No compatible camera device found.")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            
        } catch {
            print(error)
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        // Start video capture.
        // captureSession.startRunning()
        
        // Move the message label and top bar to the front
        messageLabel.layer.cornerRadius = 5
        view.bringSubviewToFront(messageLabel)
        view.bringSubviewToFront(captureFrame)
        
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        // Initialize QR code frame size threshold for reference to enforce min. distance
        qrCodeFrameThreshold = CGSize.init(width: 100.0, height: 100.0)
        
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        captureSession.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        captureSession.stopRunning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Helper methods
    
    func launchNavigator(decodedURL: String) {
        
        if presentedViewController != nil {
            return
        }
        
        let alertPrompt = UIAlertController(title: "Localization successful.", message: decodedURL, preferredStyle: .actionSheet)
        let confirmAction = UIAlertAction(title: "Navigate!", style: UIAlertAction.Style.default, handler: { (action) -> Void in
            self.tabBarController!.tabBar.items![1].isEnabled = true
            self.tabBarController!.tabBar.items![2].isEnabled = true
            self.tabBarController!.selectedIndex = 2
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
        
        alertPrompt.addAction(confirmAction)
        alertPrompt.addAction(cancelAction)
        
        present(alertPrompt, animated: true, completion: nil)
    }
    
    func sizePassesThreshold(_ qrCodeFrameSize: CGSize) -> Bool {
        return (qrCodeFrameSize.width >= (qrCodeFrameThreshold?.width)! && qrCodeFrameSize.height >= qrCodeFrameThreshold!.height)
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No QR Code detected."
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata (or barcode) then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil && sizePassesThreshold((qrCodeFrameView?.frame.size)!){
                let qrCodeURL = metadataObj.stringValue!
                let qrCodeFragments = qrCodeURL.components(separatedBy: "::")
                let qrCodeBuilding = qrCodeFragments[0]
                let qrCodeFloorLevel = Int(qrCodeFragments[1])!
                let qrCodeFloorPoint = qrCodeFragments[2]
                
                var qrTag : QRTag?
                var building : Building?
                var floor : Floor?
                do {
                    try DB.write { db in
                        qrTag = try QRTag.fetchOne(db, "SELECT * FROM QRTag WHERE url = ?", arguments: [qrCodeURL])
                        building = try Building.fetchOne(db, "SELECT * FROM Building WHERE alias = ?", arguments: [qrCodeBuilding])
                        floor = try Floor.fetchOne(db, "SELECT * FROM Floor WHERE bldg = ? AND level = ?", arguments: [qrCodeBuilding, qrCodeFloorLevel])
                    }
                } catch {
                    print(error)
                }
                
                messageLabel.text = qrCodeURL
                launchNavigator(decodedURL: "You are in the \(Utilities.ordinalize(floor!.level)) Floor of \(building!.name), at Point \(qrCodeFloorPoint) <\(qrTag!.url)>.")
                
                do {
                    try DB.write { db in
                        locs = try IndoorLocation.fetchAll(db, "SELECT * FROM IndoorLocation WHERE bldg = ? AND level = ?", arguments: [qrCodeBuilding, qrCodeFloorLevel])
                        // locs = try IndoorLocation.fetchAll(db, "SELECT * FROM IndoorLocation WHERE bldg = ?", arguments: [qrCodeBuilding])
                    }
                } catch {
                    print(error)
                }
                
                rooms = []
                
                for loc in locs {
                    rooms.append(loc.name)
                }
                
                let imagePath = Bundle.main.path(forResource: String(qrCodeFloorLevel), ofType: "png", inDirectory: "Textures.scnassets/UP AECH")!
                floorPlanTexture = UIImage(named: imagePath)!
                
            } else if metadataObj.stringValue != nil {
                messageLabel.text = "Step closer to scan QR code"
            }
        }
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
