//
//  Track.swift
//  Elephant
//
//  Created by Thomas Brichart on 08/06/2015.
//  Copyright (c) 2015 Thomas Brichart. All rights reserved.
//

import Foundation
import SpriteKit

enum TrackPosition {
    case FarLeft
    case CenterLeft
    case CenterRight
    case FarRight
}

class Track: SKShapeNode {
    
    // Calculated Characteristics
    var top: CGPoint!
    var bottom: CGPoint!
    
    var length: CGFloat!
    var angle: CGFloat!
    
    var markerPosition: CGPoint!
    
    var trackPosition: TrackPosition!
    
    init(position: TrackPosition) {
        
        trackPosition = position
        
        // Position du début et de la fin de la piste
        var topShift: CGFloat = 0
        var bottomShift: CGFloat = 0
        
        switch position {
        case .FarLeft:
            topShift = -UIConfig.topTrackSpacing - UIConfig.topSubSpacing
            bottomShift = -UIConfig.bottomTrackSpacing - UIConfig.bottomSubSpacing
        case .CenterLeft:
            topShift = -UIConfig.topTrackSpacing + UIConfig.topSubSpacing
            bottomShift = -UIConfig.bottomTrackSpacing + UIConfig.bottomSubSpacing
        case .CenterRight:
            topShift = UIConfig.topTrackSpacing - UIConfig.topSubSpacing
            bottomShift = UIConfig.bottomTrackSpacing - UIConfig.bottomSubSpacing
        case .FarRight:
            topShift = UIConfig.topTrackSpacing + UIConfig.topSubSpacing
            bottomShift = UIConfig.bottomTrackSpacing + UIConfig.bottomSubSpacing
        default:
            fatalError("Unknown track position used during Track initialization")
        }
        
        self.top = CGPointMake(UIConfig.screenSize.width / 2 + topShift, UIConfig.screenSize.height)
        self.bottom = CGPointMake(UIConfig.screenSize.width / 2 + bottomShift, 0)
        
        // Longueur et angle de la corde avec la hauteur de l'écran
        let vector = CGVector.makeFromPoint(A: bottom, B: top)
        
        length = vector.length()
        
        switch position {
        case .FarLeft, .CenterLeft:
            angle = CGVectorMake(0, UIConfig.screenSize.height).angleWith(vector)
        case .CenterRight, .FarRight:
            angle = vector.angleWith(CGVectorMake(0, UIConfig.screenSize.height))
        default:
            fatalError("Unknown track position used during Track initialization")
        }
        
        // Position des marqueurs
        let a: CGFloat = (top.y - bottom.y) / (top.x - bottom.x)
        let b: CGFloat = top.y - a * top.x
        
        let X = (UIConfig.baseLineHeight - b) / a
        
        markerPosition = CGPointMake(X, UIConfig.baseLineHeight)
        
        var path: CGMutablePathRef = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, top.x, top.y)
        CGPathAddLineToPoint(path, nil, bottom.x, bottom.y)
        
        super.init()
        
        self.path = path
        self.alpha = 1
        self.fillColor = NSColor.whiteColor()
        self.strokeColor = NSColor.whiteColor()
        self.lineWidth = UIConfig.trackStrokeWidth
        
        self.lineWidth = UIConfig.trackStrokeWidth
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}