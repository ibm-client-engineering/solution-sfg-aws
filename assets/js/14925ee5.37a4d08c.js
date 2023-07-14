"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[7497],{4137:(e,t,r)=>{r.d(t,{Zo:()=>u,kt:()=>f});var n=r(7294);function a(e,t,r){return t in e?Object.defineProperty(e,t,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[t]=r,e}function o(e,t){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);t&&(n=n.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),r.push.apply(r,n)}return r}function i(e){for(var t=1;t<arguments.length;t++){var r=null!=arguments[t]?arguments[t]:{};t%2?o(Object(r),!0).forEach((function(t){a(e,t,r[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(r)):o(Object(r)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(r,t))}))}return e}function l(e,t){if(null==e)return{};var r,n,a=function(e,t){if(null==e)return{};var r,n,a={},o=Object.keys(e);for(n=0;n<o.length;n++)r=o[n],t.indexOf(r)>=0||(a[r]=e[r]);return a}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(n=0;n<o.length;n++)r=o[n],t.indexOf(r)>=0||Object.prototype.propertyIsEnumerable.call(e,r)&&(a[r]=e[r])}return a}var s=n.createContext({}),c=function(e){var t=n.useContext(s),r=t;return e&&(r="function"==typeof e?e(t):i(i({},t),e)),r},u=function(e){var t=c(e.components);return n.createElement(s.Provider,{value:t},e.children)},p="mdxType",g={inlineCode:"code",wrapper:function(e){var t=e.children;return n.createElement(n.Fragment,{},t)}},m=n.forwardRef((function(e,t){var r=e.components,a=e.mdxType,o=e.originalType,s=e.parentName,u=l(e,["components","mdxType","originalType","parentName"]),p=c(r),m=a,f=p["".concat(s,".").concat(m)]||p[m]||g[m]||o;return r?n.createElement(f,i(i({ref:t},u),{},{components:r})):n.createElement(f,i({ref:t},u))}));function f(e,t){var r=arguments,a=t&&t.mdxType;if("string"==typeof e||a){var o=r.length,i=new Array(o);i[0]=m;var l={};for(var s in t)hasOwnProperty.call(t,s)&&(l[s]=t[s]);l.originalType=e,l[p]="string"==typeof e?e:a,i[1]=l;for(var c=2;c<o;c++)i[c]=r[c];return n.createElement.apply(null,i)}return n.createElement.apply(null,r)}m.displayName="MDXCreateElement"},7204:(e,t,r)=>{r.r(t),r.d(t,{assets:()=>s,contentTitle:()=>i,default:()=>g,frontMatter:()=>o,metadata:()=>l,toc:()=>c});var n=r(7462),a=(r(7294),r(4137));const o={title:"Log - Sprint 27 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-27",tags:["log","sprint"]},i=void 0,l={permalink:"/solution-sfg-aws/blog/flight-log-27",editUrl:"https://github.com/ibm-client-engineering/solution-sfg-aws/edit/main/website/flight-logs/2023-07-11-cocreate.md",source:"@site/flight-logs/2023-07-11-cocreate.md",title:"Log - Sprint 27 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",date:"2023-07-11T00:00:00.000Z",formattedDate:"July 11, 2023",tags:[{label:"log",permalink:"/solution-sfg-aws/blog/tags/log"},{label:"sprint",permalink:"/solution-sfg-aws/blog/tags/sprint"}],readingTime:.71,hasTruncateMarker:!1,authors:[],frontMatter:{title:"Log - Sprint 27 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-27",tags:["log","sprint"]},prevItem:{title:"Log - Sprint 28 \ud83d\udeeb",permalink:"/solution-sfg-aws/blog/flight-log-28"},nextItem:{title:"Log - Sprint 26 \ud83d\udeeb",permalink:"/solution-sfg-aws/blog/flight-log-26"}},s={authorsImageUrls:[]},c=[{value:"Work In Progress",id:"work-in-progress",level:2},{value:"Tracking",id:"tracking",level:2}],u={toc:c},p="wrapper";function g(e){let{components:t,...r}=e;return(0,a.kt)(p,(0,n.Z)({},u,r,{components:t,mdxType:"MDXLayout"}),(0,a.kt)("h2",{id:"work-in-progress"},"Work In Progress"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Today the team continued to discuss the \u201cOIDC Not Found\u201d error."),(0,a.kt)("li",{parentName:"ul"},"The Customer said that he opened a ticket with AWS, and they gave him feedback on the error."),(0,a.kt)("li",{parentName:"ul"},"AWS provided some suggested documentation on the matter:\n",(0,a.kt)("a",{parentName:"li",href:"https://aws.amazon.com/blogs/containers/cross-account-iam-roles-for-kubernetes-service-accounts/"},"https://aws.amazon.com/blogs/containers/cross-account-iam-roles-for-kubernetes-service-accounts/")),(0,a.kt)("li",{parentName:"ul"},"It was suggested that the OIDC be created in the same account as the destination S3 bucket.")),(0,a.kt)("h2",{id:"tracking"},"Tracking"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"The Customer said he was working on this with his team and would update us on their progress."),(0,a.kt)("li",{parentName:"ul"},"The Customer also mentioned that there was an open AWS ticket on the S3 signature issue awaiting feedback."),(0,a.kt)("li",{parentName:"ul"},(0,a.kt)("strong",{parentName:"li"},"Cases open: 1"),(0,a.kt)("ul",{parentName:"li"},(0,a.kt)("li",{parentName:"ul"},"Case TS013430052"))),(0,a.kt)("li",{parentName:"ul"},(0,a.kt)("strong",{parentName:"li"},"Cases closed: 5"),(0,a.kt)("ul",{parentName:"li"},(0,a.kt)("li",{parentName:"ul"},"case TS012906539"),(0,a.kt)("li",{parentName:"ul"},"case TS013042929"),(0,a.kt)("li",{parentName:"ul"},"case TS012831699"),(0,a.kt)("li",{parentName:"ul"},"case TS012704616"),(0,a.kt)("li",{parentName:"ul"},"case TS012702956  "))),(0,a.kt)("li",{parentName:"ul"},(0,a.kt)("a",{parentName:"li",href:"https://zenhub.ibm.com/workspaces/st5-action-information-center-64343620d0cfd0000f03a114/issues/ibm-client-engineering/solution-sfg-aws/17"},"ibm-client-engineering/solution-sfg-aws#17")),(0,a.kt)("li",{parentName:"ul"},'This flight log is being submitted via PR "07/12/2023 Documentation".')))}g.isMDXComponent=!0}}]);