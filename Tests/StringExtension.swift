//
//  StringExtension.swift
//  FutureLib
//
//  Created by Andreas Grosam on 05.01.16.
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//


public extension String {
    /// Returns `true` iff `self` begins contains `substring`.
    public func contains(substring: String) -> Bool {
        let range = self.rangeOfString(substring)
        if let r = range {
            return r.startIndex != r.endIndex
        }
        return false
    }
}

