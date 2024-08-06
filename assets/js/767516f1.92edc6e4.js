"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[556],{57159:e=>{e.exports=JSON.parse('{"functions":[],"properties":[],"types":[{"name":"PreHookEvent","desc":"Note that Update will run on any operation that saves the datastore e.g. :Save()","lua_type":"\\"Open\\" | \\"Close\\" | \\"Update\\" | \\"Read\\"","source":{"line":10,"path":"src/Types.luau"}},{"name":"PostHookEvent","desc":"Note that Update will run on any operation that saves the datastore e.g. :Save()","lua_type":"\\"Open\\" | \\"Close\\" | \\"Update\\" | \\"Read\\"","source":{"line":19,"path":"src/Types.luau"}},{"name":"FailReason","desc":"","lua_type":"\\"RobloxAPIFail\\" | \\"InvalidDataNotHandled\\" | \\"SessionLocked\\" | \\"MigrationFailed\\"","source":{"line":26,"path":"src/Types.luau"}},{"name":"Result<T>","desc":"","lua_type":"({ success: true, data: T } | { success: false, failReason: FailReason, errorMessage: string, data: nil })","source":{"line":33,"path":"src/Types.luau"}},{"name":"Migrations<T>","desc":"Data format versions start at 0. The first migration should migrate from 0 to 1.\\n\\nIf you have data existing in the key before you open a Document, this will be considered version 0 and migrations will run.\\n\\nIf backwardsCompatible is false, loading this version and later versions in an older server without this migration defined will fail.\\n\\nThe current version is defined by the length of this array.","lua_type":"{ { backwardsCompatible: boolean, migrate: (data: unknown) -> unknown, } }","source":{"line":57,"path":"src/Types.luau"}}],"name":"DocumentService","desc":"Namespace containing public classes and types for DocumentService.\\n\\nContains the classes `DocumentService.DocumentStore` and `DocumentService.Util`.\\n\\nExample\\n```lua\\n\\tlocal DocumentStore = require(path/to/documentservice).DocumentStore\\n\\tlocal store = DocumentStore.new(...)\\n```","source":{"line":32,"path":"src/init.luau"}}')}}]);