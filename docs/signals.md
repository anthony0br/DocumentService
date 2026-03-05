---
sidebar_position: 8
---

# Signals & Hooks

## Signals

DocumentService provides 5 signals:
UpdatedSignal, OpenedSignal, ReadSignal, ClosedSignal, CacheChangedSignal.

These signals allow you to wait for a document to be open before modifying it or
to tap into cache changes (e.g. for replication), for example. They also
implement the Once and cancellation functionality through `:Once` and `:Disconnect`.

They are implemented with sleitnick signals, so listeners are wrapped in a task.spawn
and hence will run immediately (and before the method returns), until a yield
is encountered, and will run in reverse order to the order they are added.

## Hooks

Hooks can be useful for debugging or logging. Use signals in new work instead.

DocumentService has a before-hooks API: `HookBefore` and `OnceBefore`.

Hooks run sequentially in the order they are added and, generally, should not
yield. If a hook yields, it will yield the method that triggered it.

Hooks cannot mutate arguments.

`HookBefore` returns a cancel function. This will clean up the hook and stop it
from running again in response to any future events. Note that once an event
happens, the sequence of hooks to run is fixed and cannot be changed while the
hooks are running for that particular event.

The supported hook events are: `"Open"`, `"Close"`, `"Update"`, and `"Read"`.