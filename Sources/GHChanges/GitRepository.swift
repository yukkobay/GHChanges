//
//  GitRepository.swift
//  GHChanges
//
//  Created by Yuka Kobayashi on 2021/02/03.
//

import Foundation

final class GitRepository {

    private let path: String
    private let owner: String
    private let name: String
    private let token: String

    init(at path: String, token: String) throws {

        self.path = path
        self.token = token

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
    }

    func getPullRequests(
        from refFrom: String,
        to refTo: String,
        completion: @escaping (Result<[PullRequest], Error>) -> Void
    ) throws {

        let ids = getPullRequestIdentifiers(from: refFrom, to: refTo)

        if ids.isEmpty {
            completion(.success([]))
            return
        }

        fetchPullRequests(identifiers: ids, completion: completion)
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

    private func fetchPullRequests(
        identifiers: [PullRequest.Identifier],
        completion: @escaping (Result<[PullRequest], Error>) -> Void
    ) {

        var query: String = """
            {
                repository(name: "\(name)", owner: "\(owner)") {

            """

        for id in identifiers {
            query += """
                    p\(id): pullRequest(number: \(id)) { ...info }

            """
        }

        query += """
                }
            }

            """

        query += """
            fragment info on PullRequest {
                number
                title
                author { ... on User { login } }
                labels(first: 100) { nodes { name } }
                additions
                deletions
            }
            """

        requestGitHub(query: query) { result in
            switch result {
            case .success(let data):

                do {
                    let r = try JSONDecoder().decode(
                        FetchPullRequestResponse.self,
                        from: data
                    )

                    completion(.success(r.pullRequest))

                } catch {
                    completion(.failure(error))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func requestGitHub(query: String, completion: @escaping (Result<Data, Error>) -> Void) {

        let url = URL(string: "https://api.github.com/graphql")!
        var request = URLRequest(url: url)

        do {
            request.httpBody = try JSONSerialization.data(
                withJSONObject: ["query": query],
                options: .init()
            )
        } catch {
            completion(.failure(error))
        }

        request.httpMethod = "POST"
        request.cachePolicy = .reloadIgnoringLocalCacheData

        request.addValue("application/json; charaset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, res, error in

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(GHChangesError.undefined))
                return
            }

            completion(.success(data))
        }

        task.resume()
    }

    private struct FetchPullRequestResponse: Decodable {

        private enum RootKeys: String, CodingKey {
            case data
        }

        private enum DataKeys: String, CodingKey {
            case repository
        }

        let pullRequest: [PullRequest]

        init(from decoder: Decoder) throws {
            pullRequest = try decoder
                .container(keyedBy: RootKeys.self)
                .nestedContainer(keyedBy: DataKeys.self, forKey: .data)
                .decode([String: PullRequest].self, forKey: .repository)
                .map({ $0.value })
        }
    }
}
