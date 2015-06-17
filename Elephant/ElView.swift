//
//  ElView.swift
//  Elephant
//
//  Created by Thomas Brichart on 08/06/2015.
//  Copyright (c) 2015 Thomas Brichart. All rights reserved.
//

import Foundation
import SpriteKit

class ElView: SKView {
    
    override func viewDidEndLiveResize() {
        self.scene?.didMoveToView(self)
    }
}