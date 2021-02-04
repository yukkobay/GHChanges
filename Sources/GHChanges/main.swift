import ArgumentParser
import Combine
import Foundation

struct GHChanges: ParsableCommand {
    @Option(
        name: [.customLong("repo"), .short],
        help: ArgumentHelp(
            "Path to git working directory with remote settings to GitHub",
            valueName: "path/to/dir"
        )
    )
    var repoDir: String = "./"

    @Option(help: "Github API token with a permission for repo:read")
    var token: String = ""

    @Option(
        name: .customLong("from"),
        help: ArgumentHelp("Git ref at start. Generally use a latest release tag", valueName: "ref")
    )
    var refFrom: String = ""

    @Option(
        name: .customLong("to"),
        help: ArgumentHelp("Git ref at end", valueName: "ref")
    )
    var refTo: String = "HEAD"

    @Flag(name: .shortAndLong, help: "Print status updates while counting.")
    var verbose: Bool = false

    mutating func run() throws {

        if verbose {
            print("Args")
            print("  repo:", repoDir)
            print("  token:", token)
            print("  refFrom:", refFrom)
            print("  refTo:", refTo)
            print()
        }

        // ## Note
        // Only merge commits are supported.
        // This is not a problem as the default branch is protected.
        // In the future, we need to support direct single commit.

        var result: Result<[PullRequest], Error>!

        getPullRequests: do {
            let group = DispatchGroup()
            group.enter()

            try GitRepository(at: repoDir, token: token, verbose: verbose)
                .getPullRequests(from: refFrom, to: refTo) {
                    result = $0
                    group.leave()
                }

            group.wait()
        }

        let pullRequests = try result.get()

        guard !pullRequests.isEmpty else {
            // TODO: Exit as error
            return
        }

        let visitor = ChangeVisitor()
        pullRequests.forEach({ visitor.visit(pullRequest: $0) })

        let output = ChangeNoteGenerator.make(
            with: visitor.summary,
            withAppendix: false
        )

        print(output)
    }

    mutating func validate() throws {
        #if DEBUG
        verbose = true

        // Use these when debugging
//        repo = "./SampleGit"
//        token = "xxx"
//        refFrom = "v0.0.0"
        #endif

        if repoDir.isEmpty {
            throw ValidationError("repo is a reqired option.")
        }

        if token.isEmpty {
            throw ValidationError("token is a reqired option.")
        }

        if refFrom.isEmpty {
            throw ValidationError("from is a reqired option.")
        }
    }
}

GHChanges.main()
