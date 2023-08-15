"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[3690],{4137:(e,t,n)=>{n.d(t,{Zo:()=>u,kt:()=>h});var r=n(7294);function o(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function a(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){o(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function l(e,t){if(null==e)return{};var n,r,o=function(e,t){if(null==e)return{};var n,r,o={},i=Object.keys(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||(o[n]=e[n]);return o}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(o[n]=e[n])}return o}var s=r.createContext({}),c=function(e){var t=r.useContext(s),n=t;return e&&(n="function"==typeof e?e(t):a(a({},t),e)),n},u=function(e){var t=c(e.components);return r.createElement(s.Provider,{value:t},e.children)},p="mdxType",g={inlineCode:"code",wrapper:function(e){var t=e.children;return r.createElement(r.Fragment,{},t)}},m=r.forwardRef((function(e,t){var n=e.components,o=e.mdxType,i=e.originalType,s=e.parentName,u=l(e,["components","mdxType","originalType","parentName"]),p=c(n),m=o,h=p["".concat(s,".").concat(m)]||p[m]||g[m]||i;return n?r.createElement(h,a(a({ref:t},u),{},{components:n})):r.createElement(h,a({ref:t},u))}));function h(e,t){var n=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var i=n.length,a=new Array(i);a[0]=m;var l={};for(var s in t)hasOwnProperty.call(t,s)&&(l[s]=t[s]);l.originalType=e,l[p]="string"==typeof e?e:o,a[1]=l;for(var c=2;c<i;c++)a[c]=n[c];return r.createElement.apply(null,a)}return r.createElement.apply(null,n)}m.displayName="MDXCreateElement"},8435:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>s,contentTitle:()=>a,default:()=>g,frontMatter:()=>i,metadata:()=>l,toc:()=>c});var r=n(7462),o=(n(7294),n(4137));const i={title:"Log - Sprint 34 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-34",tags:["log","sprint"]},a=void 0,l={permalink:"/solution-sfg-aws/blog/flight-log-34",editUrl:"https://github.com/ibm-client-engineering/solution-sfg-aws/edit/main/website/flight-logs/2023-08-07-cocreate.md",source:"@site/flight-logs/2023-08-07-cocreate.md",title:"Log - Sprint 34 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",date:"2023-08-07T00:00:00.000Z",formattedDate:"August 7, 2023",tags:[{label:"log",permalink:"/solution-sfg-aws/blog/tags/log"},{label:"sprint",permalink:"/solution-sfg-aws/blog/tags/sprint"}],readingTime:1.345,hasTruncateMarker:!1,authors:[],frontMatter:{title:"Log - Sprint 34 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-34",tags:["log","sprint"]},prevItem:{title:"Log - Sprint 35 \ud83d\udeeb",permalink:"/solution-sfg-aws/blog/flight-log-35"},nextItem:{title:"Log - Sprint 33 \ud83d\udeeb",permalink:"/solution-sfg-aws/blog/flight-log-33"}},s={authorsImageUrls:[]},c=[{value:"Work In Progress",id:"work-in-progress",level:2},{value:"Tracking",id:"tracking",level:2}],u={toc:c},p="wrapper";function g(e){let{components:t,...n}=e;return(0,o.kt)(p,(0,r.Z)({},u,n,{components:t,mdxType:"MDXLayout"}),(0,o.kt)("h2",{id:"work-in-progress"},"Work In Progress"),(0,o.kt)("ul",null,(0,o.kt)("li",{parentName:"ul"},"The team began to work on the SFTP use case. "),(0,o.kt)("li",{parentName:"ul"},'The first thing the team tried was "Obtain Remote Key" through the B2Bi Console. However they were unable to connect to the remote host. We then checked the ingress to make sure the policies allowed the connection and after some inspection we determine that there should be no policies blocking the connection. '),(0,o.kt)("li",{parentName:"ul"},"The customer reiterated that they were trying to configure a 1 to 1 relationship between an SFTP server and a specific mailbox. Since we could not connect to the second SFTP server, we decided to move forward using one SFTP server. We then created a new Remote Profile to accommodate this."),(0,o.kt)("li",{parentName:"ul"},'We then created a new partner producer and consumer and verified the group, added a template to it, and created a channel. We then tried to test the connection and we were getting an "Access Denied". We then tried to connect with an preexisting partner and it was able to connect to the SFTP server.'),(0,o.kt)("li",{parentName:"ul"},"We tried many troubleshooting methods but were unable to resolve the issue during the session. ")),(0,o.kt)("h2",{id:"tracking"},"Tracking"),(0,o.kt)("ul",null,(0,o.kt)("li",{parentName:"ul"},"We will continue to look into the SFTP authentication issue and continue to troubleshoot in our next session. "),(0,o.kt)("li",{parentName:"ul"},"The team also opened a new support ticket TS013430052 on the the issue. "),(0,o.kt)("li",{parentName:"ul"},(0,o.kt)("strong",{parentName:"li"},"Cases open: 1"),(0,o.kt)("ul",{parentName:"li"},(0,o.kt)("li",{parentName:"ul"},"Case TS013825812"))),(0,o.kt)("li",{parentName:"ul"},(0,o.kt)("strong",{parentName:"li"},"Cases closed: 6"),(0,o.kt)("ul",{parentName:"li"},(0,o.kt)("li",{parentName:"ul"},"Case TS013430052"),(0,o.kt)("li",{parentName:"ul"},"case TS012906539"),(0,o.kt)("li",{parentName:"ul"},"case TS013042929"),(0,o.kt)("li",{parentName:"ul"},"case TS012831699"),(0,o.kt)("li",{parentName:"ul"},"case TS012704616"),(0,o.kt)("li",{parentName:"ul"},"case TS012702956  "))),(0,o.kt)("li",{parentName:"ul"},(0,o.kt)("a",{parentName:"li",href:"https://zenhub.ibm.com/workspaces/st5-action-information-center-64343620d0cfd0000f03a114/issues/ibm-client-engineering/solution-sfg-aws/12"},"ibm-client-engineering/solution-sfg-aws#12")),(0,o.kt)("li",{parentName:"ul"},'This flight log is being submitted via PR "08/11/2023 Documentation".')))}g.isMDXComponent=!0}}]);