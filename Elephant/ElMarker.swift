//
//  ElMarker.swift
//  Elephant
//
//  Created by Thomas Brichart on 09/06/2015.
//  Copyright (c) 2015 Thomas Brichart. All rights reserved.
//

import Foundation
import SpriteKit

class ElMarker: SKSpriteNode {
    
    init(position: CGPoint, color: NSColor) {
        super.init(texture: SKTexture(imageNamed: "note"), color: color, size: UIConfig.noteEndSize)
        self.position = position
        self.colorBlendFactor = UIConfig.songItemColorBlendingFactor
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}