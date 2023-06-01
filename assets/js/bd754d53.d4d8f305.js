"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[1234],{4137:(e,t,n)=>{n.d(t,{Zo:()=>p,kt:()=>f});var r=n(7294);function i(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function l(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function o(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?l(Object(n),!0).forEach((function(t){i(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):l(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function a(e,t){if(null==e)return{};var n,r,i=function(e,t){if(null==e)return{};var n,r,i={},l=Object.keys(e);for(r=0;r<l.length;r++)n=l[r],t.indexOf(n)>=0||(i[n]=e[n]);return i}(e,t);if(Object.getOwnPropertySymbols){var l=Object.getOwnPropertySymbols(e);for(r=0;r<l.length;r++)n=l[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(i[n]=e[n])}return i}var s=r.createContext({}),c=function(e){var t=r.useContext(s),n=t;return e&&(n="function"==typeof e?e(t):o(o({},t),e)),n},p=function(e){var t=c(e.components);return r.createElement(s.Provider,{value:t},e.children)},u="mdxType",g={inlineCode:"code",wrapper:function(e){var t=e.children;return r.createElement(r.Fragment,{},t)}},m=r.forwardRef((function(e,t){var n=e.components,i=e.mdxType,l=e.originalType,s=e.parentName,p=a(e,["components","mdxType","originalType","parentName"]),u=c(n),m=i,f=u["".concat(s,".").concat(m)]||u[m]||g[m]||l;return n?r.createElement(f,o(o({ref:t},p),{},{components:n})):r.createElement(f,o({ref:t},p))}));function f(e,t){var n=arguments,i=t&&t.mdxType;if("string"==typeof e||i){var l=n.length,o=new Array(l);o[0]=m;var a={};for(var s in t)hasOwnProperty.call(t,s)&&(a[s]=t[s]);a.originalType=e,a[u]="string"==typeof e?e:i,o[1]=a;for(var c=2;c<l;c++)o[c]=n[c];return r.createElement.apply(null,o)}return r.createElement.apply(null,n)}m.displayName="MDXCreateElement"},193:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>s,contentTitle:()=>o,default:()=>g,frontMatter:()=>l,metadata:()=>a,toc:()=>c});var r=n(7462),i=(n(7294),n(4137));const l={title:"Log - Sprint 9 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-9",tags:["log","sprint"]},o=void 0,a={permalink:"/solution-sfg-aws/blog/flight-log-9",editUrl:"https://github.com/ibm-client-engineering/solution-sfg-aws/edit/main/website/flight-logs/2023-05-30-cocreate.md",source:"@site/flight-logs/2023-05-30-cocreate.md",title:"Log - Sprint 9 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",date:"2023-05-30T00:00:00.000Z",formattedDate:"May 30, 2023",tags:[{label:"log",permalink:"/solution-sfg-aws/blog/tags/log"},{label:"sprint",permalink:"/solution-sfg-aws/blog/tags/sprint"}],readingTime:.755,hasTruncateMarker:!1,authors:[],frontMatter:{title:"Log - Sprint 9 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-9",tags:["log","sprint"]},prevItem:{title:"Log - Sprint 10 \ud83d\udeeb",permalink:"/solution-sfg-aws/blog/flight-log-10"},nextItem:{title:"Log - Sprint 8 \ud83d\udeeb",permalink:"/solution-sfg-aws/blog/flight-log-8"}},s={authorsImageUrls:[]},c=[{value:"Key Accomplishments",id:"key-accomplishments",level:2},{value:"Challenges",id:"challenges",level:2},{value:"Up Next",id:"up-next",level:2},{value:"Tracking",id:"tracking",level:2}],p={toc:c},u="wrapper";function g(e){let{components:t,...n}=e;return(0,i.kt)(u,(0,r.Z)({},p,n,{components:t,mdxType:"MDXLayout"}),(0,i.kt)("h2",{id:"key-accomplishments"},"Key Accomplishments"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"We ran a helm chart update and it failed on the patched 2.1.1 since it was missing the pullsecret entry for the preinstall-tls job"),(0,i.kt)("li",{parentName:"ul"},"Applied series of patch commands in order to run the helm upgrade."),(0,i.kt)("li",{parentName:"ul"},"Updated the helm chart to add an annotation for the pull-secret")),(0,i.kt)("h2",{id:"challenges"},"Challenges"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"Received multiple errors during the helm upgrade")),(0,i.kt)("h2",{id:"up-next"},"Up Next"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"Need to update patches for helm charts 2.1.1 to add pull secrets to preinstall-tls job container"),(0,i.kt)("li",{parentName:"ul"},"We need to get the business process set up to access S3"),(0,i.kt)("li",{parentName:"ul"},"Will need to update the service account entry in the overrides to the created S3 service account that has the role annotated."),(0,i.kt)("li",{parentName:"ul"},"Aneesh will re-run the helm upgrade offline and we will check in on the next working session")),(0,i.kt)("h2",{id:"tracking"},"Tracking"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("a",{parentName:"li",href:"https://zenhub.ibm.com/workspaces/st5-action-information-center-64343620d0cfd0000f03a114/issues/ibm-client-engineering/solution-sfg-aws/17"},"ibm-client-engineering/solution-sfg-aws#17")),(0,i.kt)("li",{parentName:"ul"},"This flight log is being submitted via PR 05/30/2023")))}g.isMDXComponent=!0}}]);