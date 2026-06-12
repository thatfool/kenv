kenv
====

A command line tool for macOS that stores environment variables in the login keychain, and executes programs with those variables in their environment. Before accessing the variables, kenv requires authentication via touch ID or your account password (see Security Notes below for details on how this is enforced).

The main use case is programs that read secrets like API keys from their environment, but kenv can also be used to manage named profiles for programs that are configured through sets of environment variables, even if they're not secret.


Example Usage
-------------

Store your API key in the login keychain, in a store called `cloud`:

    kenv set cloud API_KEY

You can type the secret in, paste it, or if it's in a file, use shell redirection. When typing or pasting, enter an empty line after the secret to finish input.

By default, the secret is displayed while you enter it and remains visible in the terminal scrollback. Pass `--no-echo` to keep it from being displayed:

    kenv set --no-echo cloud API_KEY

Each store can contain multiple environment variables.

To run a program (here: `tofu apply`) with secrets from the `cloud` store in its environment:

    kenv run cloud tofu apply

Some programs can run a command to obtain a secret instead of reading it from the environment, often configured through a `_CMD` variant of a setting. For this, `kenv get` can print a single value with nothing around it:

    kenv get --value cloud API_KEY

There are other commands to interact with stores and secrets. Run `kenv` without arguments to see them.


Source Code
-----------

This project lives on codeberg at https://codeberg.org/snokatt/kenv

There is a mirror on GitHub at https://github.com/thatfool/kenv


Installation
------------

To install via homebrew:

    brew tap snokatt/tap https://codeberg.org/snokatt/homebrew-tap
    brew install snokatt/tap/kenv

To build from source:

    swift build -c release
    cp .build/release/kenv /your/favorite/binary/path


Security Notes
--------------

When you access a store, kenv prompts for touch ID or your account password. This check is implemented and enforced by the kenv application itself, not by the keychain: the secrets are stored as regular login keychain items, and macOS does not require touch ID to read them.

This is a deliberate trade-off. Having the keychain itself enforce touch ID would require storing the secrets in the data protection keychain with an access control list, which is only available to binaries that are code signed with the necessary entitlements. Since kenv is meant to be built from source or installed via homebrew without code signing, it uses the login keychain instead and performs the authentication step in the application.

In practice this means the secrets are protected by the standard login keychain access controls (per-application access, see Caveats below), and the touch ID prompt is an additional layer that kenv adds on top.

Separate from kenv itself, be aware of how environment variables behave once `kenv run` has placed secrets in a program's environment:

- The environment is inherited by every child process the program starts, and by their children in turn, unless a program explicitly cleans it up.
- Any process running as the same user can read the environment that another process was launched with (for example with `ps -E`).
- The superuser can read the environment of any process.

In short, treat secrets passed through the environment as visible to every process running as your user, and to root, for as long as the program is running. This is a property of environment variables in general, not of kenv. Using `kenv run` limits the exposure to the lifetime of the program, since the secrets are otherwise only stored in the keychain.

For your own projects that read secrets from the environment, one possible mitigation is to support a `*_CMD` form for sensitive settings: instead of the secret itself, the environment holds a command to execute, and your code reads the secret from that command's output. The `--value` option of `kenv get` makes it print only the value of a secret, so it can serve as such a command.


Caveats
-------

If the executable changes (update, rebuild, etc.), kenv needs to be authorized to access its secrets again. The first time you access a store after an update, you will be prompted for your password. Click "always allow" to restore kenv's access. This is because while kenv gets permission from the OS to work with secrets it creates by default, if you build and install a new version, that version will not inherit this permission for existing secrets. This is a separate permission from touch ID based authentication (or password based) that's required when you actually use the secrets.


Third-Party Dependencies
------------------------

- Swift Argument Parser: https://github.com/apple/swift-argument-parser
