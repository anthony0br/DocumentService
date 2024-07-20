# DocumentService

## Goals
- Type checking and migration support
- Few dependencies and simple API: DocumentService will not lock you into using a specific implementation of Promise or Future. Instead, it just yields when it needs to, and lets you implement your own async behaviour.
- Transaction based API as the core, auto-saving for rapidly changing data can be added on later
- Safe transactions involving multiple keys (e.g. trades)
- Hooks. These can be used for automated logging, automated retries, migrating data on then re-trying fail to open, and more
- Session-locking

## What it does not do:
- Throttling. If you reach limits, you are probably using transactions too frequently. In the future an extended class could be created from Document to enable cacheing and auto-saves (for less important transactions), queueing and throttling. You should ratelimit remotes that call document updates.
- Mock DataStores. I plan to provide an interface and add the ability to inject a different datastore class, but this mock class itself is outside the scope of this project.

## Limitations:
- Luau type checking is not perfect

If you think I could achieve these goals better please open an Issue or contact me!

# Documentation

## DocumentService

## DocumentStore

## Document