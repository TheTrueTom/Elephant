//
//  ElWindow.swift
//  Elephant
//
//  Created by Thomas Brichart on 08/06/2015.
//  Copyright (c) 2015 Thomas Brichart. All rights reserved.
//

import Foundation
import Cocoa

class ElWindow: NSWindow {
    override var canBecomeKeyWindow: Bool {
        return true
    }
}