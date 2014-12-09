//
//  KenBurnsView.swift
//  KenBurnsSlideshowView-Demo
//
//  Created by Ryo Aoyama on 12/1/14.
//  Copyright (c) 2014 Ryo Aoyama. All rights reserved.
//

import UIKit

class KenBurnsView: UIView {
    
    enum kenBurnsViewZoomCourse: Int {
        case Random = 0
        case ToLowerLeft = 1
        case ToLowerRight = 2
        case ToUpperLeft = 3
        case ToUpperRight = 4
    }
    
    enum kenBurnsViewState {
        case Animating
        case Invalid
        case Pausing
    }
    
    private enum kenBurnsViewStartZoomPoint {
        case LowerLeft
        case LowerRight
        case UpperLeft
        case UpperRight
    }
    
    private var imageView: UIImageView!
    private var wholeImageView: UIImageView!
    
    var image: UIImage? {
        set {
            let duration = self.imageView.image == nil ? 0.7 : 0
            self.imageView.image = newValue
            self.wholeImageView.image = newValue
            UIView.animateWithDuration(duration, delay: 0, options: .BeginFromCurrentState | .CurveEaseInOut, animations: { () -> Void in
                self.alpha = 0
                self.alpha = 1.0
                }, completion: nil)
            
            if newValue != nil {
                self.setUpImageViewRect(newValue)
                self.setUpTransform()
                self.startMotion()
            }
        }
        get {
            return self.imageView.image
        }
    }
    
    var zoomCourse: kenBurnsViewZoomCourse = .Random
    var startZoomRate: CGFloat = 1.2 {
        didSet {
            self.updateMotion()
        }
    }
    var endZoomRate: CGFloat = 1.4 {
        didSet {
            self.updateMotion()
        }
    }
    var animationDuration: CGFloat = 15.0 {
        didSet {
            self.updateMotion()
        }
    }
    var padding: UIEdgeInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0) {
        didSet {
            self.updateMotion()
        }
    }
    
    private (set) var state: kenBurnsViewState = .Invalid
    
    private var startTransform: CGAffineTransform = CGAffineTransformIdentity
    private var endTransform: CGAffineTransform = CGAffineTransformIdentity
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureView()
    }
    
    func startMotion() {
        let current = CAShapeLayer()
        
        let transX = CABasicAnimation(keyPath: "transform.translation.x")
        transX.fromValue = self.startTransform.tx
        transX.toValue = self.endTransform.tx
        
        let transY = CABasicAnimation(keyPath: "transform.translation.y")
        transY.fromValue = self.startTransform.ty
        transY.toValue = self.endTransform.ty
        
        let scaleX = CABasicAnimation(keyPath: "transform.scale.x")
        scaleX.fromValue = self.startTransform.a
        scaleX.toValue = self.endTransform.a
        
        let scaleY = CABasicAnimation(keyPath: "transform.scale.y")
        scaleY.fromValue = self.startTransform.d
        scaleY.toValue = self.endTransform.d
        
        let group = CAAnimationGroup()
        group.repeatCount = Float.infinity
        group.autoreverses = true
        group.duration = CFTimeInterval(self.animationDuration)
        group.removedOnCompletion = false
        group.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        group.animations = [transX, transY, scaleX, scaleY]
        
        self.imageView.layer.addAnimation(group, forKey: "kenBurnsAnimation")
        self.state = .Animating 
    }
    
    func updateMotion() {
        self.setUpTransform()
        self.startMotion()
    }
    
    func invalidateMotion() {
        self.imageView.layer.removeAllAnimations()
        self.imageView.transform = CGAffineTransformIdentity
        self.state = .Invalid
    }
    
    func pauseMotion() {
        if self.state == .Animating {
            let pausedTime: CFTimeInterval = self.imageView.layer .convertTime(CACurrentMediaTime(), fromLayer: nil)
            self.imageView.layer.speed = 0
            self.imageView.layer.timeOffset = pausedTime
            self.state = .Pausing
        }
    }
    
    func resumeMotion() {
        if self.state == .Pausing {
            let pausedTime: CFTimeInterval = self.imageView.layer.timeOffset
            self.imageView.layer.speed = 1.0
            self.imageView.layer.beginTime = 0
            self.imageView.layer.timeOffset = 0
            let intervalSincePaused: CFTimeInterval = self.imageView.layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
            self.imageView.layer.beginTime = intervalSincePaused
            self.state = .Animating
        }
    }
    
    func showWholeImage() {
        self.pauseMotion()
        
        let layer: AnyObject? = self.imageView.layer.presentationLayer()
        self.wholeImageView.frame = layer!.frame
        self.wholeImageView.hidden = false
        self.imageView.hidden = true
        
        let size = self.bounds.size
        let imageSize = self.imageView.bounds.size
        let widthRatio = size.width / imageSize.width
        let heightRatio = size.height / imageSize.height
        var rate: CGFloat = min(widthRatio, heightRatio)
        let resizedSize = CGSizeMake(imageSize.width * rate, imageSize.height * rate)
        
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveLinear, animations: { () -> Void in
            self.wholeImageView.frame.size = resizedSize
            self.wholeImageView.center = self.center
        }, completion: nil)
    }
    
    func zoomImageAndRestartMotion() {
        let layer: AnyObject? = self.imageView.layer.presentationLayer()
        
        UIView.animateWithDuration(0.3, delay: 0, options: .BeginFromCurrentState | .CurveEaseIn, animations: { () -> Void in
            self.wholeImageView.frame = layer!.frame
        }) { (finished) -> Void in
            self.imageView.hidden = false
            self.wholeImageView.hidden = true
            self.wholeImageView.frame = CGRectZero
            self.resumeMotion()
        }
    }
    
    private func configureView() {
        self.clipsToBounds = true
        self.backgroundColor = UIColor.blackColor()
        
        self.imageView = UIImageView(frame: self.bounds)
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.imageView.contentMode = UIViewContentMode.ScaleAspectFit
//        self.imageView.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        self.imageView.clipsToBounds = true
        self.insertSubview(self.imageView, atIndex: 0)
        
        self.wholeImageView = UIImageView()
        self.wholeImageView.contentMode = .ScaleAspectFill
        self.wholeImageView.clipsToBounds = true
        self.wholeImageView.hidden = true
        self.insertSubview(self.wholeImageView, atIndex: 0)
    }
    
    private func setUpImageViewRect(image: UIImage!) {
        let size = self.bounds.size
        let imageSize = image.size
        let widthRatio = size.width / imageSize.width
        let heightRatio = size.height / imageSize.height
        var rate: CGFloat = max(widthRatio, heightRatio)

        var resizedSize = CGSizeMake(imageSize.width * rate, imageSize.height * rate)
        self.imageView.frame.size = resizedSize
    }
    
    private func setUpTransform() {
        if self.zoomCourse == .Random {
            let randomNum = Int(arc4random_uniform(4) + 1)
            self.zoomCourse = kenBurnsViewZoomCourse(rawValue: randomNum)!
        }
        self.setUpZoomRect(self.zoomCourse)
    }
    
    private func setUpZoomRect(course: kenBurnsViewZoomCourse) {
        var startRect = CGRectZero
        var endRect = CGRectZero
        
        switch course {
        case .ToLowerLeft:
            startRect = self.computeZoomRect(.UpperRight, zoomRate: self.startZoomRate)
            endRect = self.computeZoomRect(.LowerLeft, zoomRate: self.endZoomRate)
        case .ToLowerRight:
            startRect = self.computeZoomRect(.UpperLeft, zoomRate: self.startZoomRate)
            endRect = self.computeZoomRect(.LowerRight, zoomRate: self.endZoomRate)
        case .ToUpperLeft:
            startRect = self.computeZoomRect(.LowerRight, zoomRate: self.startZoomRate)
            endRect = self.computeZoomRect(.UpperLeft, zoomRate: self.endZoomRate)
        case .ToUpperRight:
            startRect = self.computeZoomRect(.LowerLeft, zoomRate: self.startZoomRate)
            endRect = self.computeZoomRect(.UpperRight, zoomRate: self.endZoomRate)
        default:
            break
        }
        
        self.startTransform = self.translatesAndScaledTransform(startRect)
        self.endTransform = self.translatesAndScaledTransform(endRect)
    }
    
    private func translatesAndScaledTransform(rect: CGRect) -> CGAffineTransform {
        let imageViewSize = self.imageView.bounds.size
        
        let scale = CGAffineTransformMakeScale(CGRectGetWidth(rect) / imageViewSize.width, CGRectGetHeight(rect) / imageViewSize.height)
        let translation = CGAffineTransformMakeTranslation(CGRectGetMidX(rect) - CGRectGetMidX(self.imageView.bounds), CGRectGetMidY(rect) - CGRectGetMidY(self.imageView.bounds))
        return CGAffineTransformConcat(scale, translation)
    }
    
    private func computeZoomRect(zoomPoint: kenBurnsViewStartZoomPoint, zoomRate: CGFloat) -> CGRect {
        let imageViewSize = self.imageView.bounds.size
        let zoomSize = CGSizeMake(imageViewSize.width * zoomRate, imageViewSize.height * zoomRate)
        var point = CGPointZero
        
        var x = -fabs(zoomSize.width - CGRectGetWidth(self.bounds))
        var y = -fabs(zoomSize.height - CGRectGetHeight(self.bounds))
        
        switch zoomPoint {
        case .LowerLeft:
            point = CGPointMake(0, y)
        case .LowerRight:
            point = CGPointMake(x, y)
        case .UpperLeft:
            point = CGPointMake(0, 0)
        case .UpperRight:
            point = CGPointMake(x, 0)
        }
        
        var zoomRect: CGRect = CGRectMake(point.x, point.y, zoomSize.width, zoomSize.height)
        let pad = self.padding
        var insets = UIEdgeInsetsMake(-pad.top, -pad.left, -pad.bottom, -pad.right)
        return UIEdgeInsetsInsetRect(zoomRect, insets)
    }
}