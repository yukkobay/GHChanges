//
//  PullRequest.swift
//  GHChanges
//
//  Created by Yuka Kobayashi on 2021/02/03.
//

import Foundation

struct PullRequest {

    private static let prefixOfGroup = "group: "
    private static let prefixOfTag = "tag: "

    typealias Identifier = Int

    let number: Identifier
    let title: String

    let author: String

    let group: String?
    let tags: [String]

    let additions: Int
    let deletions: Int

    func accept(visitor: ChangeVisitor) {
        visitor.visit(pullRequest: self)
    }
}

// MARK: - <Decodable>
extension PullRequest: Decodable {

    private enum RootKeys: String, CodingKey {
        case number
        case title
        case author
        case labels
        case additions
        case deletions
    }

    private enum OtherKeys: String, CodingKey {
        case login
        case nodes
    }

    private struct _Label: Decodable {
        let name: String
    }

    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: RootKeys.self)

        number = try container.decode(Int.self, forKey: .number)
        title = try container.decode(String.self, forKey: .title)

        author = try container
            .nestedContainer(keyedBy: OtherKeys.self, forKey: .author)
            .decode(String.self, forKey: .login)

        let labels = try container
            .nestedContainer(keyedBy: OtherKeys.self, forKey: .labels)
            .decode([_Label].self, forKey: .nodes)
            .map({ $0.name })

        group = labels
            .filter { $0.hasPrefix(Self.prefixOfGroup) }
            .map { String($0.dropFirst(Self.prefixOfGroup.count)) }
            .first

        tags = labels
            .filter { $0.hasPrefix(Self.prefixOfTag) }
            .map { String($0.dropFirst(Self.prefixOfTag.count)) }

        additions = try container.decode(Int.self, forKey: .additions)
        deletions = try container.decode(Int.self, forKey: .deletions)
    }
}
