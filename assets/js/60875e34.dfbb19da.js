"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[554],{3905:(e,t,n)=>{n.d(t,{Zo:()=>s,kt:()=>h});var a=n(67294);function r(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function o(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);t&&(a=a.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,a)}return n}function l(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?o(Object(n),!0).forEach((function(t){r(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):o(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function i(e,t){if(null==e)return{};var n,a,r=function(e,t){if(null==e)return{};var n,a,r={},o=Object.keys(e);for(a=0;a<o.length;a++)n=o[a],t.indexOf(n)>=0||(r[n]=e[n]);return r}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(a=0;a<o.length;a++)n=o[a],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(r[n]=e[n])}return r}var c=a.createContext({}),u=function(e){var t=a.useContext(c),n=t;return e&&(n="function"==typeof e?e(t):l(l({},t),e)),n},s=function(e){var t=u(e.components);return a.createElement(c.Provider,{value:t},e.children)},p="mdxType",d={inlineCode:"code",wrapper:function(e){var t=e.children;return a.createElement(a.Fragment,{},t)}},m=a.forwardRef((function(e,t){var n=e.components,r=e.mdxType,o=e.originalType,c=e.parentName,s=i(e,["components","mdxType","originalType","parentName"]),p=u(n),m=r,h=p["".concat(c,".").concat(m)]||p[m]||d[m]||o;return n?a.createElement(h,l(l({ref:t},s),{},{components:n})):a.createElement(h,l({ref:t},s))}));function h(e,t){var n=arguments,r=t&&t.mdxType;if("string"==typeof e||r){var o=n.length,l=new Array(o);l[0]=m;var i={};for(var c in t)hasOwnProperty.call(t,c)&&(i[c]=t[c]);i.originalType=e,i[p]="string"==typeof e?e:r,l[1]=i;for(var u=2;u<o;u++)l[u]=n[u];return a.createElement.apply(null,l)}return a.createElement.apply(null,n)}m.displayName="MDXCreateElement"},66351:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>c,contentTitle:()=>l,default:()=>d,frontMatter:()=>o,metadata:()=>i,toc:()=>u});var a=n(87462),r=(n(67294),n(3905));const o={sidebar_position:4},l="Setting Up Player Data",i={unversionedId:"tutorial",id:"tutorial",title:"Setting Up Player Data",description:"This page covers setting up player data for your game, as well as a modulescript to handle everything.",source:"@site/docs/tutorial.md",sourceDirName:".",slug:"/tutorial",permalink:"/DocumentService/docs/tutorial",draft:!1,editUrl:"https://github.com/anthony0br/DocumentService/edit/main/docs/tutorial.md",tags:[],version:"current",sidebarPosition:4,frontMatter:{sidebar_position:4},sidebar:"defaultSidebar",previous:{title:"Opening a player document",permalink:"/DocumentService/docs/opening"},next:{title:"Developer Products",permalink:"/DocumentService/docs/products"}},c={},u=[{value:"Setup",id:"setup",level:2},{value:"Player Data Structure",id:"player-data-structure",level:2},{value:"Creating the DocumentStore",id:"creating-the-documentstore",level:2},{value:"Managing Player Data",id:"managing-player-data",level:2},{value:"Best Practices",id:"best-practices",level:2},{value:"Editing Player Data",id:"editing-player-data",level:2},{value:"Accessing Data from the Client",id:"accessing-data-from-the-client",level:2}],s={toc:u},p="wrapper";function d(e){let{components:t,...n}=e;return(0,r.kt)(p,(0,a.Z)({},s,n,{components:t,mdxType:"MDXLayout"}),(0,r.kt)("h1",{id:"setting-up-player-data"},"Setting Up Player Data"),(0,r.kt)("p",null,"This page covers setting up player data for your game, as well as a modulescript to handle everything."),(0,r.kt)("h2",{id:"setup"},"Setup"),(0,r.kt)("p",null,"Get the required services and libraries."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local DataStoreService = game:GetService("DataStoreService")\n\nlocal DocumentService = require(path.to.DocumentService)\nlocal Guard = require(path.to.Guard)\n')),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"Guard"),": Used to validate data types.")),(0,r.kt)("h2",{id:"player-data-structure"},"Player Data Structure"),(0,r.kt)("p",null,"You need to define a structure for your data - this is called a schema."),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"Define a type"),":\nIt is useful to define your schema as a type."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},"type DataSchema = {\n    Coins: number,\n    XP: number,\n}\n")),(0,r.kt)("p",null,"You can add more fields as needed."),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"Check function"),":"),(0,r.kt)("p",null,"The check function takes an unknown value (the value from Data Stores) and\nverifies that it meets the correct format by returning a boolean. The second return type must match the\ntype of your default - however, this is only to help you prevent mistakes."),(0,r.kt)("p",null,"A good way to create a check function is to use ",(0,r.kt)("a",{parentName:"p",href:"https://util.redblox.dev/guard.html"},"Guard"),". Create a standard interface check in Guard, and then wrap it with Guard.Check so it returns a boolean."),(0,r.kt)("p",null,"Note that, while it is recommended that you use a check function, you can of course write one\nthat always returns true if you are confident data won't be mistakenly corrupted!\nIn the future, the check function may be optional."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local DataInterface = {\n    Coins = Guard.Integer,\n    XP = Guard.Integer,\n}\n\nlocal function dataCheck(value: unknown): DataSchema\n    assert(type(value) == "table", "Data must be a table")\n    local Value: any = value\n\n    return {\n        Coins = DataInterface.Coins(Value.Coins),\n        XP = DataInterface.XP(Value.XP),\n    }\nend\n')),(0,r.kt)("h2",{id:"creating-the-documentstore"},"Creating the DocumentStore"),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"DocumentStore"),":\nSet up the ",(0,r.kt)("a",{parentName:"p",href:"https://anthony0br.github.io/DocumentService/api/DocumentStore/"},"DocumentStore")," for player data."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local PlayerDocumentStore = DocumentService.DocumentStore.new({\n    dataStore = DataStoreService:GetDataStore("PlayerData"),\n    check = Guard.Check(dataCheck),\n    default = {\n        Coins = 0,\n        XP = 0,\n    },\n    migrations = {\n        backwardsCompatible = false, \n    },\n    -- This is an important feature of player data. It locks editing to one server\n    -- at a time, allowing us to safely cache player data and save batches of updates.\n    -- We do this through additional methods that session locking unlocks, such as\n    -- `SetCache` and `GetCache`.\n    lockSessions = true,\n})\n')),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"BackwardsCompatible"),": If ",(0,r.kt)("inlineCode",{parentName:"li"},"False"),", players can only join up-to-date servers."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"LockSessions"),": Prevents multiple devices from accessing the same player's data simultaneously.")),(0,r.kt)("h2",{id:"managing-player-data"},"Managing Player Data"),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"GetDocument"),":\nFetch a player's document:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},"function PlayerData:GetDocument(player: Player)\n    return PlayerDocumentStore:GetDocument(`{player.UserId}`)\nend\n")),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"CloseDocument"),":\nSave the player's data when they exit:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'function PlayerData:CloseDocument(player: Player)\n    local document = PlayerDocumentStore:GetDocument(`{player.Name}_{player.UserId}`)\n\n    if not document:IsOpen() and document:IsOpenAvailable() then\n        document:Open()\n    end\n\n    if document and document:IsOpen() then\n        local successfulClose, closeResult = pcall(function()\n            return document:Close()\n        end)\n\n        if not successfulClose then\n            warn("Failed to close document for player:", player.Name, "Error:", closeResult)\n        end\n    else\n        warn("Failed to retrieve document for player:", player.Name)\n    end\nend\n')),(0,r.kt)("h2",{id:"best-practices"},"Best Practices"),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"Strict types:")," Write your scripts in strict mode to benefit fully from the type-checking features of DocumentService. Be as precise as you can with types - using ",(0,r.kt)("inlineCode",{parentName:"p"},"any")," or other loosely-defined types for your fields will have little to no benefit."),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"Use good tools:")," Roblox Studio's script editor doesn't provide great linting - luau-lsp is better\nfor taking full advantage of type-checking."),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"Seperation:")," You might want to put your default table, migrations, types and your check function in a separate file to keep things manageable and modular."),(0,r.kt)("p",null,(0,r.kt)("strong",{parentName:"p"},"Use cache where you can:")," Minimise methods that call DataStore APIs, such as ",(0,r.kt)("inlineCode",{parentName:"p"},"Read")," and ",(0,r.kt)("inlineCode",{parentName:"p"},"Update"),", in\nfavour of ",(0,r.kt)("inlineCode",{parentName:"p"},"GetCache")," and ",(0,r.kt)("inlineCode",{parentName:"p"},"SetCache"),". This improves performance and reduces the chance of hitting limits."),(0,r.kt)("h2",{id:"editing-player-data"},"Editing Player Data"),(0,r.kt)("p",null,"To modify the player's data on the ",(0,r.kt)("strong",{parentName:"p"},"Server"),":\nNote that this assumes the player is in the server!"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'local document = YourPlayerDataModule:GetDocument(player)\n\nif not document:IsOpen() then\n    -- See "Waiting for a Document to Open" page if you need to wait for the document to be open\nend\n\n-- We need to clone the table and any sub-tables we intend to edit, since\n-- DocumentService freezes tables on SetCache.\n-- This forces immutable updates and helps you avoid creating bugs!\nlocal documentClone = table.clone(document:GetCache())\n\ndocumentClone.Coins = 99\ndocumentClone.XP = 99\ndocument:SetCache(documentClone)\n')),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"document:SetCache()"),": Updates the player's data cache, which is saved when the document is closed.")),(0,r.kt)("h2",{id:"accessing-data-from-the-client"},"Accessing Data from the Client"),(0,r.kt)("p",null,"Access the player's data from the ",(0,r.kt)("strong",{parentName:"p"},"Client"),":"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},"-- Server\nGetPlayerData_Remote:Connect(function(player)\n    local playerDocument = PlayerData:GetDocument(player)\n\n    return playerDocument:GetCache()\nend)\n\n-- Client\nlocal playerDocument = GetPlayerData_Remote:Invoke()\n\nprint(playerDocument.XP) -- 99\nprint(playerDocument.Coins) -- 99\n")),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"playerDocument:Read()"),": Returns the player's data")))}d.isMDXComponent=!0}}]);