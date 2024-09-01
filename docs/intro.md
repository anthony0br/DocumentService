---
sidebar_position: 1
---

#  Introduction

DocumentService is a fully strictly typed Luau library for saving data with Roblox DataStores.

DocumentService provides a DataStore abstraction, DocumentStore, which holds data about entities within Documents.

A document can represent data about anything - e.g. a player, a group, or a virtual house shared between players.

DocumentStores can be session-locked or not session-locked. DocumentStores which aren't session locked
are designed to be used for shared data which needs multiple-server editing. This will disable some methods,
such as caching - you should write directly to the DataStore every time you make an update. You should use
session locking where you can to take full advantage of the library.

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

See [README.md](https://github.com/anthony0br/DocumentService/blob/v1.0.0-rc.9/README.md) for more.