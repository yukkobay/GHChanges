//
//  PullRequest.swift
//  GHChanges
//
//  Created by Yuka Kobayashi on 2021/02/03.
//

import Foundation

struct PullRequest: Decodable {

    typealias Identifier = Int

    struct Label {
        enum Kind {
            case group
            case tag
            case undefined

            fileprivate var prefix: String {
                switch self {
                case .group: return "group: "
                case .tag: return "tag: "
                case .undefined: return ""
                }
            }

            init(rawValue: String) {
                if rawValue.hasPrefix(Kind.group.prefix) {
                    self = .group
                } else if rawValue.hasPrefix(Kind.tag.prefix) {
                    self = .tag
                } else {
                    self = .undefined
                }
            }
        }

        let kind: Kind
        let name: String
    }

    let number: Identifier
    let title: String

    let author: String
    let labels: [Label]

    let additions: Int
    let deletions: Int

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

    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: RootKeys.self)

        number = try container.decode(Int.self, forKey: .number)
        title = try container.decode(String.self, forKey: .title)

        author = try container
            .nestedContainer(keyedBy: OtherKeys.self, forKey: .author)
            .decode(String.self, forKey: .login)

        labels = try container
            .nestedContainer(keyedBy: OtherKeys.self, forKey: .labels)
            .decode([Label].self, forKey: .nodes)

        additions = try container.decode(Int.self, forKey: .additions)
        deletions = try container.decode(Int.self, forKey: .deletions)
    }
}

extension PullRequest.Label: Decodable {

    private enum Keys: String, CodingKey {
        case name
    }

    init(from decoder: Decoder) throws {
        let rawName = try decoder
            .container(keyedBy: Keys.self)
            .decode(String.self, forKey: .name)

        let kind = Kind(rawValue: rawName)
        self.name = String(rawName.dropFirst(kind.prefix.count))
        self.kind = kind
    }
}
