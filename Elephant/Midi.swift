//
//  Midi.swift
//  Elephant
//
//  Created by Thomas Brichart on 05/07/2015.
//  Copyright (c) 2015 Thomas Brichart. All rights reserved.
//

import Foundation
import AudioToolbox
import Cocoa

class MidiFile {
    
    class func readMidiFile(url: NSURL) -> [Int: [String: [ElNote]]] {
        var musicSequence:MusicSequence = nil
        
        var s: MusicSequence = MusicSequence()
        NewMusicSequence(&s)
        
        var result: [Int: [String: [ElNote]]] = [:]
        
        var midiFileURL = url
        let soundCFURL = midiFileURL as CFURL
        
        //println("Sound URL: \(soundCFURL)")
        
        MusicSequenceFileLoad(s, soundCFURL, 0, 0)
        
        var trackCount: UInt32 = 0
        
        var track: MusicTrack = nil
        
        MusicSequenceGetTrackCount(s, &trackCount)
        
        println("Track count: \(trackCount)")
        
        var infos = MusicSequenceGetInfoDictionary(s) as Dictionary
        
        var tempo = infos["tempo"] as! Int
        
        println(infos)
        
        MusicSequenceGetIndTrack(s, 0, &track)
        
        var iterator: MusicEventIterator = nil
        NewMusicEventIterator(track, &iterator)
        
        var timeStamp = MusicTimeStamp()
        var type = MusicEventType()
        var data: UnsafePointer<()> = nil
        var dataSize = UInt32()
        
        var hasNext: Boolean = 1
        
        var midiNoteMessage: MIDINoteMessage = MIDINoteMessage()
        
        while hasNext == 1 {
            MusicEventIteratorHasNextEvent(iterator, &hasNext)
            
            MusicEventIteratorGetEventInfo(iterator, &timeStamp, &type, &data, &dataSize)
            
            var outSeconds: Float64 = 0
            MusicSequenceGetSecondsForBeats(s, timeStamp, &outSeconds)
            
            switch (type){
            case UInt32(kMusicEventType_MIDINoteMessage):
                let eventData = UnsafePointer<MIDINoteMessage>(data)
                let channel = eventData.memory.channel
                let note = eventData.memory.note
                let velocity = eventData.memory.velocity
                let duration = eventData.memory.duration
                //println("\(outSeconds) - \(timeStamp) - \(note) - \(velocity) - \(duration)")
                
                let track: TrackPosition!
                
                if note == 36 {
                    track = .FarLeft
                } else if note == 40 {
                    track = .CenterLeft
                } else if note == 44 {
                    track = .CenterRight
                } else {
                    track = .FarRight
                }
                
                var appearTime = Int(outSeconds * 600)
                
                if appearTime == 0 { appearTime = 1 }
                
                let noteDuration = Int(duration * 600)
                
                var newNote = ElNote(track: track, appearTime: Double(appearTime), noteDuration: Double(noteDuration))
                
                if result[appearTime] != nil {
                    if result[appearTime]!["appear"] != nil {
                        result[appearTime]!["appear"]!.append(newNote)
                    } else {
                        result[appearTime]!.updateValue([newNote], forKey: "appear")
                    }
                } else {
                    result.updateValue(["appear": [newNote]], forKey: appearTime)
                }
                
                let playTime = Int(appearTime) + Int(UIConfig.expectedFPS * UIConfig.noteDuration)
                
                if result[playTime] != nil {
                    if result[playTime]!["play"] != nil {
                        result[playTime]!["play"]!.append(newNote)
                    } else {
                        result[playTime]!.updateValue([newNote], forKey: "play")
                    }
                } else {
                    result.updateValue(["play": [newNote]], forKey: playTime)
                }
                
                let stopTime = playTime + Int(noteDuration)
                
                if result[stopTime] != nil {
                    if result[stopTime]!["stop"] != nil {
                        result[stopTime]!["stop"]!.append(newNote)
                    } else {
                        result[stopTime]!.updateValue([newNote], forKey: "stop")
                    }
                } else {
                    result.updateValue(["stop": [newNote]], forKey: stopTime)
                }
                
            case UInt32(kMusicEventType_Meta):
                //println("Meta Données")
                let eventData = UnsafePointer<MIDIMetaEvent>(data)
                let eventType = eventData.memory.metaEventType
                let unused1 = eventData.memory.unused1
                let unused2 = eventData.memory.unused2
                let unused3 = eventData.memory.unused3
                let dataLength = eventData.memory.dataLength
                let data = eventData.memory.data
                
                //println("\(eventType) - \(eventData) - \(unused1) - \(unused2) - \(unused3) - \(data) - \(dataLength)")
            default:
                println("Unknwon type: \(type)")
            }
            
            MusicEventIteratorNextEvent(iterator)
        }
        
        return result
    }
}