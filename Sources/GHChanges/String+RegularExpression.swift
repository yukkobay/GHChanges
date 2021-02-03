//
//  String+RegularExpression.swift
//  GHChanges
//
//  Created by Yuka Kobayashi on 2021/02/03.
//

import Foundation

extension String {
    func isMatch(_ pattern: String) -> Bool {
        return !matches(pattern).isEmpty
    }

    func matches(_ pattern: String) -> [String] {
        let regex: NSRegularExpression
        do {
            regex = try .init(pattern: pattern)
        } catch {
            assertionFailure("Invalid pattern: \(pattern)")
            return []
        }

        guard let result = regex.firstMatch(
            in: self,
            options: .init(),
            range: .init(location: 0, length: count)
        ) else {
            return []
        }

        return (0 ..< result.numberOfRanges)
            .map({
                let range = result.range(at: $0)
                let from = index(startIndex, offsetBy: range.lowerBound)
                let to = index(startIndex, offsetBy: range.upperBound)

                return String(self[from..<to])
            })
    }
}
