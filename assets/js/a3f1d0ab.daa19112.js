"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[246],{67310:e=>{e.exports=JSON.parse('{"functions":[{"name":"new","desc":"Creates a new DocumentStore\\n\\n:::warning\\nThis should only be called once per server for each DataStore in a live game.\\nIf there are multiple instances of a DocumentStore for one key, any Documents\\nwill be treated as if they are from different sessions. This is useful for\\nunit testing but can lead to weird bugs in production.\\n:::","params":[{"name":"dataStore","desc":"The object returned by DataStoreService:GetDataStore()","lua_type":"DataStore"},{"name":"check","desc":"A type check function for your data, errors if types are invalid","lua_type":"(unknown) -> (boolean, T)"},{"name":"default","desc":"Default values, which are set if keys are empty","lua_type":"Table<T>"},{"name":"migrations","desc":"Fixes invalid data e.g. through migrations. Unfixable data should be reset.","lua_type":"Migrations<T>\\n"}],"returns":[{"desc":"","lua_type":"DocumentStore"}],"function_type":"static","source":{"line":51,"path":"src/DocumentStore.luau"}},{"name":"GetDocument","desc":"Gets the document for the key given, or creates one if it does not exist.","params":[{"name":"self","desc":"","lua_type":"DocumentStore<T>"},{"name":"key","desc":"","lua_type":"string"}],"returns":[{"desc":"","lua_type":"Document"}],"function_type":"static","source":{"line":84,"path":"src/DocumentStore.luau"}},{"name":"CloseAllDocuments","desc":"Closes all documents as fast as possible","params":[{"name":"self","desc":"","lua_type":"DocumentStore<T>"}],"returns":[],"function_type":"static","source":{"line":107,"path":"src/DocumentStore.luau"}},{"name":"isDocumentStore","desc":"Checks whether a metatable passed is a DocumentStore","params":[{"name":"instance","desc":"","lua_type":"metatable"}],"returns":[{"desc":"is it a DocumentStore","lua_type":"isDocumentStore"}],"function_type":"static","source":{"line":135,"path":"src/DocumentStore.luau"}}],"properties":[],"types":[],"name":"DocumentStore","desc":"A struct that holds information about all Documents within a DataStore and provides a less\\nrepetitive way of instantiating documents. This can be seen as an abstraction over a DataStore.","source":{"line":14,"path":"src/DocumentStore.luau"}}')}}]);