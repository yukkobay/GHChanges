//
//  GHChangesError.swift
//  GHChanges
//
//  Created by Yuka Kobayashi on 2021/02/03.
//

import Foundation

enum GHChangesError: Error {
    case processError(Int32)
    case gitError(String)
    case undefined
}
