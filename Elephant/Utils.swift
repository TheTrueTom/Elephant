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
    class func notesFromFile(fileURL: NSURL) -> Dictionary<Int, Array<ElNote>> {
        
        var result: Dictionary<Int, Array<ElNote>> = [:]
        
        if let path = fileURL.path, let aStreamReader = StreamReader(path: path) {
            
            for line in aStreamReader {
                var lineElements = split(line) {$0 == " "}
                
                if contains(["BEAT", "VOCAL"], lineElements[0]) {
                    let track = Utils.getStringPosition(lineElements[3])
                    let appearTime = lineElements[1].toInt()!
                    let noteDuration = Double(lineElements[2].toInt()!)
                    
                    var note = ElNote(track: track, appearTime: Double(appearTime), noteDuration: noteDuration)
                    
                    if result[appearTime] != nil {
                        result[appearTime]?.append(note)
                    } else {
                        result.updateValue([note], forKey: appearTime)
                    }
                }
            }
            
            aStreamReader.close()
        }
        
        println("File loaded")
        
        return result
    }
    
    class func saveFileFromNotes(fileURL: NSURL, notes: [Int: [ElNote]]) {
        let sortedKeys = Array(notes.keys).sorted(<)
        
        var fileString = ""
        
        for key in sortedKeys {
            if let noteList = notes[key] where !noteList.isEmpty {
                for note in noteList {
                    var prefix = ""
                    var stringPos = ""
                    
                    if note.trackPosition == .FarLeft {
                        prefix = "BEAT"
                        stringPos = "A"
                    }else if note.trackPosition == .CenterLeft {
                        prefix = "BEAT"
                        stringPos = "B"
                    } else if note.trackPosition == .CenterRight {
                        prefix = "VOCAL"
                        stringPos = "C"
                    } else {
                        prefix = "VOCAL"
                        stringPos = "D"
                    }
                    
                    var noteString = prefix + " \(Int(note.appearTime))" + " \(Int(note.noteDuration)) " + stringPos + "\n"
                    
                    fileString += noteString
                }
            }
        }
        
        fileString.writeToURL(fileURL, atomically: false, encoding: NSUTF8StringEncoding, error: nil)
    }
    
    class func getStringPosition(string: String) -> TrackPosition {
        switch string {
        case "A":
            return .FarLeft
        case "B":
            return .CenterLeft
        case "C":
            return .CenterRight
        case "D":
            return .FarRight
        default:
            fatalError("Wrong TrackPosition called in Utils.getStringPosition")
        }
    }
    
    class func getMaxKey(dictionary: Dictionary<Int, AnyObject>) -> Double {
        return Double(maxElement(dictionary.keys))
    }
}