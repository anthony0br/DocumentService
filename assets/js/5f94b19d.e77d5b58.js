"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[33],{3905:(e,n,t)=>{t.d(n,{Zo:()=>p,kt:()=>h});var r=t(67294);function o(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function a(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),t.push.apply(t,r)}return t}function i(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{};n%2?a(Object(t),!0).forEach((function(n){o(e,n,t[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):a(Object(t)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(t,n))}))}return e}function l(e,n){if(null==e)return{};var t,r,o=function(e,n){if(null==e)return{};var t,r,o={},a=Object.keys(e);for(r=0;r<a.length;r++)t=a[r],n.indexOf(t)>=0||(o[t]=e[t]);return o}(e,n);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);for(r=0;r<a.length;r++)t=a[r],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(o[t]=e[t])}return o}var s=r.createContext({}),c=function(e){var n=r.useContext(s),t=n;return e&&(t="function"==typeof e?e(n):i(i({},n),e)),t},p=function(e){var n=c(e.components);return r.createElement(s.Provider,{value:n},e.children)},d="mdxType",u={inlineCode:"code",wrapper:function(e){var n=e.children;return r.createElement(r.Fragment,{},n)}},f=r.forwardRef((function(e,n){var t=e.components,o=e.mdxType,a=e.originalType,s=e.parentName,p=l(e,["components","mdxType","originalType","parentName"]),d=c(t),f=o,h=d["".concat(s,".").concat(f)]||d[f]||u[f]||a;return t?r.createElement(h,i(i({ref:n},p),{},{components:t})):r.createElement(h,i({ref:n},p))}));function h(e,n){var t=arguments,o=n&&n.mdxType;if("string"==typeof e||o){var a=t.length,i=new Array(a);i[0]=f;var l={};for(var s in n)hasOwnProperty.call(n,s)&&(l[s]=n[s]);l.originalType=e,l[d]="string"==typeof e?e:o,i[1]=l;for(var c=2;c<a;c++)i[c]=t[c];return r.createElement.apply(null,i)}return r.createElement.apply(null,t)}f.displayName="MDXCreateElement"},83380:(e,n,t)=>{t.r(n),t.d(n,{assets:()=>s,contentTitle:()=>i,default:()=>u,frontMatter:()=>a,metadata:()=>l,toc:()=>c});var r=t(87462),o=(t(67294),t(3905));const a={sidebar_position:8},i="Signals & Hooks",l={unversionedId:"hooks",id:"hooks",title:"Signals & Hooks",description:"Signals",source:"@site/docs/hooks.md",sourceDirName:".",slug:"/hooks",permalink:"/DocumentService/docs/hooks",draft:!1,editUrl:"https://github.com/anthony0br/DocumentService/edit/main/docs/hooks.md",tags:[],version:"current",sidebarPosition:8,frontMatter:{sidebar_position:8},sidebar:"defaultSidebar",previous:{title:"Error Handling",permalink:"/DocumentService/docs/errors"}},s={},c=[{value:"Signals",id:"signals",level:2},{value:"Hooks",id:"hooks",level:2}],p={toc:c},d="wrapper";function u(e){let{components:n,...t}=e;return(0,o.kt)(d,(0,r.Z)({},p,t,{components:n,mdxType:"MDXLayout"}),(0,o.kt)("h1",{id:"signals--hooks"},"Signals & Hooks"),(0,o.kt)("h2",{id:"signals"},"Signals"),(0,o.kt)("p",null,"DocumentService provides 5 signals:\nUpdatedSignal, OpenedSignal, ReadSignal, ClosedSignal, CacheChangedSignal."),(0,o.kt)("p",null,"These signals allow you to wait for a document to be open before modifying it or\nto tap into cache changes (e.g. for replication), for example. They also\nimplement the Once and cancellation functionality of after hooks, through ",(0,o.kt)("inlineCode",{parentName:"p"},":Once")," and ",(0,o.kt)("inlineCode",{parentName:"p"},":Disconnect"),"."),(0,o.kt)("p",null,"They are implemented with sleitnick signals, so listeners are wrapped in a task.spawn\nand hence will run immediately (and before the method returns), until a yield\nis encountered, and will run in reverse order to the order they are added."),(0,o.kt)("h2",{id:"hooks"},"Hooks"),(0,o.kt)("p",null,"Hooks are now deprecated (except for before hooks, which can be useful\nfor debugging/logging). Use signals in new work instead."),(0,o.kt)("p",null,"To listen to and respond to events, like saving or reading data, DocumentService\nhas a hooks API: ",(0,o.kt)("inlineCode",{parentName:"p"},"HookBefore"),", ",(0,o.kt)("inlineCode",{parentName:"p"},"HookAfter"),", ",(0,o.kt)("inlineCode",{parentName:"p"},"OnceBefore"),", and ",(0,o.kt)("inlineCode",{parentName:"p"},"OnceAfter"),"."),(0,o.kt)("p",null,"Hooks run sequentially in the order they are added, and generally, should not\nyield."),(0,o.kt)("p",null,(0,o.kt)("inlineCode",{parentName:"p"},"HookBefore")," and ",(0,o.kt)("inlineCode",{parentName:"p"},"HookAfter")," return a cancel function. This will clean up the\nhook and stop it from running again in response to any future events. Note that\nonce an event happens, the sequence of hooks to run is fixed and cannot be changed\nfor while the hooks are running for that particular event."))}u.isMDXComponent=!0}}]);