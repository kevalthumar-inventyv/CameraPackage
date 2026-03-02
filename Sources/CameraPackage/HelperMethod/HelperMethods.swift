//
//  HelperMethods.swift
//  BLEDemo
//
//  Created by Keval Thumar on 23/02/26.
//

import Foundation

@MainActor
public class HelperMethods {
    public static let shared = HelperMethods()
    private init() {}
        
    public func getCurrentTimeStamp() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss.SSS"
        return dateFormatter.string(from: date)
    }
}

