# DocumentService - A powerful Roblox datastore library

DocumentService is a fully strictly typed Luau library for saving data with Roblox DataStores.

DocumentService provides a DataStore abstraction, DocumentStore, which holds data about entities within Documents.

This project is currently in its early stages and should not be used in production.

## Features
- Fully strictly typed: data is typed (intellisense and typechecking on data you read from DataStores!), and the whole library is written in --!strict.
- Immutable cache and autosaves.
- Migrations, inspired by Lapis. (If you're used to :Reconcile, you can do this with migrations).
- Data validation - use any runtime type checker for your data, and use the static types!
- Support for both session-locking and multi-server editing (not simultaneously)
- Run hooks before and after operations, e.g. logging.
- Automatic retry with exponential backoff.
- Migrate from no library, or another library if you're brave.
- Checks your data can be stored in JSON to avoid silent errors.
- No dependencies or complicated APIs like Promises. Methods yield, and you can wrap them in any coroutine abstraction you like.

## Long-term goals
- ACID transactions involving multiple Documents. Please get in touch if you can help with this!

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
