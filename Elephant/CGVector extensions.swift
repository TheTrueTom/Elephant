//
//  CGVector extensions.swift
//  Elephant
//
//  Created by Thomas Brichart on 08/06/2015.
//  Copyright (c) 2015 Thomas Brichart. All rights reserved.
//

import Foundation

extension CGVector {
    static func makeFromPoint(#A: CGPoint, B: CGPoint) -> CGVector {
        return CGVectorMake(B.x - A.x, B.y - A.y)
    }
    
    func length() -> CGFloat {
        return sqrt(dx*dx + dy*dy)
    }
    
    func dot(secondVector: CGVector) -> CGFloat {
        return (dx * secondVector.dx) + (dy * secondVector.dy)
    }
    
    func angleWith(otherVector: CGVector) -> CGFloat {
        return acos(self.dot(otherVector) / (self.length() * otherVector.length()))
    }
}