// Checkpoint 4G: creator-to-explorer check against the real development
// project, through the public APIs only (publishable key + user sessions),
// exactly as the app calls them. Prints PASS/FAIL lines; never prints keys,
// passwords or tokens.
// Usage: node tool/e2e/creator_to_explorer.mjs . tool/e2e/.accounts.json
// The accounts file (gitignored) is created on the first run and reused.
import fs from 'node:fs';
import crypto from 'node:crypto';

const [repo, stateFile] = process.argv.slice(2);
const env = Object.fromEntries(
  fs.readFileSync(`${repo}/.env`, 'utf8').split(/\r?\n/)
    .filter((l) => l.includes('=') && !l.trim().startsWith('#'))
    .map((l) => [l.slice(0, l.indexOf('=')).trim(), l.slice(l.indexOf('=') + 1).trim()]),
);
const URL_ = env.SUPABASE_URL;
const KEY = env.SUPABASE_PUBLISHABLE_KEY;

let passed = 0;
let failed = 0;
const check = (ok, label, detail = '') => {
  if (ok) passed++; else failed++;
  console.log(`${ok ? 'PASS' : 'FAIL'} ${label}${!ok && detail ? ` — ${detail}` : ''}`);
};

async function call(method, path, { token, body, headers = {}, raw } = {}) {
  const res = await fetch(`${URL_}${path}`, {
    method,
    headers: {
      apikey: KEY,
      Authorization: `Bearer ${token ?? KEY}`,
      ...(raw ? {} : { 'Content-Type': 'application/json' }),
      ...headers,
    },
    body: raw ?? (body === undefined ? undefined : JSON.stringify(body)),
  });
  const text = await res.text();
  let json = null;
  try { json = JSON.parse(text); } catch { /* not JSON */ }
  return { status: res.status, json, text };
}
const rpc = (name, params, token) => call('POST', `/rest/v1/rpc/${name}`, { token, body: params });

// Accounts: reuse from the state file if a previous run created them.
let state = fs.existsSync(stateFile) ? JSON.parse(fs.readFileSync(stateFile, 'utf8')) : null;
if (!state) {
  const tag = crypto.randomBytes(3).toString('hex');
  state = {
    a: { email: `worlds.e2e.creator.${tag}@example.com`, password: crypto.randomBytes(18).toString('base64url'), username: `e2e_creator_${tag}` },
    b: { email: `worlds.e2e.explorer.${tag}@example.com`, password: crypto.randomBytes(18).toString('base64url'), username: `e2e_explorer_${tag}` },
  };
  fs.writeFileSync(stateFile, JSON.stringify(state));
}

async function session(account) {
  let r = await call('POST', '/auth/v1/token?grant_type=password', { body: { email: account.email, password: account.password } });
  if (r.status !== 200) {
    r = await call('POST', '/auth/v1/signup', { body: { email: account.email, password: account.password, data: { username: account.username } } });
  }
  if (!r.json?.access_token) throw new Error(`no session for ${account.username}: ${r.status} ${r.json?.error_code ?? r.json?.code ?? ''}`);
  return { token: r.json.access_token, id: r.json.user.id };
}

const A = await session(state.a);
const B = await session(state.b);
check(A.id !== B.id, 'two separate accounts signed in through Auth');

const lat = -41.0;
const lon = -121.0;
const worldId = crypto.randomUUID();
const textId = crypto.randomUUID();
const questionId = crypto.randomUUID();
const coverId = crypto.randomUUID();
const secretAsset = crypto.randomUUID();
const answer = 'Lighthouse Keeper';

const world = (extra = {}) => ({
  id: worldId,
  category: 'puzzle',
  title: '[e2e] Lighthouse Riddle',
  description: 'Automated Checkpoint 4 test World, far out at sea.',
  cover_asset_id: null,
  latitude: lat,
  longitude: lon,
  unlock_radius_meters: 50,
  blocks: [
    { id: textId, block_type: 'text', content: { body: 'Find the old lighthouse.' } },
    { id: questionId, block_type: 'question', content: { prompt: 'Who lived here?', hint: 'Two words', success_message: 'Correct!' } },
  ],
  ...extra,
});

// --- Creator A drafts, uploads and publishes --------------------------------
let r = await rpc('save_world', { world: world(), question_answers: { [questionId]: answer } }, A.token);
check(r.status === 200 && r.json?.status === 'draft', 'A saves a new draft', `${r.status} ${r.text.slice(0, 120)}`);
check(r.json?.blocks?.[1]?.has_answer === true && !/keeper/i.test(r.text), 'the answer is stored but never returned');

r = await rpc('save_world', { world: world(), question_answers: {} }, A.token);
check(r.status === 200 && r.json?.blocks?.length === 2 && r.json?.blocks?.[1]?.has_answer === true, 'saving again (a retry) keeps one World and the answer');

const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==', 'base64');
const upload = (path, bytes, type, token) => call('POST', `/storage/v1/object/world-media/${path}`, { token, raw: bytes, headers: { 'Content-Type': type, 'x-upsert': 'false' } });
const coverPath = `${A.id}/${worldId}/${coverId}.png`;

r = await upload(coverPath, png, 'image/png', A.token);
check(r.status === 200, 'A uploads a PNG into their World folder', `${r.status} ${r.text.slice(0, 120)}`);
r = await upload(coverPath, png, 'image/png', A.token);
check(r.status === 400 || r.status === 409, 'the same file cannot be overwritten', `${r.status} ${r.text.slice(0, 120)}`);
r = await upload(`${A.id}/${worldId}/${crypto.randomUUID()}.png`, Buffer.from('GIF89a'), 'image/gif', A.token);
check(r.status >= 400 && r.status < 500, 'storage refuses a GIF (type not allowed)', `${r.status}`);
r = await upload(`${A.id}/${worldId}/${crypto.randomUUID()}.jpg`, Buffer.alloc(5 * 1024 * 1024 + 1, 0xff), 'image/jpeg', A.token);
check(r.status === 413 || (r.status >= 400 && /size|large|exceed/i.test(r.text)), 'storage refuses a file over 5 MB', `${r.status} ${r.text.slice(0, 80)}`);
r = await upload(`${B.id}/${worldId}/${crypto.randomUUID()}.png`, png, 'image/png', A.token);
check(r.status >= 400 && r.status < 500, "A cannot upload into someone else's folder", `${r.status}`);
r = await upload(`${A.id}/${worldId}/${crypto.randomUUID()}.png`, png, 'image/png', undefined);
check(r.status >= 400 && r.status < 500, 'a signed-out upload is refused', `${r.status}`);
r = await upload(`${B.id}/${worldId}/${crypto.randomUUID()}.png`, png, 'image/png', B.token);
check(r.status >= 400 && r.status < 500, "B cannot upload into A's World", `${r.status}`);

r = await rpc('register_world_asset', { asset_id: coverId, world_id: worldId, storage_path: coverPath }, A.token);
check(r.status === 200 && r.json?.mime_type === 'image/png', 'A registers the upload as an asset', `${r.status} ${r.text.slice(0, 120)}`);
r = await rpc('register_world_asset', { asset_id: coverId, world_id: worldId, storage_path: coverPath }, B.token);
check(r.status >= 400 && r.json?.code === 'P0002', "B cannot register A's file", `${r.status} ${r.json?.code}`);

// A second image that stays unused, to check others cannot read it.
const secretPath = `${A.id}/${worldId}/${secretAsset}.png`;
await upload(secretPath, png, 'image/png', A.token);
await rpc('register_world_asset', { asset_id: secretAsset, world_id: worldId, storage_path: secretPath }, A.token);

r = await rpc('save_world', { world: world({ cover_asset_id: coverId }), question_answers: {} }, A.token);
check(r.status === 200 && r.json?.cover_asset_id === coverId, 'A sets the cover');

r = await rpc('publish_world', { world_id: worldId }, A.token);
check(r.status === 200 && r.json?.status === 'published' && r.json?.problems?.length === 0, 'A publishes', `${r.status} ${r.text.slice(0, 160)}`);
const publishedAt = r.json?.published_at;
r = await rpc('publish_world', { world_id: worldId }, A.token);
check(r.json?.status === 'published' && r.json?.published_at === publishedAt, 'publishing again (a retry after a timeout) changes nothing');

// --- Explorer B and a signed-out visitor ------------------------------------
for (const [who, token] of [['B', B.token], ['signed out', undefined]]) {
  r = await rpc('get_nearby_worlds', { user_lat: lat + 0.001, user_lon: lon, radius_meters: 5000, category_filter: null, search_text: null }, token);
  const hit = Array.isArray(r.json) ? r.json.find((w) => w.id === worldId) : null;
  check(!!hit && hit.distance_meters > 100 && hit.distance_meters < 125, `${who}: the World appears in nearby search with a server distance`, `${r.status}`);
  r = await rpc('get_world_details', { world_id: worldId, from_lat: lat + 0.001, from_lon: lon }, token);
  check(r.status === 200 && r.json?.title === '[e2e] Lighthouse Riddle' && r.json?.block_count === 2 && r.json?.cover_path === coverPath && r.json?.is_creator === false,
    `${who}: details open with cover, part count and no creator rights`, `${r.status} ${r.text.slice(0, 160)}`);
  check(!/keeper|who lived here|find the old lighthouse/i.test(r.text) && !('blocks' in (r.json ?? {})), `${who}: details carry no content and no answer`);
  r = await call('POST', `/storage/v1/object/sign/world-media/${coverPath}`, { token, body: { expiresIn: 60 } });
  const signed = r.json?.signedURL ?? r.json?.signedUrl;
  let imageStatus = null;
  if (signed) imageStatus = (await fetch(`${URL_}/storage/v1${signed}`)).status;
  check(r.status === 200 && imageStatus === 200, `${who}: the published cover can be shown`, `${r.status} ${imageStatus}`);
  r = await call('POST', `/storage/v1/object/sign/world-media/${secretPath}`, { token, body: { expiresIn: 60 } });
  check(r.status >= 400, `${who}: an unused image of A's cannot be read`, `${r.status}`);
  r = await call('GET', `/rest/v1/world_content_blocks?world_id=eq.${worldId}&select=*`, { token });
  check((r.status === 200 && Array.isArray(r.json) && r.json.length === 0) || r.status === 401 || r.status === 403, `${who}: block content is not readable`, `${r.status} ${r.text.slice(0, 80)}`);
}

for (const [name, params] of [
  ['get_world_draft', { world_id: worldId }],
  ['save_world', { world: world({ title: '[e2e] Taken over' }), question_answers: {} }],
  ['unpublish_world', { world_id: worldId }],
  ['delete_world', { world_id: worldId }],
  ['forget_world_asset', { asset_id: secretAsset }],
]) {
  r = await rpc(name, params, B.token);
  check(r.status >= 400 && r.json?.code === 'P0002', `B cannot ${name.replaceAll('_', ' ')} on A's World`, `${r.status} ${r.json?.code}`);
}
r = await rpc('save_world', { world: { id: crypto.randomUUID(), category: 'puzzle', title: '[e2e] B hijack', blocks: [{ id: textId, block_type: 'text', content: { body: 'mine' } }] }, question_answers: {} }, B.token);
check(r.status >= 400 && r.json?.code === '22023', "B cannot reuse A's block ids", `${r.status} ${r.json?.code}`);
r = await call('PATCH', `/rest/v1/worlds?id=eq.${worldId}`, { token: B.token, body: { title: 'hacked' } });
check(r.status === 401 || r.status === 403, 'direct table writes are refused', `${r.status}`);
r = await rpc('save_world', { world: world(), question_answers: {} }, undefined);
check(r.status === 401 || r.json?.code === '42501', 'signed out, saving is refused', `${r.status} ${r.json?.code}`);

r = await rpc('get_world_details', { world_id: worldId }, A.token);
check(r.json?.title === '[e2e] Lighthouse Riddle' && r.json?.is_creator === true, "A's World is unchanged and A is its creator");

// Validation reaches the client as the codes the app maps.
r = await rpc('save_world', { world: world({ blocks: [{ id: questionId, block_type: 'question', content: { prompt: 'x', answer: 'leak' } }] }), question_answers: {} }, A.token);
check(r.status >= 400 && r.json?.code === '22023', 'an answer smuggled into block content is refused', `${r.status} ${r.json?.code}`);
r = await rpc('save_world', { world: world({ blocks: [] }), question_answers: {} }, A.token);
check(r.status >= 400 && r.json?.code === '22023', 'a published World cannot be emptied', `${r.status} ${r.json?.code}`);

// --- Unpublish and clean up -------------------------------------------------
r = await rpc('unpublish_world', { world_id: worldId }, A.token);
check(r.json?.status === 'draft' && r.json?.published_at === publishedAt, 'A unpublishes; the publish date is kept');
r = await rpc('get_nearby_worlds', { user_lat: lat, user_lon: lon, radius_meters: 5000, category_filter: null, search_text: null }, B.token);
check(Array.isArray(r.json) && !r.json.some((w) => w.id === worldId), 'after unpublishing, B no longer finds it');
r = await rpc('get_world_details', { world_id: worldId }, B.token);
check(r.json?.code === 'P0002', 'after unpublishing, B cannot open it');

await rpc('save_world', { world: world({ cover_asset_id: null }), question_answers: {} }, A.token);
for (const assetId of [coverId, secretAsset]) {
  r = await rpc('forget_world_asset', { asset_id: assetId }, A.token);
  const path = r.json;
  const removed = typeof path === 'string'
    ? await call('DELETE', '/storage/v1/object/world-media', { token: A.token, body: { prefixes: [path] } })
    : { status: 0 };
  check(typeof path === 'string' && removed.status === 200, 'A releases and deletes an image', `${r.status} ${removed.status}`);
}
r = await rpc('delete_world', { world_id: worldId }, A.token);
check(r.status === 200 || r.status === 204, 'A deletes the test World', `${r.status} ${r.text.slice(0, 80)}`);
r = await rpc('get_world_draft', { world_id: worldId }, A.token);
check(r.json?.code === 'P0002', 'the deleted World is gone, even for its creator');

console.log(`\n${passed} passed, ${failed} failed. Test World ${worldId} (soft-deleted).`);
console.log(`Accounts: ${state.a.username}, ${state.b.username}`);
process.exitCode = failed ? 1 : 0;
