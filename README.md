kenv
====

A command line tool for macOS that stores environment variables in the login keychain, and executes programs with those variables in their environment. Access to the variables needs authentication, touch ID is supported.

The main use case is programs that read secrets like API keys from their environment, but kenv can also be used to manage named profiles for programs that are configured through sets of environment variables, even if they're not secret.


Example Usage
-------------

Store your API key in the login keychain, in a store called `cloud`:

    kenv set cloud API_KEY

You can type the secret in, paste it, or if it's in a file, use shell redirection. When typing or pasting, enter an empty line after the secret to finish input.

Each store can contain multiple environment variables.

To run a program (here: `tofu apply`) with secrets from the `cloud` store in its environment:

    kenv run cloud tofu apply

There are other commands to interact with stores and secrets. Run `kenv` without arguments to see them.


Installation
------------

    swift build -c release
    cp .build/release/kenv /your/favorite/binary/path


Caveats
-------

If the executable changes (update, rebuild, etc.), kenv needs to be authorized to access its secrets again. The first time you access a store after an update, you will be prompted for your password. Click "always allow" to restore kenv's access. This is separate from touch ID authentication and does not disable it.


Third-Party Dependencies
------------------------

- Swift Argument Parser: https://github.com/apple/swift-argument-parser
