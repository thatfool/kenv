import ArgumentParser
import Foundation

@main
struct Kenv: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "kenv",
        abstract: "Manage environment variables in the macOS keychain",
        subcommands: [Set.self, Unset.self, Get.self, Run.self, Remove.self, List.self]
    )
}

/// kenv set [--no-echo] <store> <variable>
/// Sets a variable in a store.
/// Reads the value from standard input.
/// If standard input is a pipe, it all input is read.
/// If standard input is a terminal, the input can also be terminated by an empty line,
/// and echo can be disabled with --no-echo.
extension Kenv {
    struct Set: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Set an environment variable in a store"
        )

        @Argument(help: "The store name")
        var store: String

        @Argument(help: "The variable name")
        var variable: String

        @Flag(help: "Do not display the value while it is entered")
        var noEcho: Bool = false

        func validate() throws {
            guard isValidEnvironmentVariableName(variable) else {
                throw ValidationError("Invalid environment variable name: '\(variable)'")
            }
        }

        func run() throws {
            let value = try readValue()
            let manager = StoreManager()
            try manager.setVariable(store: store, name: variable, value: value)
        }

        private func readValue() throws -> String {
            let isTerminal = FileHandle.standardInput.isTerminal

            if isTerminal {
                fputs("Enter value: ", stderr)
            }

            let echoDisabled = isTerminal && noEcho
            if echoDisabled {
                try Terminal.disableEcho()
            }
            defer {
                if echoDisabled {
                    Terminal.restoreEcho()
                }
            }

            var lines: [String] = []
            while let line = readLine(strippingNewline: false) {
                if isTerminal && line == "\n" {
                    break
                }
                lines.append(line)
            }

            var value = lines.joined()
            if value.hasSuffix("\n") {
                value.removeLast()
            }

            return value
        }
    }
}

/// kenv unset <store> <variable>
/// Deletes a variable from a store, and deletes the store if no variables are left.
extension Kenv {
    struct Unset: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Remove an environment variable from a store"
        )

        @Argument(help: "The store name")
        var store: String

        @Argument(help: "The variable name")
        var variable: String

        func run() throws {
            let manager = StoreManager()
            try manager.unsetVariable(store: store, name: variable)
        }
    }
}

/// kenv get [--export] <store> [<variable>]
/// Reads variables from a store and writes them to standard output in shell script form.
/// If a variable name is specified, reads only that variable.
/// Otherwise, reads all variables.
extension Kenv {
    struct Get: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Get environment variables from a store"
        )

        @Argument(help: "The store name")
        var store: String

        @Argument(help: "Optional variable name to get")
        var variable: String?

        @Flag(name: .long, help: "Add 'export ' prefix to each line")
        var export: Bool = false

        func run() throws {
            let manager = StoreManager()

            if let variable = variable {
                guard let value = try manager.getVariable(store: store, name: variable) else {
                    throw StoreError.variableNotFound(store: store, name: variable)
                }
                print(formatEnvLine(name: variable, value: value, export: export))
            } else {
                let variables = try manager.getAllVariables(store: store)
                for name in variables.keys.sorted() {
                    print(formatEnvLine(name: name, value: variables[name]!, export: export))
                }
            }
        }
    }
}

/// kenv run <store> <command> [..]
/// Runs a given command (with optional arguments), with the variables from a given store in its environment.
extension Kenv {
    struct Run: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Run a command with environment variables from a store"
        )

        @Argument(help: "The store name")
        var store: String

        @Argument(parsing: .captureForPassthrough, help: "The command and arguments to run")
        var command: [String]

        func run() throws {
            guard !command.isEmpty else {
                throw ValidationError("Command is required")
            }

            let manager = StoreManager()
            let variables = try manager.getAllVariables(store: store)

            // Set environment variables
            for (name, value) in variables {
                setenv(name, value, 1)
            }

            // Execute the command
            let executablePath = command[0]
            let args = command
            let cArgs = args.map { strdup($0) } + [nil]
            execvp(executablePath, cArgs)

            // If execvp returns, it failed
            let errorCode = errno
            throw RuntimeError("Failed to execute '\(executablePath)': \(String(cString: strerror(errorCode)))")
        }
    }
}

/// kenv rm <store>
/// Remove an entire store from the keychain.
extension Kenv {
    struct Remove: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Remove a store"
        )

        @Argument(help: "The store name")
        var store: String

        func run() throws {
            let manager = StoreManager()
            try manager.deleteStore(store)
        }
    }
}

/// kenv list
/// List all available stores in the keychain.
extension Kenv {
    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List available stores"
        )

        func run() throws {
            let manager = StoreManager()
            let stores = try manager.listStores()
            for store in stores {
                print(store)
            }
        }
    }
}

/// A runtime error.
struct RuntimeError: Error, LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}

/// Utility extension to determine whether a file handle is connected to a terminal.
extension FileHandle {
    var isTerminal: Bool {
        isatty(fileDescriptor) == 1
    }
}
