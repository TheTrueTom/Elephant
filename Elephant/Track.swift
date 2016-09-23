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

class Track{
    
    // Calculated Characteristics
    var top: CGPoint!
    var bottom: CGPoint!
    
    var length: CGFloat!
    var angle: CGFloat!
    
    var markerPosition: CGPoint!
    
    var trackPosition: TrackPosition!
    
    init(position: TrackPosition) {
        
        trackPosition = position
        
        switch position {
        case .FarLeft:
            self.top = CGPointMake(160, 212) // CGPointMake(119, 390)
            self.bottom = CGPointMake(447, 594) // CGPointMake(480, 0)
            self.markerPosition = CGPointMake(388, 516) // CGPointMake(355, 134)
        case .CenterLeft:
            self.top = CGPointMake(370, 129) // CGPointMake(396, 470)
            self.bottom = CGPointMake(512, 594) // CGPointMake(525, 0)
            self.markerPosition = CGPointMake(469, 454) // CGPointMake(472, 194)
        case .CenterRight:
            self.top = CGPointMake(632, 137) // CGPointMake(680, 470)
            self.bottom = CGPointMake(534, 594) // CGPointMake(500, 0)
            self.markerPosition = CGPointMake(565, 447) // CGPointMake(572, 190)
        case .FarRight:
            self.top = CGPointMake(907, 225) // CGPointMake(890, 390)
            self.bottom = CGPointMake(627, 594) // CGPointMake(520, 0)
            self.markerPosition = CGPointMake(673, 525) // CGPointMake(660, 140)
        default:
            fatalError("Unknown track position used during Track initialization")
        }
        
        // Longueur et angle de la corde avec la hauteur de l'écran
        let vector = CGVector.makeFromPoint(A: bottom, B: top)
        
        length = vector.length()
        
        switch position {
        case .CenterRight, .FarRight:
            angle = -CGVectorMake(0, UIConfig.screenSize.height).angleWith(vector)
        case .FarLeft, .CenterLeft:
            angle = -vector.angleWith(CGVectorMake(0, UIConfig.screenSize.height))
        default:
            fatalError("Unknown track position used during Track initialization")
        }
    }
}