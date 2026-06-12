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


Caveats
-------

If the executable changes (update, rebuild, etc.), kenv needs to be authorized to access its secrets again. The first time you access a store after an update, you will be prompted for your password. Click "always allow" to restore kenv's access. This is because while kenv gets permission from the OS to work with secrets it creates by default, if you build and install a new version, that version will not inherit this permission for existing secrets. This is a separate permission from touch ID based authentication (or password based) that's required when you actually use the secrets.


Third-Party Dependencies
------------------------

- Swift Argument Parser: https://github.com/apple/swift-argument-parser
