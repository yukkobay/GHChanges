//
//  ChangeNoteGenerator.swift
//  GHChanges
//
//  Created by Yuka Kobayashi on 2021/02/04.
//

import Foundation

struct ChangeNoteGenerator {

    static func make(with summary: ChangeSummary, withAppendix: Bool) -> String {

        var grouped = summary
            .groupedPRs
            .sorted { $0.key < $1.key }
            .map({ markdown(forGroup: $0.key, pullRequests: $0.value) })

        if !summary.notGroupedPRs.isEmpty {
            grouped
                .append(markdown(forGroup: "Others", pullRequests: summary.notGroupedPRs))
        }

        let body = grouped.joined(separator: "\n\n") + "\n"

        let appendix: String
        if !withAppendix {
            appendix = ""
        } else {

            let mvp: String = {
                guard let mvp = summary.authorCount.max(by: { $0.value < $1.value }) else {
                    return ""
                }

                return "- 🎉 Most contributed person is @\(mvp.key)! (\(mvp.value) PRs)\n"
            }()

            let tagTable: String = {

                guard !summary.tagCount.isEmpty else {
                    return ""
                }

                let table = summary.tagCount
                    .sorted(by: { $0.value > $1.value })
                    .map({ "\($0.key) | \($0.value)" })
                    .joined(separator: "\n")

                return """
                    Tag | # of PRs
                    ---|---
                    \(table)

                    """
            }()

            appendix = """

                ---
                ### Appendix
                - 🔖 Number of PRs: \(summary.numberOfPullRequests)
                \(mvp)
                ```diff
                + Total additions +\(summary.additions)
                - Todal deletions -\(summary.deletions)
                ```
                """ + tagTable
        }

        return body + appendix
    }

    private static func markdown(forGroup group: String, pullRequests: [PullRequest]) -> String {
        return """
            ## \(group) (\(pullRequests.count))
            \(pullRequests.map(markdown(forPullRequest:)).joined(separator: "\n"))
            """
    }

    private static func markdown(forPullRequest pullRequest: PullRequest) -> String {
        let header = "- \(pullRequest.title) #\(pullRequest.number) (@\(pullRequest.author))"
        let body = pullRequest.tags.map({ "`\($0)`" }).joined(separator: " ")

        return header + (body.isEmpty ? "" : "\n  - \(body)")
    }
}
