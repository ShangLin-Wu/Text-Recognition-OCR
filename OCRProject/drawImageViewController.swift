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

class drawImageViewController: UIViewController, CanvasDelegate {

    @IBOutlet var canvasView: UIView!
    @IBOutlet var writeSegment: UISegmentedControl!

    var didSave: ((UIImage) -> Void)?
    var imageView = UIImageView()
    var canvas = Canvas()

    required init(inputView:UIImage) {
        super.init(nibName: nil, bundle: nil)
        imageView.image = inputView
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Bundle.main.loadNibNamed("drawImageViewController", owner: self, options: nil)
        
        canvas.delegate = self
        canvas.clipsToBounds = true
        canvas.layer.cornerRadius = 10
        canvas.frame = canvasView.frame
        
        self.view.addSubview(canvas)
        
        writeSegment.selectedSegmentIndex = 0
        
    }
    
    func beganDrawing() {
        writeSegment.isUserInteractionEnabled = false
        writeSegment.backgroundColor = .darkGray
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
        if(writeSegment.selectedSegmentIndex == 0){
            return image
        }
        else
        {
            return image.rotate(radians: .pi/2)!
        }
        

    }
    
    @IBAction func saveImageBtnClick(_ sender: Any) {
    
        canvas.isUserInteractionEnabled = false
        
        guard let didSave = didSave else { return print("Don't have saveCallback") }
        let drawImg = drawOnImage()
        didSave(drawImg)
        dismiss(animated: true, completion: nil)
        
    }
    
    
    @IBAction func clearLine(_ sender: Any) {
        canvas.removeFromSuperview()
        canvas = Canvas()
        canvas.delegate = self
        canvas.clipsToBounds = true
        canvas.layer.cornerRadius = 10
        canvas.frame = canvasView.frame
        
        self.view.addSubview(canvas)
        writeSegment.backgroundColor = .systemTeal
        writeSegment.isUserInteractionEnabled = true
    }
    
    
}

protocol CanvasDelegate {
    func beganDrawing();
}

class Canvas: UIView {
    
    var delegate:CanvasDelegate?
    
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
        
        delegate?.beganDrawing()
        
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
    
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
