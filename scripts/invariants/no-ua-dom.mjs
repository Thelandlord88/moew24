#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path';
const DIST='dist'; if(!fs.existsSync(DIST)) { console.log('[inv:no-ua] dist/ missing'); process.exit(0); }
function* walk(dir){ for(const e of fs.readdirSync(dir,{withFileTypes:true})){ const full=path.join(dir,e.name); if(e.isDirectory()) yield* walk(full); else if(e.isFile()&&(e.name.endsWith('.js')||e.name.endsWith('.mjs'))) yield full; } }
let issues=0;
for(const file of walk(DIST)){ const s=fs.readFileSync(file,'utf8'); if(/navigator\.userAgent/.test(s)) { console.error(`[inv:no-ua] ${file}: found navigator.userAgent`); issues++; } }
if(issues) process.exit(1); console.log('[inv:no-ua] OK');
