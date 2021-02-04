//
//  Visitor.swift
//  GHChanges
//
//  Created by Yuka Kobayashi on 2021/02/04.
//

import Foundation

struct ChangeSummary: CustomDebugStringConvertible {

    var prCount: Int = 0

    var groupedPRs: [String: [PullRequest]] = [:]
    var notGroupedPRs: [PullRequest] = []

    var tagCount: [String: Int] = [:]
    var authorCount: [String: Int] = [:]

    var additions: Int = 0
    var deletions: Int = 0

    var debugDescription: String {

        let groupedPRsText = groupedPRs
            .map { "        \($0.key): \($0.value.count) PRs" }
            .joined(separator: "\n")

        let tagCountText = tagCount
            .map { "        \($0.key): \($0.value)" }
            .joined(separator: "\n")

        let authorCountText = authorCount
            .map { "        \($0.key): \($0.value)" }
            .joined(separator: "\n")

        return """
            ChangeSummary(
                prCount: \(prCount)
                groupedPRs: [\({
                    groupedPRsText.isEmpty ? "" : "\n\(groupedPRsText)\n    "
                }())]
                notGroupedPRs: \(notGroupedPRs.count)
                tagCount: [\({
                    tagCountText.isEmpty ? "" : "\n\(tagCountText)\n    "
                }())]
                additions: \(additions)
                deletions: \(deletions)
                authors: [\({
                    authorCountText.isEmpty ? "" : "\n\(authorCountText)\n    "
                }())]
            )
            """
    }
}

final class ChangeVisitor {

    private(set) var summary: ChangeSummary = .init()

    func visit(pullRequest: PullRequest) {

        summary.prCount += 1

        if let group = pullRequest.group {
            summary.groupedPRs[group] = summary.groupedPRs[group] ?? []
            summary.groupedPRs[group]?.append(pullRequest)
        } else {
            summary.notGroupedPRs.append(pullRequest)
        }

        pullRequest.tags.forEach {
            summary.tagCount[$0] = summary.tagCount[$0] ?? 0
            summary.tagCount[$0]? += 1
        }

        summary.additions += pullRequest.additions
        summary.deletions += pullRequest.deletions

        summary.authorCount.updateValue(default: 0, forKey: pullRequest.author) {
            return $0 + 1
        }
    }

    // In future, we will support a direct commit.
    // func visit(commit: Any) {}
}

private extension Dictionary {
    mutating func updateValue(
        default defaultValue: Value,
        forKey key: Key,
        handler: (Value) -> Value
    ) {
        updateValue(handler(self[key] ?? defaultValue), forKey: key)
    }
}
