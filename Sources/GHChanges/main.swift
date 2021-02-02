import ArgumentParser

struct GHChanges: ParsableCommand {
    @Option(
        name: .shortAndLong,
        help: ArgumentHelp(
            "Path to git working directory with remote settings to GitHub",
            valueName: "path/to/dir"
        )
    )
    var repo: String = "./"

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
            print("  repo:", repo)
            print("  token:", token)
            print("  refFrom:", refFrom)
            print("  refTo:", refTo)
        }

        // TODO: merge-commit list -> pr list
        // TODO: prごとにlabelを収集する
        // TODO: grouping
        // TODO: output to markdown
    }

    mutating func validate() throws {
        #if DEBUG
        verbose = true

        // Use these when debugging
//        repo = "./SampleGit"
//        token = "xxx"
//        refFrom = "v0.0.0"
        #endif

        if repo.isEmpty {
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
