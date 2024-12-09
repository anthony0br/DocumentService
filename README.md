# DocumentService - A powerful, schematised Roblox datastore library

DocumentService is a strictly typed Luau library for saving data with Roblox DataStores.
It can be used for sesssion-locked data, such as player data, or for non-session-locked data, like
shared groups or houses.

See the [docs](https://anthony0br.github.io/DocumentService/docs/intro) for more information.

## Features
- Fully typed API. This means you get full intellisense and typechecking on your data,
and on every API method, including possible errors for each method.
- Superior Rust-inspired error handling (Result types).
- Immutable cache - preventing bugs caused by updates interfering with eachother.
- Does auto-saves and BindToClose saves for you.
- Migrations, inspired by nezuo's Lapis.
- Validate your data with support for runtime and static typechecking.
- Documents can be session-locked, or not (to allow multi-server editing).
- Signals & hooks to 'tap in' to when operations start & finish.
- Automatic retries with exponential backoff.
- Migrate from no library, or another library if you're brave.
- Checks your data can be stored in JSON to avoid silent errors.
- Supports DataStore dependency injection - use any Mock DataStore you like.
- Internally, completely strictly typed (Luau "--!strict" mode), and high
code quality standards with high test coverage.

## Ready for production

DocumentService is currently used in production in [Croydon: The London Transport Game](https://www.roblox.com/games/8265622251/V1-3-2-Croydon-The-London-Transport-Game). It powers both player data and the custom companies feature
(these are complex shared social groups). In its first few hours it flawlessly handled over 300,000 data updates and performed tens of thousands of migrations, migrating from no library (the game originally used a different, fragile system).

## Installation

### Method 1: Wally
Add `DocumentService = "anthony0br/documentservice@LATEST_VERSION"` to your `wally.toml`.

### Method 2: Manual
DocumentService has no dependencies so you can just copy and paste the contents of
`target/roblox` into your project.

## Long-term goals
- Split DocumentService's API up into separate classes for session-locked and non-session-locked documents,
that share common functionality.
- ACID transactions involving multiple Documents. Please get in touch if you can help with this!
- See the [issues](https://github.com/anthony0br/DocumentService/issues) page to discuss ways to make DocumentService better!

## Inspiration
This library takes inspiration from Lapis, ProfileService, keyForm, and kampfkarren's blog.
These are all great projects but didn't meet my needs in some way.

## Contributing
Contributions are accepted. Please follow the Roblox Lua Style Guide and write unit tests.

To build for Roblox (this process is automated through a GitHub action, but in case you need it):
1. Install necessary tools (see rokit.toml).
2. Run `rojo sourcemap source.project.json -o sourcemap.json`. It is necessary to generate a sourcemap of the src folder so darklua can convert our requires.
3. Run `darklua process src target/roblox`.

## Contact
Most discussions relating to this project happen on the [Roblox OSS Discord Server](https://discord.gg/rhwQFJksJD) (go to the DocumentService thread under projects).