"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[972],{24936:e=>{e.exports=JSON.parse('{"functions":[{"name":"new","desc":"Creates a new Document class\\n\\nDon\'t create more than one Document for the same key, they will be considered different sessions.","params":[{"name":"props","desc":"","lua_type":"DocumentProps"}],"returns":[{"desc":"","lua_type":"Document<T>\\n"}],"function_type":"static","private":true,"source":{"line":282,"path":"src/Document.luau"}},{"name":"Open","desc":"Validates the document if one exists, creates a default document if no\\ndocument exists, or creates a document with the data that is in the given\\nkey if the key hasn\'t been used with DocumentService before.\\n\\nOpening a session-locked document will enable periodic autosaves until it is\\nclosed.\\n\\nYou must open a document before reading or writing to it.\\n\\n:::info\\nIf the document is locked by another session, this method will wait and\\nretry up to 5 times, and yields until the retries are exhausted or the lock\\nis removed. Therefore, you should not use this method to check if the\\nDocument is being used by another session.\\n:::\\n\\n:::warning\\nYou should check the value of `success`, and handle failures by checking\\nthe value of `reason`. The possible `reason`s for each method are defined in\\nthe return type.\\n:::","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[{"desc":"","lua_type":"OpenResult<T>"}],"function_type":"static","yields":true,"source":{"line":365,"path":"src/Document.luau"}},{"name":"OpenAndUpdate","desc":"Opens, and also runs a transform function on the data. Useful for\\nnon-session-locked data for shared entities, where one-off updates might\\nbe needed.\\n\\nWill throw a Luau error if the transform produces invalid or unsavable data.\\n\\nRuns both Open and Update hooks and signals, including fail hooks.","params":[{"name":"self","desc":"","lua_type":"Document<T>"},{"name":"transform","desc":"","lua_type":"Transform<T>"}],"returns":[{"desc":"","lua_type":"OpenResult<T>"}],"function_type":"static","yields":true,"source":{"line":606,"path":"src/Document.luau"}},{"name":"Steal","desc":"Marks the lock as stolen. The next `:Open` call will ignore any existing\\nlocks.\\n\\n:::info\\nGenerally, it is recommended to call `:Steal` and then `:Open` in the case\\nthat the initial `:Open` fails due to `SessionLockedError`.\\n:::\\n\\n:::warning\\nDo not use this unless you are very sure the previous session is dead, or\\nyou could cause data loss. Only usable on session-locked Documents.\\n:::","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[],"function_type":"static","yields":true,"source":{"line":647,"path":"src/Document.luau"}},{"name":"GetOpenedSignal","desc":"Retrieves a signal that is fired when the document is opened. Note that this will\\nbe fired on completion of any `:Open`, even if it failed.","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[{"desc":"","lua_type":"Signal<OpenResult<T>>"}],"function_type":"static","yields":true,"source":{"line":662,"path":"src/Document.luau"}},{"name":"GetClosedSignal","desc":"Retrieves a signal that is fired when the document is closed. Note that this will\\nbe fired on completion of any `:Close`, even if it failed.","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[{"desc":"","lua_type":"Signal<WriteResult<T?>"}],"function_type":"static","yields":true,"source":{"line":674,"path":"src/Document.luau"}},{"name":"GetUpdatedSignal","desc":"Retrieves a signal that is fired when the document is updated.\\nFor example, this will be fired after an autosave or after you call :`Save()`.\\nNote that this will be fired on completion of any `:Update`, even if it failed.","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[{"desc":"","lua_type":"Signal<WriteResult<T>>"}],"function_type":"static","yields":true,"source":{"line":687,"path":"src/Document.luau"}},{"name":"GetReadSignal","desc":"Retrieves a signal that is fired when the document is read. Note that this will\\nbe fired on completion of any `:Read`, even if it failed.","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[{"desc":"","lua_type":"Signal<ReadResult<T>>"}],"function_type":"static","yields":true,"source":{"line":699,"path":"src/Document.luau"}},{"name":"GetCacheChangedSignal","desc":"Retrieves a signal that is fired when the document\'s cache is set.","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[{"desc":"","lua_type":"Signal<T>"}],"function_type":"static","yields":true,"source":{"line":710,"path":"src/Document.luau"}},{"name":"IsOpenAvailable","desc":"Returns a false Result if Document is either:\\ni. Currently open in this server\\nii. Currently locked by another session\\n\\nOtherwise returns a true Result.\\n\\nIf props.lockSessions is false, this will always return a true Result.\\n\\n:::tip\\nYou can use this to check if a player is active to avoid data loss while\\nediting data from another server.\\n:::","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[{"desc":"","lua_type":"Result<boolean, RobloxAPIError>"}],"function_type":"static","yields":true,"source":{"line":732,"path":"src/Document.luau"}},{"name":"IsOpen","desc":"Returns whether the document is open or not","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[{"desc":"","lua_type":"boolean"}],"function_type":"static","source":{"line":783,"path":"src/Document.luau"}},{"name":"Close","desc":"Closes the document, so it cannot be edited.\\n\\nThe document must be open before using this method.\\n\\nIf session locked, will save the document, remove the lock, and\\ncancel autosaves first. If this fails, the document will not be closed.\\n\\nIf the Close performs a Save, Result.data will be the data saved.","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[{"desc":"","lua_type":"WriteResult<T?>"}],"function_type":"static","yields":true,"source":{"line":801,"path":"src/Document.luau"}},{"name":"IsClosing","desc":"Returns true if `:Close` has been called and is incomplete.","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[{"desc":"","lua_type":"boolean"}],"function_type":"static","source":{"line":853,"path":"src/Document.luau"}},{"name":"SetCache","desc":"Sets the cache.\\n\\nThe document must be open before using this method. You can only use cache for session-locked data.\\n\\n:::warning\\nNever yield between a GetCache and a SetCache while modifying data or you may revert data.\\n:::\\n\\n:::warning\\nYour cache should always pass your check function, otherwise autosaves\\nmay error.\\n:::\\n\\n:::info\\nYou must use immutable operations on cache, i.e. clone any table you intend to edit.\\n:::","params":[{"name":"self","desc":"","lua_type":"Document<T>"},{"name":"newCache","desc":"","lua_type":"T"}],"returns":[{"desc":"","lua_type":"T"}],"function_type":"static","source":{"line":878,"path":"src/Document.luau"}},{"name":"GetCache","desc":"Retrieves the cache.\\n\\nThe document must be open before using this method. You can only use cache for session-locked data.\\n\\n:::info\\nYou must use immutable operations on cache, i.e. clone any table you intend to edit.\\n:::","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[{"desc":"","lua_type":"T"}],"function_type":"static","source":{"line":900,"path":"src/Document.luau"}},{"name":"Update","desc":"Performs an atomic transaction on the Document, writing to the DataStore.\\n\\nThe document must be open before using this method.\\n\\nIf using session locking, passing a transform is equvialent to calling\\n`SetCache` with the transformed data and then `Save`.\\nIt is recommended you do this instead and reserver the transform\\nfunction for non-session-locked data.\\nIf the Save fails, the cache will still be updated.\\n\\nThrows if data is not storable or the transform return value is invalid.\\n\\n:::tip\\nDue to Luau limitations with the old solver, you will get the\\nbest experience if you manually annotate the type of the transform parameter.\\n:::\\n\\n:::warning\\nThe transform function must not yield, and shouldn\'t rely on any data\\nfrom outside. It must follow the rules of what is storable in Data Stores.\\n:::\\n\\n:::warning\\nAssumes the data that is already in Data Stores is valid since the last\\n`:Open`. If it isn\'t, and this is not corrected by the transform, this\\nmethod will throw a luau error.\\n:::\\n\\n:::warning\\nIf you are using session locking, your transform needs to use immutable\\noperations (in the same way updating cache does).\\n:::\\n\\n:::warning\\nIf your transform errors, the update will be aborted and the error\\nwill be thrown in a new thread (this is Roblox behaviour).\\n:::\\n\\n:::info\\nUnlike `Open`, this method will not retry if the lock is stolen, and will\\ninstead return a `SessionLockedError` after the first attempt.\\n:::","params":[{"name":"self","desc":"","lua_type":"Document<T>"},{"name":"transform","desc":"Transform function for the transaction.","lua_type":"Transform<T>"}],"returns":[{"desc":"","lua_type":"WriteResult<T>"}],"function_type":"static","yields":true,"source":{"line":956,"path":"src/Document.luau"}},{"name":"Save","desc":"Saves a Document\'s cache to its DataStore. Equivalent to calling Update\\nwithout transforming the data.\\n\\nThe document must be open and locked to use this method.\\n\\nReturns a WriteResult with the data field being the data saved to Data Stores.","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[{"desc":"","lua_type":"WriteResult<T>"}],"function_type":"static","yields":true,"source":{"line":1113,"path":"src/Document.luau"}},{"name":"Erase","desc":"Erases all data associated with the key.\\n\\nThe document must not be open. It is up to you to check if the document\\nis open elsewhere, e.g. via `IsOpenAvailable`.\\n\\nSatisfies compliance with GDPR right of erasure.\\n\\nDoes not run hooks.","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[{"desc":"","lua_type":"Result<nil, RobloxAPIError>"}],"function_type":"static","yields":true,"source":{"line":1136,"path":"src/Document.luau"}},{"name":"Read","desc":"Reads the latest data stored in Data Stores.\\n\\nRuns migrations and the check function, but does not save changes.\\n\\nThis may be called while the document is not open.\\n\\n:::warning\\nA `SchemaError` will be returned if document has never been opened before,\\nso it is strongly recommended to handle this case, and Open the document\\nbefore reading it if possible. This includes when migrating from no library.\\n:::\\n\\nRuns Read hooks.","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[{"desc":"","lua_type":"Result<any, RobloxAPIError | SchemaError | CheckError | BackwardsCompatibilityError>"}],"function_type":"static","yields":true,"source":{"line":1172,"path":"src/Document.luau"}},{"name":"HookBefore","desc":"Attaches a hook which occurs before the event.\\n\\nNote that if a hook yields, it will yield all methods that call it. Hooks\\nare called in the order they are added.\\n\\nHooks cannot currently mutate arguments.","params":[{"name":"self","desc":"","lua_type":"Document<T>"},{"name":"event","desc":"the operation to call the hook before","lua_type":"HookEvent"},{"name":"hook","desc":"a hook function that receives the arguments passed in to the operation","lua_type":"() -> ()"}],"returns":[{"desc":"a callback that removes the hook from the given hook event registry","lua_type":"cleanup"}],"function_type":"static","source":{"line":1271,"path":"src/Document.luau"}},{"name":"HookAfter","desc":"Attaches a hook which occurs after the event, before the method returns.\\n\\n\\nNote that if a hook yields, it will yield all methods that call it. Hooks\\nare called in the order they are added.\\n\\nHooks added with HookAfter only run if the operation is successful, and\\ncannot mutate the result.","params":[{"name":"self","desc":"","lua_type":"Document<T>"},{"name":"event","desc":"the operation to call the hook after","lua_type":"HookEvent"},{"name":"hook","desc":"a hook function that receives the arguments passed in to the operation","lua_type":"() -> ()"}],"returns":[{"desc":"a callback that removes the hook from the given hook event registry","lua_type":"cleanup"}],"function_type":"static","deprecated":{"version":"v1.2.0","desc":"use signals"},"source":{"line":1295,"path":"src/Document.luau"}},{"name":"HookFail","desc":"Attaches a hook which occurs after an event fails.\\n\\n\\nNote that fail hooks only run when a method returns an Err<E> type. They\\nwill not run if the method throws a Luau error due to incorrect usage.","params":[{"name":"self","desc":"","lua_type":"Document<T>"},{"name":"event","desc":"the operation to call the hook after","lua_type":"HookEvent"},{"name":"hook","desc":"a hook function that receives the arguments passed in to the operation","lua_type":"() -> ()"}],"returns":[{"desc":"a callback that removes the hook from the given hook event registry","lua_type":"cleanup"}],"function_type":"static","deprecated":{"version":"v1.2.0","desc":"use signals"},"source":{"line":1316,"path":"src/Document.luau"}},{"name":"OnceBefore","desc":"Attaches a single-use hook which occurs before the event.","params":[{"name":"self","desc":"","lua_type":"Document<T>"},{"name":"event","desc":"the operation to call the hook before","lua_type":"HookEvent"},{"name":"hook","desc":"a hook function that receives the arguments passed in to the operation","lua_type":"() -> ()"}],"returns":[],"function_type":"static","source":{"line":1331,"path":"src/Document.luau"}},{"name":"OnceAfter","desc":"Attaches a single-use hook which occurs after the event, before the method returns.","params":[{"name":"self","desc":"","lua_type":"Document<T>"},{"name":"event","desc":"the operation to call the hook after","lua_type":"HookEvent"},{"name":"hook","desc":"a hook function that receives the arguments passed in to the operation","lua_type":"() -> ()"}],"returns":[],"function_type":"static","deprecated":{"version":"v1.2.0","desc":"use signals"},"source":{"line":1348,"path":"src/Document.luau"}},{"name":"OnceFail","desc":"Attaches a single-use hook which occurs after an event fails.","params":[{"name":"self","desc":"","lua_type":"Document<T>"},{"name":"event","desc":"the operation to call the hook after","lua_type":"HookEvent"},{"name":"hook","desc":"a hook function that receives the arguments passed in to the operation","lua_type":"() -> ()"}],"returns":[],"function_type":"static","deprecated":{"version":"v1.2.0","desc":"use signals"},"source":{"line":1365,"path":"src/Document.luau"}},{"name":"__tostring","desc":"","params":[{"name":"self","desc":"","lua_type":"Document<T>"}],"returns":[],"function_type":"static","ignore":true,"source":{"line":1377,"path":"src/Document.luau"}},{"name":"isDocument","desc":"Checks if a metatable passed is a Document.","params":[{"name":"instance","desc":"","lua_type":"metatable"}],"returns":[{"desc":"","lua_type":"boolean"}],"function_type":"static","source":{"line":1387,"path":"src/Document.luau"}}],"properties":[],"types":[{"name":"OpenResult<T>","desc":"","lua_type":"Result<T, RobloxAPIError | BackwardsCompatibilityError | CheckError | SessionLockedError>","source":{"line":110,"path":"src/Document.luau"}},{"name":"WriteResult<T>","desc":"","lua_type":"Result<T, RobloxAPIError | SessionLockedError | SchemaError>","source":{"line":117,"path":"src/Document.luau"}},{"name":"DocumentProps","desc":":::info\\nYour check function should return true if the provided table contains all of\\nthe correctly typed fields from T (the type of your data schema).\\n\\nThe check function should accept tables with additional properties, and\\nshould not mutate the table in any way. The second return value exists to\\nassist you by typechecking the interfaces you write, but is not currently\\nused, to ensure data is not lost when loaded by an old server.\\n\\nFor example, with [Guard](https://util.redblox.dev/guard.html)\\n```\\n\\tlocal TestDataInterface = {\\n\\t\\tDocument = Guard.String,\\n\\t\\tService = Guard.Number,\\n\\t}\\n\\n\\tlocal function testDataCheck(value: unknown): TestData\\n\\t\\tassert(type(value) == \\"table\\")\\n\\t\\tlocal Value: any = value\\n\\n\\t\\treturn {\\n\\t\\t\\tDocument = TestDataInterface.Document(Value.Document),\\n\\t\\t\\tService = TestDataInterface.Service(Value.Service),\\n\\t\\t}\\n\\tend\\n```\\n\\nIf you do not wish to dynamically check your data, write a placeholder with typecasting.\\n:::","fields":[{"name":"key","lua_type":"string","desc":"The datastore key"},{"name":"dataStore","lua_type":"DataStoreInterface","desc":"The object returned by DataStoreService:GetDataStore()"},{"name":"check","lua_type":"(unknown) -> (boolean, T)","desc":"A pure function that verifies your data schema"},{"name":"default","lua_type":"T","desc":"Default values, which are set if keys are empty"},{"name":"migrations","lua_type":"Types.Migrations","desc":"Migrations"},{"name":"lockSessions","lua_type":"boolean","desc":"Should the document be session locked?"}],"private":true,"source":{"line":273,"path":"src/Document.luau"}}],"name":"Document","desc":"An abstraction over keys in a DataStore.\\n\\nDocuments are designed to contain information about an entity in a schema.\\nThis schema is enforced by your check function, and should be changed\\nthrough migrations. You may, of course, decide to not use a schema by\\ndefining an empty check function, but this generally isn\'t recommended.\\n\\n:::tip\\nSession locking prevents your data from being edited by mutliple servers,\\nand ensures one server is finished with it before it is opened by another.\\n\\nIn DocumentService, session locking enables the use of the caching methods\\n`SetCache` and `GetCache`.\\n\\nThis is ideal for player data, or any data that needs frequent updates\\nand does not need multi-server editing.\\n:::\\n\\n:::warning\\nYou are free to edit the contents of the table in the .data field with\\na tool like DataStore Editor, but manually changing other fields could cause\\ndata loss and errors.\\n:::\\n\\n:::warning\\nTypes for your data are provided under the assumption that once a document\\nis opened, the underlying data held in Data Stores is not updated\\nexternally in a way that changes its type.\\n:::","source":{"line":46,"path":"src/Document.luau"}}')}}]);