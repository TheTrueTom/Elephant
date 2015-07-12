//
//  Utils.swift
//  You're Up Guitar Hero
//
//  Created by Thomas Brichart on 26/05/2015.
//  Copyright (c) 2015 Thomas Brichart. All rights reserved.
//

import Foundation
import SpriteKit

class Utils {
    class func getMaxKey(dictionary: Dictionary<Int, AnyObject>) -> Double {
        return Double(maxElement(dictionary.keys))
    }
}