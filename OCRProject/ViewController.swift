//
//  ViewController.swift
//  OCRProject
//
//  Created by 吳尚霖 on 6/8/20.
//  Copyright © 2020 SamWu. All rights reserved.
//

import UIKit
import Vision
import VisionKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet var tapToWriteBtn: UIButton!
    @IBOutlet var scanImage: UIImageView!
    @IBOutlet var scanText: UILabel!
    @IBOutlet var scanBtn: UIButton!
    private var ocrRequest = VNRecognizeTextRequest(completionHandler: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestAccessCamera()
        
        scanImage.image = UIImage()
        scanImage.layer.borderColor = UIColor.green.cgColor
        scanText.layer.borderColor = UIColor.green.cgColor
        
        processRecognition()
    }
    
    @IBAction func scanBtnClick(_ sender: Any) {
        let vc = VNDocumentCameraViewController()
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func clickToDrawImage(_ sender: Any) {
        
        let paintVC = drawImageViewController(inputView: scanImage.image!)
        paintVC.modalPresentationStyle = .fullScreen
        
        paintVC.didSave = {outputImage in
            DispatchQueue.main.async {
                self.scanImage.image = outputImage
                self.processImage(outputImage)
                self.tapToWriteBtn.isHidden = true
            }
        }
        present(paintVC, animated:true)
    }
    
}

extension ViewController:VNDocumentCameraViewControllerDelegate{
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan){
        
        guard scan.pageCount>0 else {
            controller.dismiss(animated: true, completion: nil)
            return
        }
        
        scanImage.image = scan.imageOfPage(at: scan.pageCount-1)
        controller.dismiss(animated: true, completion: nil)
        processImage(scanImage.image!)
        
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController){
        self.dismiss(animated: true, completion: nil)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error){
        print(error)
    }
    
}

extension ViewController{
    private func requestAccessCamera() -> Bool{
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            return true
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                //request access again
                if granted {
                    
                }
                    
                    //request rejected
                else {
                    let alertController = UIAlertController(title: "開啟失敗", message: "請先開啟相機權限", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                        self.dismiss(animated: true, completion: nil)
                    })
                    
                    // click setting
                    let okAction = UIAlertAction(title: "Setting", style: .default, handler: { _ in
                        let url = URL(string: UIApplication.openSettingsURLString)
                        if let url = url, UIApplication.shared.canOpenURL(url) {
                            if #available(iOS 10, *) {
                                UIApplication.shared.open(url, options: [:],completionHandler: {(success) in })
                            } else {
                                UIApplication.shared.openURL(url)
                            }
                        }
                    })
                    alertController.addAction(cancelAction)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            })
        }
        return false
    }
    
    private func processRecognition(){
        
        //configure request
        ocrRequest.recognitionLevel = .accurate
        ocrRequest.recognitionLanguages = ["en_US"]
        ocrRequest.usesLanguageCorrection = true
        
        
        //sending request when processImage
        ocrRequest = VNRecognizeTextRequest{(request, error) in
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var resultText = ""
            
            for observation in observations{
                
                guard let topCandidate = observation.topCandidates(1).first else { return }
                
                resultText += topCandidate.string + "\n"
            }
            
            
            DispatchQueue.main.async {
                self.scanText.text = resultText
                self.scanBtn.isEnabled = true
            }
        }
    }
    
    private func processImage(_ image:UIImage){
        guard let cgImage = image.cgImage else { return }
        
        scanText.text = ""
        scanBtn.isEnabled = false
        
        let reqHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try reqHandler.perform([self.ocrRequest])
        } catch {
        }
        
    }
}

