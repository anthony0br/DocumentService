# DocumentService

Goals of DocumentService
- Type checking and migration support
- Few dependencies and simple API: DocumentService will not lock you into using a specific implementation of Promise or Future. Instead, it just yields when it needs to, and lets you implement your own async behaviour.
- Transaction based API as the core, auto-saving for rapidly changing data can be added on later
- Safe transactions involving multiple keys (e.g. trades)
- Session-locking

# Documentation

## DocumentService

## DocumentStore

## Document