"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[1321],{4137:(e,t,n)=>{n.d(t,{Zo:()=>u,kt:()=>f});var r=n(7294);function i(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function o(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function a(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?o(Object(n),!0).forEach((function(t){i(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):o(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function l(e,t){if(null==e)return{};var n,r,i=function(e,t){if(null==e)return{};var n,r,i={},o=Object.keys(e);for(r=0;r<o.length;r++)n=o[r],t.indexOf(n)>=0||(i[n]=e[n]);return i}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(r=0;r<o.length;r++)n=o[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(i[n]=e[n])}return i}var s=r.createContext({}),c=function(e){var t=r.useContext(s),n=t;return e&&(n="function"==typeof e?e(t):a(a({},t),e)),n},u=function(e){var t=c(e.components);return r.createElement(s.Provider,{value:t},e.children)},p="mdxType",g={inlineCode:"code",wrapper:function(e){var t=e.children;return r.createElement(r.Fragment,{},t)}},m=r.forwardRef((function(e,t){var n=e.components,i=e.mdxType,o=e.originalType,s=e.parentName,u=l(e,["components","mdxType","originalType","parentName"]),p=c(n),m=i,f=p["".concat(s,".").concat(m)]||p[m]||g[m]||o;return n?r.createElement(f,a(a({ref:t},u),{},{components:n})):r.createElement(f,a({ref:t},u))}));function f(e,t){var n=arguments,i=t&&t.mdxType;if("string"==typeof e||i){var o=n.length,a=new Array(o);a[0]=m;var l={};for(var s in t)hasOwnProperty.call(t,s)&&(l[s]=t[s]);l.originalType=e,l[p]="string"==typeof e?e:i,a[1]=l;for(var c=2;c<o;c++)a[c]=n[c];return r.createElement.apply(null,a)}return r.createElement.apply(null,n)}m.displayName="MDXCreateElement"},4663:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>s,contentTitle:()=>a,default:()=>g,frontMatter:()=>o,metadata:()=>l,toc:()=>c});var r=n(7462),i=(n(7294),n(4137));const o={title:"Log - Sprint 8 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-8",tags:["log","sprint"]},a=void 0,l={permalink:"/solution-sfg-aws/blog/flight-log-8",editUrl:"https://github.com/ibm-client-engineering/solution-sfg-aws/edit/main/website/flight-logs/2023-05-26-cocreate.md",source:"@site/flight-logs/2023-05-26-cocreate.md",title:"Log - Sprint 8 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",date:"2023-05-26T00:00:00.000Z",formattedDate:"May 26, 2023",tags:[{label:"log",permalink:"/solution-sfg-aws/blog/tags/log"},{label:"sprint",permalink:"/solution-sfg-aws/blog/tags/sprint"}],readingTime:.855,hasTruncateMarker:!1,authors:[],frontMatter:{title:"Log - Sprint 8 \ud83d\udeeb",description:"Flight Log of Co-Creation Activities",slug:"flight-log-8",tags:["log","sprint"]},prevItem:{title:"Log - Sprint 9 \ud83d\udeeb",permalink:"/solution-sfg-aws/blog/flight-log-9"},nextItem:{title:"Log - Sprint 7 \ud83d\udeeb",permalink:"/solution-sfg-aws/blog/flight-log-7"}},s={authorsImageUrls:[]},c=[{value:"Key Accomplishments",id:"key-accomplishments",level:2},{value:"Up Next",id:"up-next",level:2},{value:"Tracking",id:"tracking",level:2}],u={toc:c},p="wrapper";function g(e){let{components:t,...n}=e;return(0,i.kt)(p,(0,r.Z)({},u,n,{components:t,mdxType:"MDXLayout"}),(0,i.kt)("h2",{id:"key-accomplishments"},"Key Accomplishments"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"Successfully applied AWS role and policy to allow access to S3 buckets in our reference env."),(0,i.kt)("li",{parentName:"ul"},"Successfully demoed Sterling Secure Proxy"),(0,i.kt)("li",{parentName:"ul"},"Introduced customer team to new Document site"),(0,i.kt)("li",{parentName:"ul"},"Updated the ALB idle timeout in the ingress annotations in the overrides",(0,i.kt)("ul",{parentName:"li"},(0,i.kt)("li",{parentName:"ul"},"Verified in our reference environment that this solves a Gateway 403 error when running an S3 business process and updated our documentation. ",(0,i.kt)("a",{parentName:"li",href:"https://github.com/ibm-client-engineering/solution-sfg-aws/pull/37"},"PR#37")),(0,i.kt)("li",{parentName:"ul"},"Updated the customer's ingress annotations in their overrides and applied to their environment"))),(0,i.kt)("li",{parentName:"ul"},"Was able to verify with the customer that the following were configured and enabled:",(0,i.kt)("ul",{parentName:"li"},(0,i.kt)("li",{parentName:"ul"},"OIDC provider assigned to cluster"),(0,i.kt)("li",{parentName:"ul"},"IAM policy for S3 configured for their test bucket"),(0,i.kt)("li",{parentName:"ul"},"Service account was created in the cluster"),(0,i.kt)("li",{parentName:"ul"},"IAM policy was attached to the appropriate role created"),(0,i.kt)("li",{parentName:"ul"},"Service account in cluster was annotated with the role.")))),(0,i.kt)("h2",{id:"up-next"},"Up Next"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"Build a Business Process that uploads a file to the S3 bucket and verify the file was successfully uploaded. ")),(0,i.kt)("h2",{id:"tracking"},"Tracking"),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("a",{parentName:"li",href:"https://zenhub.ibm.com/workspaces/st5-action-information-center-64343620d0cfd0000f03a114/issues/ibm-client-engineering/solution-sfg-aws/17"},"ibm-client-engineering/solution-sfg-aws#17"))))}g.isMDXComponent=!0}}]);