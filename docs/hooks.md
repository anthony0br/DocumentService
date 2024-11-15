---
sidebar_position: 8
---

# Signals & Hooks

## Signals

DocumentService provides 5 signals:
UpdatedSignal, OpenedSignal, ReadSignal, ClosedSignal, CacheChangedSignal.

These signals allow you to wait for a document to be open before modifying it or
to tap into cache changes (e.g. for replication), for example. They also
implement the Once and cancellation functionality of after hooks, through `:Once` and `:Disconnect`.

They are implemented with sleitnick signals, so listeners are wrapped in a task.spawn
and hence will run immediately (and before the method returns), until a yield
is encountered, and will run in reverse order to the order they are added.

## Hooks

Hooks are now deprecated (except for before hooks, which can be useful
for debugging/logging). Use signals in new work instead.

To listen to and respond to events, like saving or reading data, DocumentService
has a hooks API: `HookBefore`, `HookAfter`, `OnceBefore`, and `OnceAfter`.

Hooks run sequentially in the order they are added, and generally, should not
yield.

`HookBefore` and `HookAfter` return a cancel function. This will clean up the
hook and stop it from running again in response to any future events. Note that
once an event happens, the sequence of hooks to run is fixed and cannot be changed
for while the hooks are running for that particular event.