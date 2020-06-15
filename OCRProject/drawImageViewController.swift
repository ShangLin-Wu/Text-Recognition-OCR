//
//  drawImageViewController.swift
//  OCRProject
//
//  Created by 吳尚霖 on 6/8/20.
//  Copyright © 2020 SamWu. All rights reserved.
//

import UIKit


struct line {
    var strokeColor : UIColor
    var strokeWidth : Float
    var points : [CGPoint]
}

class drawImageViewController: UIViewController {

    @IBOutlet var canvasView: UIView!

    var didSave: ((UIImage) -> Void)?
    var imageView = UIImageView()
    var inputImg : UIImage!
    let canvas = Canvas()

    required init(inputView:UIImage) {
        super.init(nibName: nil, bundle: nil)
        self.inputImg = inputView
        imageView.image = inputView
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Bundle.main.loadNibNamed("drawImageViewController", owner: self, options: nil)
        canvas.frame = canvasView.frame
        
        self.view.addSubview(canvas)
    }
    
    
    func drawOnImage() -> UIImage{
        UIGraphicsBeginImageContextWithOptions(canvas.frame.size, false, 0.0)
        let context =  UIGraphicsGetCurrentContext()!
        let originalImage = imageView.image!
        originalImage.draw(in: canvas.bounds)
        canvas.lines.forEach { (line) in
            context.setStrokeColor(line.strokeColor.cgColor)
            context.setLineWidth(CGFloat(line.strokeWidth))
            context.setLineCap(.butt)
            context.setBlendMode(.normal)
            
            context.addLines(between: line.points)
            context.strokePath()
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    @IBAction func saveImageBtnClick(_ sender: Any) {
    
        canvas.isUserInteractionEnabled = false
        
        guard let didSave = didSave else { return print("Don't have saveCallback") }
        let drawImg = drawOnImage()
        didSave(drawImg)
        dismiss(animated: true, completion: nil)
        
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        let vc = ViewController()
//        vc.scanImage.image = image
//        vc.modalPresentationStyle = .fullScreen
//        present(vc, animated: true, completion: nil)
            
    }
    
    
    @IBAction func clearLine(_ sender: Any) {
        canvas.clear()
    }
    
    
}

class Canvas: UIView {
    
    var lines = [line]()
    
    var strokeColor = UIColor.white
    var strokeWidth:Float = 5.0
    
    func setStrokeColor(color:UIColor){
           strokeColor = color
       }
       
       func setStrokeWidth(width:Float){
           strokeWidth = width
       }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context =  UIGraphicsGetCurrentContext() else {return}
        lines.forEach { (line) in
            context.setStrokeColor(line.strokeColor.cgColor)
            context.setLineWidth(CGFloat(line.strokeWidth))
            context.setLineCap(.round)
            context.setBlendMode((line.strokeColor == .clear) ?.clear :.normal)
            context.addLines(between: line.points)
            context.strokePath()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //init line struct
        var newLine = line.init(strokeColor: strokeColor, strokeWidth: strokeWidth, points:[])
        
        guard let point = touches.first?.location(in: self ) else { return }
        newLine.points.append(point)
        lines.append(newLine)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let point = touches.first?.location(in: self) else { return }
                    
        guard var lastline = lines.popLast() else { return }
        
        lastline.points.append(point)
        lines.append(lastline)
        
        setNeedsDisplay()
        
    }
    
   @objc func clear(){
    lines.removeAll()
    setNeedsDisplay()
    }
    
    
}
