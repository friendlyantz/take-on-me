// supports-color@10.2.2 downloaded from https://ga.jspm.io/npm:supports-color@10.2.2/browser.js

const t=(()=>{if(!("navigator"in globalThis))return 0;if(globalThis.navigator.userAgentData){const t=navigator.userAgentData.brands.find((({brand:t})=>t==="Chromium"));if(t?.version>93)return 3}return/\b(Chrome|Chromium)\//.test(globalThis.navigator.userAgent)?1:0})();const a=t!==0&&{level:t,hasBasic:true,has256:t>=2,has16m:t>=3};const r={stdout:a,stderr:a};export{r as default};

