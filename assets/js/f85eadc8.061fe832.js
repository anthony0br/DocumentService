"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[668],{3905:(e,t,n)=>{n.d(t,{Zo:()=>u,kt:()=>f});var r=n(67294);function o(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function a(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function i(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?a(Object(n),!0).forEach((function(t){o(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):a(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function c(e,t){if(null==e)return{};var n,r,o=function(e,t){if(null==e)return{};var n,r,o={},a=Object.keys(e);for(r=0;r<a.length;r++)n=a[r],t.indexOf(n)>=0||(o[n]=e[n]);return o}(e,t);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);for(r=0;r<a.length;r++)n=a[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(o[n]=e[n])}return o}var l=r.createContext({}),s=function(e){var t=r.useContext(l),n=t;return e&&(n="function"==typeof e?e(t):i(i({},t),e)),n},u=function(e){var t=s(e.components);return r.createElement(l.Provider,{value:t},e.children)},p="mdxType",d={inlineCode:"code",wrapper:function(e){var t=e.children;return r.createElement(r.Fragment,{},t)}},m=r.forwardRef((function(e,t){var n=e.components,o=e.mdxType,a=e.originalType,l=e.parentName,u=c(e,["components","mdxType","originalType","parentName"]),p=s(n),m=o,f=p["".concat(l,".").concat(m)]||p[m]||d[m]||a;return n?r.createElement(f,i(i({ref:t},u),{},{components:n})):r.createElement(f,i({ref:t},u))}));function f(e,t){var n=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var a=n.length,i=new Array(a);i[0]=m;var c={};for(var l in t)hasOwnProperty.call(t,l)&&(c[l]=t[l]);c.originalType=e,c[p]="string"==typeof e?e:o,i[1]=c;for(var s=2;s<a;s++)i[s]=n[s];return r.createElement.apply(null,i)}return r.createElement.apply(null,n)}m.displayName="MDXCreateElement"},30404:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>l,contentTitle:()=>i,default:()=>d,frontMatter:()=>a,metadata:()=>c,toc:()=>s});var r=n(87462),o=(n(67294),n(3905));const a={sidebar_position:4},i="Opening a player document",c={unversionedId:"opening",id:"opening",title:"Opening a player document",description:"This is an example of how to open a document for a DocumentStore that deals with player data.",source:"@site/docs/opening.md",sourceDirName:".",slug:"/opening",permalink:"/DocumentService/docs/opening",draft:!1,editUrl:"https://github.com/anthony0br/DocumentService/edit/main/docs/opening.md",tags:[],version:"current",sidebarPosition:4,frontMatter:{sidebar_position:4},sidebar:"defaultSidebar",previous:{title:"Creating a DocumentStore",permalink:"/DocumentService/docs/creating"},next:{title:"Developer Products",permalink:"/DocumentService/docs/products"}},l={},s=[],u={toc:s},p="wrapper";function d(e){let{components:t,...n}=e;return(0,o.kt)(p,(0,r.Z)({},u,n,{components:t,mdxType:"MDXLayout"}),(0,o.kt)("h1",{id:"opening-a-player-document"},"Opening a player document"),(0,o.kt)("p",null," This is an example of how to open a document for a DocumentStore that deals with player data.\nThe following code should run on ",(0,o.kt)("inlineCode",{parentName:"p"},"Players.PlayerAdded"),":"),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-lua"},'local document = store:GetDocument(tostring(player.UserId))\nlocal result = document:Open()\n\n-- DocumentService retries 5 times over 16 seconds, so it is safe to steal\n-- after a failed `:Open`!\nif not result.success and result.reason == "SessionLockedError" then\n   document:Steal()\n   result = document:Open()\nend\n\nif not result.success then\n   if result.reason == "BackwardsCompatibilityError" then\n       player:Kick(\n           "You joined an old server which does not support your saved data."\n               .. "Please try joining another server. If this persists, contact a developer."\n       )\n   end\n\n   if result.reason == "RobloxAPIError" then\n       player:Kick("Failed to load data due to a Roblox service issue. Try again later.")\n   end\n\n   player:Kick(\n       `Failed to load data: {result.reason}. Please screenshot this message and report it to a developer.`\n   )\n\n   return false\nend\n')),(0,o.kt)("p",null,"You should close documents when a player leaves. Note that I have not created a player documents table.\nYou should use ",(0,o.kt)("inlineCode",{parentName:"p"},":GetDocument")," to retrieve the document - there is usually no need to create a table to\nreference your player documents. See the API reference for ",(0,o.kt)("inlineCode",{parentName:"p"},"GetDocument")," for information on when documents are\ngarbage collected."))}d.isMDXComponent=!0}}]);