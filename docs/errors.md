---
sidebar_position: 8
---

# Error Handling

In DocumentService, anything that is definitely a problem with your code will throw an explicit
Luau error. Examples of this include your migrations erroring, or trying to update data in a way
that would break the schema. These also won't fire any signals or hooks. You shouldn't need
to explicitly catch these.

Other things, where there is a possibility the problem is external (e.g. data modified, Roblox API failure, session locks) return errors through the `Result` type. These should be explicitly caught.

Currently trying to open a document when the game is closing results in
an explicit error, and you are expected to check the game is not closing first.