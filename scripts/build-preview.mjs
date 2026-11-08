import {cpSync,rmSync,writeFileSync} from 'node:fs';
rmSync('dist',{recursive:true,force:true});
cpSync('public','dist',{recursive:true});
writeFileSync('dist/config.js','window.SOYO_PREVIEW = true;\n');
