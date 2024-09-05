# DocumentService - A powerful, schematised Roblox datastore library

DocumentService is a fully strictly typed Luau library for saving data with Roblox DataStores.
It can be used for sesssion-locked data, such as player data, or for non-session-locked data, like
shared groups or houses.

See the [docs](https://anthony0br.github.io/DocumentService/docs/intro) for more information.

This is a new release and, although it has been thoroughly unit tested, it hasn't yet been used 
in a live production game - as with any open source software, use it at your own risk! I am
working on adding it to my game, so this will not be a concern for too long.

## Features
- Fully strictly typed. This means you get full intellisense and typechecking on your data,
and on every API method, including possible errors for each method.
- Superior Rust-inspired error handling, with each Result for each method
providing unique intellisense on which errors you need to handle.
- Immutable cache and autosaves - preventing bugs caused by updates interfering with eachother.
- Migrations, inspired by nezuo's Lapis.
- Validate your data with support for runtime and static typechecking.
- Documents can be session-locked, or not (to allow multi-server editing).
- Run hooks before and after operations, e.g. logging.
- Automatic retry with exponential backoff.
- Migrate from no library, or another library if you're brave.
- Checks your data can be stored in JSON to avoid silent errors.
- Simple API that follows SOLID principles: session-locking a document simply extends the API.
For example, in ProfileService you need to provide a lockedHandler function, which changes the
behaviour of the method to open a Profile, but in DocumentService you can just use the
with `:IsWriteAvailable` and `:Steal` methods if you need them.
- Maintainable, strictly typed source code, that is actively maintained.
- No dependencies (like Promise). Use whatever abstractions you like, and install easily.

## Installation

### Method 1: Wally
Add `DocumentService = "anthony0br/documentservice@1.0.0` to your `wally.toml`.

### Method 2: Manual
DocumentService has no dependencies so you can just copy and paste the contents of
`target/roblox` into your project.

## Long-term goals
- ACID transactions involving multiple Documents. Please get in touch if you can help with this!
- See the [issues](https://github.com/anthony0br/DocumentService/issues) page to discuss ways to make DocumentService better!

## Inspiration
This library takes inspiration from Lapis, ProfileService, keyForm, and kampfkarren's blog.
These are all great projects but didn't meet my needs in some way.

## Contributing
Contributions are accepted. Your contributions must run in Lune directly from src and, when compiled by darklua to target/roblox, in Roblox. You should use moonwave to update/generate documentation.

To build for Roblox:
1. Install necessary tools (see aftman.toml).
2. Run `rojo sourcemap source.project.json -o sourcemap.json`. It is necessary to generate a sourcemap of the src folder so darklua can convert our requires.
3. Run `darklua process src target/roblox`.

## Contact
The best way to get in touch is to ping me in the thread in the Roblox OSS discord, or create an issue.
