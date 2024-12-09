---
sidebar_position: 8
---

# Error Handling

In DocumentService, anything that is definitely a problem with your code will throw an explicit
Luau error. Examples of this include your migrations erroring, or trying to update data in a way
that would break the schema. These also won't fire any signals or hooks. You shouldn't need
to explicitly catch these.

Other things, where there is a possibility the problem is external (e.g. data modified, Roblox API failure, session locks) return errors through the `Result` type. These should be explicitly caught.