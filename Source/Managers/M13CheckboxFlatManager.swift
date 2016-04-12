//
//  M13CheckboxFlatManager.swift
//  M13Checkbox
//
//  Created by McQuilkin, Brandon on 4/1/16.
//  Copyright © 2016 Brandon McQuilkin. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

class M13CheckboxFlatManager: M13CheckboxManager {
    
    //----------------------------
    // MARK: - Properties
    //----------------------------
    
    override var tintColor: UIColor {
        didSet {
            selectedBoxLayer.strokeColor = tintColor.CGColor
            if style == .Stroke {
                markLayer.strokeColor = tintColor.CGColor
            } else {
                selectedBoxLayer.fillColor = tintColor.CGColor
            }
        }
    }
    
    override var secondaryTintColor: UIColor? {
        didSet {
            unselectedBoxLayer.strokeColor = secondaryTintColor?.CGColor
        }
    }
    
    override var secondaryCheckmarkTintColor: UIColor? {
        didSet {
            if style == .Fill {
                markLayer.strokeColor = secondaryCheckmarkTintColor?.CGColor
            }
        }
    }
    
    override var hideBox: Bool {
        didSet {
            selectedBoxLayer.hidden = hideBox
            unselectedBoxLayer.hidden = hideBox
        }
    }
    
    private var style: M13Checkbox.AnimationStyle = .Stroke
    
    init(style: M13Checkbox.AnimationStyle) {
        self.style = style
        super.init()
        sharedSetup()
    }
    
    override init() {
        super.init()
        sharedSetup()
    }
    
    private func sharedSetup() {
        // Disable som implicit animations.
        let newActions = [
            "opacity": NSNull(),
            "strokeEnd": NSNull(),
            "transform": NSNull(),
            "fillColor": NSNull(),
            "path": NSNull(),
            "lineWidth": NSNull()
        ]
        
        // Setup the unselected box layer
        unselectedBoxLayer.lineCap = kCALineCapRound
        unselectedBoxLayer.rasterizationScale = UIScreen.mainScreen().scale
        unselectedBoxLayer.shouldRasterize = true
        unselectedBoxLayer.actions = newActions
        
        unselectedBoxLayer.transform = CATransform3DIdentity
        unselectedBoxLayer.fillColor = nil
        
        // Setup the selected box layer.
        selectedBoxLayer.lineCap = kCALineCapRound
        selectedBoxLayer.rasterizationScale = UIScreen.mainScreen().scale
        selectedBoxLayer.shouldRasterize = true
        selectedBoxLayer.actions = newActions
        
        selectedBoxLayer.fillColor = nil
        selectedBoxLayer.transform = CATransform3DIdentity
        
        // Setup the checkmark layer.
        markLayer.lineCap = kCALineCapRound
        markLayer.lineJoin = kCALineJoinRound
        markLayer.rasterizationScale = UIScreen.mainScreen().scale
        markLayer.shouldRasterize = true
        markLayer.actions = newActions
        
        markLayer.transform = CATransform3DIdentity
        markLayer.fillColor = nil
    }
    
    //----------------------------
    // MARK: - Layers
    //----------------------------
    
    let markLayer = CAShapeLayer()
    let selectedBoxLayer = CAShapeLayer()
    let unselectedBoxLayer = CAShapeLayer()
    
    override var layersToDisplay: [CALayer] {
        return [unselectedBoxLayer, selectedBoxLayer, markLayer]
    }
    
    //----------------------------
    // MARK: - Animations
    //----------------------------
    
    override func animate(fromState: M13Checkbox.CheckState, toState: M13Checkbox.CheckState) {
        super.animate(fromState, toState: toState)
        
        if toState == .Unchecked {
            let morphAnimation = animations.morphAnimation(paths.pathForMark(), toPath: paths.pathForMixedMark())
            morphAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            let opacityAnimation = animations.opacityAnimation(true)
            
            let quickOpacityAnimation = animations.quickOpacityAnimation(true)
            quickOpacityAnimation.duration = quickOpacityAnimation.duration * 4.0
            morphAnimation.duration = morphAnimation.duration - quickOpacityAnimation.duration
            quickOpacityAnimation.beginTime = CACurrentMediaTime() + morphAnimation.duration
            
            CATransaction.begin()
            CATransaction.setCompletionBlock({ () -> Void in
                self.resetLayersForState(toState)
            })
            
            selectedBoxLayer.addAnimation(opacityAnimation, forKey: "opacity")
            if fromState != .Mixed {
                markLayer.addAnimation(morphAnimation, forKey: "path")
            }
            markLayer.addAnimation(quickOpacityAnimation, forKey: "opacity")
            
            CATransaction.commit()
            
        } else {
            if fromState == .Unchecked {
                markLayer.path = paths.pathForMixedMark().CGPath
                
                let morphAnimation = animations.morphAnimation(paths.pathForMixedMark(), toPath: paths.pathForMark())
                morphAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                let opacityAnimation = animations.opacityAnimation(false)
                
                let quickOpacityAnimation = animations.quickOpacityAnimation(false)
                quickOpacityAnimation.duration = quickOpacityAnimation.duration * 4.0
                morphAnimation.beginTime = CACurrentMediaTime() + quickOpacityAnimation.duration
                morphAnimation.duration = morphAnimation.duration - quickOpacityAnimation.duration
                
                CATransaction.begin()
                CATransaction.setCompletionBlock({ () -> Void in
                    self.resetLayersForState(toState)
                })
                
                selectedBoxLayer.addAnimation(opacityAnimation, forKey: "opacity")
                if toState != .Mixed {
                    markLayer.addAnimation(morphAnimation, forKey: "path")
                }
                markLayer.addAnimation(quickOpacityAnimation, forKey: "opacity")
                
                CATransaction.commit()
            } else {
                let fromPath = paths.path(fromState)
                let toPath = paths.path(toState)
                
                let morphAnimation = animations.morphAnimation(fromPath!, toPath: toPath!)
                
                CATransaction.begin()
                CATransaction.setCompletionBlock({ [unowned self] () -> Void in
                    self.resetLayersForState(self.state)
                    })
                
                markLayer.addAnimation(morphAnimation, forKey: "path")
                
                CATransaction.commit()
            }
        }
    }
    
    //----------------------------
    // MARK: - Layout
    //----------------------------
    
    override func layoutLayers() {
        // Frames
        unselectedBoxLayer.frame = CGRectMake(0.0, 0.0, paths.size, paths.size)
        selectedBoxLayer.frame = CGRectMake(0.0, 0.0, paths.size, paths.size)
        markLayer.frame = CGRectMake(0.0, 0.0, paths.size, paths.size)
        // Paths
        unselectedBoxLayer.path = paths.pathForBox().CGPath
        selectedBoxLayer.path = paths.pathForBox().CGPath
        if state == .Unchecked {
            markLayer.path = paths.pathForMixedMark().CGPath
        } else {
            markLayer.path = paths.pathForMixedMark().CGPath
        }
    }
    
    //----------------------------
    // MARK: - Display
    //----------------------------
    
    override func resetLayersForState(state: M13Checkbox.CheckState) {
        super.resetLayersForState(state)
        // Remove all remnant animations. They will interfere with each other if they are not removed before a new round of animations start.
        unselectedBoxLayer.removeAllAnimations()
        selectedBoxLayer.removeAllAnimations()
        markLayer.removeAllAnimations()
        
        // Set the properties for the final states of each necessary property of each layer.
        unselectedBoxLayer.strokeColor = secondaryTintColor?.CGColor
        unselectedBoxLayer.lineWidth = paths.boxLineWidth
        
        selectedBoxLayer.strokeColor = tintColor.CGColor
        selectedBoxLayer.lineWidth = paths.boxLineWidth
        
        if style == .Stroke {
            selectedBoxLayer.fillColor = nil
            markLayer.strokeColor = tintColor.CGColor
            if paths.markType == .Checkmark {
                markLayer.fillColor = nil
            } else {
                markLayer.fillColor = tintColor.CGColor
            }
        } else {
            selectedBoxLayer.fillColor = tintColor.CGColor
            markLayer.strokeColor = secondaryCheckmarkTintColor?.CGColor
        }
        
        markLayer.lineWidth = paths.checkmarkLineWidth
        
        if state == .Unchecked {
            selectedBoxLayer.opacity = 0.0
            markLayer.opacity = 0.0
            markLayer.path = paths.pathForMixedMark().CGPath
        } else if state == .Checked {
            selectedBoxLayer.opacity = 1.0
            markLayer.opacity = 1.0
            markLayer.path = paths.pathForCheckmark().CGPath
        } else {
            selectedBoxLayer.opacity = 1.0
            markLayer.opacity = 1.0
            markLayer.path = paths.pathForMixedMark().CGPath
        }
        
        // Paths
        unselectedBoxLayer.path = paths.pathForBox().CGPath
        selectedBoxLayer.path = paths.pathForBox().CGPath
        markLayer.path = paths.path(state)?.CGPath
    }
    
}
