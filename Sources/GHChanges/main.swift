import ArgumentParser
import Combine
import Foundation

struct GHChanges: ParsableCommand {
    @Option(
        name: [.customLong("repo"), .short],
        help: ArgumentHelp(
            "Path to git working directory with GitHub set in remote.",
            valueName: "path"
        )
    )
    var repoDir: String = "./"

    @Option(help: "Github API token with a permission for repo:read")
    var token: String = ""

    @Option(
        name: .customLong("from"),
        help: ArgumentHelp(
            "Git reference at start. Generally set a latest release tag",
            valueName: "ref"
        )
    )
    var refFrom: String = ""

    @Option(
        name: .customLong("to"),
        help: ArgumentHelp("Git ref at end", valueName: "ref")
    )
    var refTo: String = "HEAD"

    @Flag(name: [.long, .customShort("a")], help: "Append more information.")
    var withAppendix: Bool = false

    mutating func run() throws {

        // ## Note
        // Only merge commits are supported.
        // This is not a problem as the default branch is protected.
        // In the future, we need to support direct single commit.

        var result: Result<[PullRequest], Error>!

        getPullRequests: do {
            let group = DispatchGroup()
            group.enter()

            try GitRepository(at: repoDir, token: token)
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
            withAppendix: withAppendix
        )

        print(output)
    }

    mutating func validate() throws {
        #if DEBUG
//        repoDir = ""
//        token = ""
//        refFrom = ""
//        refTo = ""
//        withAppendix = true
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
