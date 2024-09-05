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

See [README.md](https://github.com/anthony0br/DocumentService/README.md) for more information.