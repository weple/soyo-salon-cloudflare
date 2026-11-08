import test from 'node:test';
import assert from 'node:assert/strict';
import {createHmac} from 'node:crypto';
import worker from '../src/index.js';
const env={PUBLIC_ORIGIN:'https://soyo.test',SESSION_SECRET:'test-secret-only',SUPABASE_URL:'https://db.test',SUPABASE_SECRET_KEY:'sb_secret_test',ADMIN_KAKAO_IDS:'123',ASSETS:{fetch:()=>new Response('asset')}};
function cookie(admin=false){const payload=Buffer.from(JSON.stringify({id:'11111111-1111-4111-8111-111111111111',kakaoId:admin?'123':'456',exp:Date.now()+60000})).toString('base64url');return 'soyo_session='+payload+'.'+createHmac('sha256',env.SESSION_SECRET).update(payload).digest('base64url')}
const request=(path,options={})=>new Request('https://soyo.test'+path,options);
test('cross-origin writes rejected even when request URL is legitimate',async()=>{const r=await worker.fetch(request('/api/logout',{method:'POST',headers:{Origin:'https://attacker.test'}}),env);assert.equal(r.status,403)});
test('missing Origin write rejected',async()=>assert.equal((await worker.fetch(request('/api/logout',{method:'POST'}),env)).status,403));
test('unauthenticated application rejected',async()=>assert.equal((await worker.fetch(request('/api/applications',{method:'POST',headers:{Origin:env.PUBLIC_ORIGIN,'content-type':'application/json'},body:'{}'}),env)).status,401));
test('ordinary member cannot read admin applications',async()=>assert.equal((await worker.fetch(request('/api/admin/applications',{headers:{Cookie:cookie()}}),env)).status,403));
test('tampered session cannot read applications',async()=>assert.equal((await worker.fetch(request('/api/applications',{headers:{Cookie:cookie()+'x'}}),env)).status,401));
test('public events projection excludes capacity, members and counts',async()=>{const orig=globalThis.fetch;let url;globalThis.fetch=async u=>{url=u;return new Response('[]')};try{const r=await worker.fetch(request('/api/events'),env);assert.equal(r.status,200);assert.match(url,/select=id,title/);assert.doesNotMatch(url,/capacity|users|applications|count/)}finally{globalThis.fetch=orig}});
test('malformed body returns 400',async()=>assert.equal((await worker.fetch(request('/api/applications',{method:'POST',headers:{Origin:env.PUBLIC_ORIGIN,Cookie:cookie(),'content-type':'application/json'},body:'{'}),env)).status,400));
test('oversized streamed body rejected without trusting content-length',async()=>assert.equal((await worker.fetch(request('/api/applications',{method:'POST',headers:{Origin:env.PUBLIC_ORIGIN,Cookie:cookie(),'content-type':'application/json'},body:JSON.stringify({x:'a'.repeat(13000)})}),env)).status,413));
test('admin fractional capacity rejected',async()=>assert.equal((await worker.fetch(request('/api/admin/events',{method:'POST',headers:{Origin:env.PUBLIC_ORIGIN,Cookie:cookie(true),'content-type':'application/json'},body:JSON.stringify({title:'title',place:'place',date:'2099-01-01',capacity:1.5})}),env)).status,400));
test('logout clears session cookie',async()=>{const r=await worker.fetch(request('/api/logout',{method:'POST',headers:{Origin:env.PUBLIC_ORIGIN}}),env);assert.equal(r.status,200);assert.match(r.headers.get('set-cookie'),/Max-Age=0/)});
test('OAuth callback rejects missing state',async()=>assert.equal((await worker.fetch(request('/auth/callback?code=x&state=x'),env)).status,400));
