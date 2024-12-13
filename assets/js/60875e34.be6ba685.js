"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[554],{3905:(e,t,a)=>{a.d(t,{Zo:()=>s,kt:()=>h});var n=a(67294);function r(e,t,a){return t in e?Object.defineProperty(e,t,{value:a,enumerable:!0,configurable:!0,writable:!0}):e[t]=a,e}function o(e,t){var a=Object.keys(e);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);t&&(n=n.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),a.push.apply(a,n)}return a}function i(e){for(var t=1;t<arguments.length;t++){var a=null!=arguments[t]?arguments[t]:{};t%2?o(Object(a),!0).forEach((function(t){r(e,t,a[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(a)):o(Object(a)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(a,t))}))}return e}function l(e,t){if(null==e)return{};var a,n,r=function(e,t){if(null==e)return{};var a,n,r={},o=Object.keys(e);for(n=0;n<o.length;n++)a=o[n],t.indexOf(a)>=0||(r[a]=e[a]);return r}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(n=0;n<o.length;n++)a=o[n],t.indexOf(a)>=0||Object.prototype.propertyIsEnumerable.call(e,a)&&(r[a]=e[a])}return r}var u=n.createContext({}),c=function(e){var t=n.useContext(u),a=t;return e&&(a="function"==typeof e?e(t):i(i({},t),e)),a},s=function(e){var t=c(e.components);return n.createElement(u.Provider,{value:t},e.children)},d="mdxType",p={inlineCode:"code",wrapper:function(e){var t=e.children;return n.createElement(n.Fragment,{},t)}},m=n.forwardRef((function(e,t){var a=e.components,r=e.mdxType,o=e.originalType,u=e.parentName,s=l(e,["components","mdxType","originalType","parentName"]),d=c(a),m=r,h=d["".concat(u,".").concat(m)]||d[m]||p[m]||o;return a?n.createElement(h,i(i({ref:t},s),{},{components:a})):n.createElement(h,i({ref:t},s))}));function h(e,t){var a=arguments,r=t&&t.mdxType;if("string"==typeof e||r){var o=a.length,i=new Array(o);i[0]=m;var l={};for(var u in t)hasOwnProperty.call(t,u)&&(l[u]=t[u]);l.originalType=e,l[d]="string"==typeof e?e:r,i[1]=l;for(var c=2;c<o;c++)i[c]=a[c];return n.createElement.apply(null,i)}return n.createElement.apply(null,a)}m.displayName="MDXCreateElement"},66351:(e,t,a)=>{a.r(t),a.d(t,{assets:()=>u,contentTitle:()=>i,default:()=>p,frontMatter:()=>o,metadata:()=>l,toc:()=>c});var n=a(87462),r=(a(67294),a(3905));const o={sidebar_position:4},i="Player data guide",l={unversionedId:"tutorial",id:"tutorial",title:"Player data guide",description:"This page covers setting up player data for your game in more detail.",source:"@site/docs/tutorial.md",sourceDirName:".",slug:"/tutorial",permalink:"/DocumentService/docs/tutorial",draft:!1,editUrl:"https://github.com/anthony0br/DocumentService/edit/main/docs/tutorial.md",tags:[],version:"current",sidebarPosition:4,frontMatter:{sidebar_position:4},sidebar:"defaultSidebar",previous:{title:"Opening a player document",permalink:"/DocumentService/docs/opening"},next:{title:"Developer Products",permalink:"/DocumentService/docs/products"}},u={},c=[{value:"Setup",id:"setup",level:2},{value:"Player Data Structure",id:"player-data-structure",level:2},{value:"Creating the DocumentStore",id:"creating-the-documentstore",level:2},{value:"Best Practices",id:"best-practices",level:2},{value:"Editing Player Data",id:"editing-player-data",level:2},{value:"Accessing data from the client",id:"accessing-data-from-the-client",level:2}],s={toc:c},d="wrapper";function p(e){let{components:t,...a}=e;return(0,r.kt)(d,(0,n.Z)({},s,a,{components:t,mdxType:"MDXLayout"}),(0,r.kt)("h1",{id:"player-data-guide"},"Player data guide"),(0,r.kt)("p",null,"This page covers setting up player data for your game in more detail."),(0,r.kt)("h2",{id:"setup"},"Setup"),(0,r.kt)("p",null,"Get the required services and libraries."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local DataStoreService = game:GetService("DataStoreService")\n\nlocal DocumentService = require(path.to.DocumentService)\nlocal Guard = require(path.to.Guard)\n')),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"Guard"),": Used to validate data types.")),(0,r.kt)("h2",{id:"player-data-structure"},"Player Data Structure"),(0,r.kt)("p",null,"You need to define a structure for your data - this is called a schema."),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"Define a type"),":\nIt is useful to define your schema as a type."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},"type DataSchema = {\n    Coins: number,\n    XP: number,\n}\n")),(0,r.kt)("p",null,"You can add more fields as needed."),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"Check function"),":"),(0,r.kt)("p",null,"The check function takes an unknown value (the value from Data Stores) and\nverifies that it meets the correct format by returning a boolean. The second return type must match the\ntype of your default - however, this is only to help you prevent mistakes."),(0,r.kt)("p",null,"A good way to create a check function is to use ",(0,r.kt)("a",{parentName:"p",href:"https://util.redblox.dev/guard.html"},"Guard"),". Create a standard interface check in Guard, and then wrap it with Guard.Check so it returns a boolean."),(0,r.kt)("p",null,"Note that, while it is recommended that you use a check function, you can of course write one\nthat always returns true if you are confident data won't be mistakenly corrupted!\nIn the future, the check function may be optional."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local DataInterface = {\n    Coins = Guard.Integer,\n    XP = Guard.Integer,\n}\n\nlocal function dataCheck(value: unknown): DataSchema\n    assert(type(value) == "table", "Data must be a table")\n    local Value: any = value\n\n    return {\n        Coins = DataInterface.Coins(Value.Coins),\n        XP = DataInterface.XP(Value.XP),\n    }\nend\n')),(0,r.kt)("h2",{id:"creating-the-documentstore"},"Creating the DocumentStore"),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"DocumentStore"),":\nSet up the ",(0,r.kt)("a",{parentName:"p",href:"https://anthony0br.github.io/DocumentService/api/DocumentStore/"},"DocumentStore")," for player data."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local PlayerDocumentStore = DocumentService.DocumentStore.new({\n    dataStore = DataStoreService:GetDataStore("PlayerData"),\n    check = Guard.Check(dataCheck),\n    default = {\n        Coins = 0,\n        XP = 0,\n    },\n    migrations = {\n        {\n            backwardsCompatible = false,\n            migrate = function()\n                -- Put a migration here!\n            end\n        }\n    },\n    -- This is an important feature of player data. It locks editing to one server\n    -- at a time, allowing us to safely cache player data and save batches of updates.\n    -- We do this through additional methods that session locking unlocks, such as\n    -- `SetCache` and `GetCache`.\n    lockSessions = true,\n})\n')),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"migrations"),": Used to mutate your schema over time."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"backwardsCompatible"),": If ",(0,r.kt)("inlineCode",{parentName:"li"},"false"),", the document with this version or later will not load in\nservers whose latest version is prior to this version. Otherwise, this version will run\non old servers. Generally, removing or changing the type of a field is not backwards compatible,\nbut adding fields is."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"lockSessions"),": Prevents multiple devices from accessing the same player's data simultaneously.")),(0,r.kt)("h2",{id:"best-practices"},"Best Practices"),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"Be very cautious of yielding:")," Transforms and cache updates should never yield. When you are updating data, if you yield and some other code makes an update, that update could be reverted. Do not update between GetCache and SetCache pairs."),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"Strict types:")," Write your scripts in strict mode to benefit fully from the type-checking features of DocumentService. Be as precise as you can with types - using ",(0,r.kt)("inlineCode",{parentName:"p"},"any")," or other loosely-defined types for your fields will have little to no benefit."),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"Use good tools:")," Roblox Studio's script editor doesn't provide great linting - luau-lsp is better\nfor taking full advantage of type-checking."),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"Seperation:")," You might want to put your default table, migrations, types and your check function in a separate file to keep things manageable and modular."),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"Use cache where you can:")," Minimise methods that call DataStore APIs, such as ",(0,r.kt)("inlineCode",{parentName:"p"},"Read")," and ",(0,r.kt)("inlineCode",{parentName:"p"},"Update"),", in\nfavour of ",(0,r.kt)("inlineCode",{parentName:"p"},"GetCache")," and ",(0,r.kt)("inlineCode",{parentName:"p"},"SetCache"),". This improves performance and reduces the chance of hitting limits."),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"Don't change your migrations:")," You should never delete a migration. You should not change migrations once they are live (unless you\nreally have to, but you should never change their effect)."),(0,r.kt)("h2",{id:"editing-player-data"},"Editing Player Data"),(0,r.kt)("p",null,"To modify the player's data on the server:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local document = YourPlayerDataModule:GetDocument(player)\n\nif not document:IsOpen() then\n    -- See "Waiting for a Document to Open" page if you need to wait for the document to be open\nend\n\n-- We need to clone the table and any sub-tables we intend to edit, since\n-- DocumentService freezes tables on SetCache.\n-- This forces immutable updates and helps you avoid creating bugs!\nlocal documentClone = table.clone(document:GetCache())\n\ndocumentClone.Coins = 99\ndocumentClone.XP = 99\ndocument:SetCache(documentClone)\n')),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"document:SetCache()"),": Updates the player's data cache, which is saved when the document is closed.")),(0,r.kt)("h2",{id:"accessing-data-from-the-client"},"Accessing data from the client"),(0,r.kt)("p",null,"You can use any usual method to replicate data, e.g. RemoteEvents."),(0,r.kt)("p",null,"More advanced methods include loleris' Replica or sending a diff generated by nezuo's DeltaCompress."))}p.isMDXComponent=!0}}]);