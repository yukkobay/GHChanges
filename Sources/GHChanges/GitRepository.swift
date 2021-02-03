//
//  GitRepository.swift
//  GHChanges
//
//  Created by Yuka Kobayashi on 2021/02/03.
//

import Foundation
import Combine

final class GitRepository {

    private let path: String
    private let owner: String
    private let name: String
    private let token: String

    private let verbose: Bool

    init(at path: String, token: String, verbose: Bool) throws {

        self.path = path
        self.token = token
        self.verbose = verbose

        guard let remoteInfo = try? execute(.git, "remote", "-v", at: path),
              !remoteInfo.isEmpty else
        {
            throw GHChangesError.gitError("Git repository is not found.")
        }

        let extracted = remoteInfo.matches("^origin\\tgit@github.com:(.+)/(.+)\\.git")
        guard extracted.count == 3 else {
            throw GHChangesError.gitError("Remote repository is not GitHub.")
        }

        owner = extracted[1]
        name = extracted[2]

        if verbose {
            print("Found a git repository.")
            print("  path:", path)
            print("  owner:", owner)
            print("  name:", name)
            print()
        }
    }

    func getPullRequests(
        from refFrom: String,
        to refTo: String
    ) throws -> Future<[PullRequest], Never> {

        let ids = getPullRequestIdentifiers(from: refFrom, to: refTo)
        print("Pull request's ids:", ids)

        // TODO: prごとにlabelを収集する

        return .init { p in
            p(.success([]))
        }
    }


    private func getPullRequestIdentifiers(
        from refFrom: String,
        to refTo: String
    ) -> [PullRequest.Identifier] {

        let raw = try? execute(
            .git,
            "log",
            "--pretty=format:%s",
            "--right-only",
            "--merges",
            "\(refFrom)..\(refTo)",
            at: path
        )

        return raw?
            .split(separator: "\n")
            .map(String.init)
            .filter(isMergeCommitOfPullRequest)
            .compactMap(self.extractPullRequestIdentifier) ?? []
    }

    private func isMergeCommitOfPullRequest(_ line: String) -> Bool {
        return line.hasPrefix("Merge pull request")
    }

    private func extractPullRequestIdentifier(
        from line: String
    ) -> PullRequest.Identifier? {

        let match = line.matches("#(\\d+)")[1]
        return PullRequest.Identifier(String(match))
    }
}
