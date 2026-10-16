// Runs real Firestore security rules locally. Never contacts a live project.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawn } = require('node:child_process');

const project = 'demo-zeka-arena';
const origin = 'http://127.0.0.1:8185';
const database = `projects/${project}/databases/(default)`;
const root = path.resolve(__dirname, '..');
const java = process.env.ARENA_TEST_JAVA || 'java';
const jar = process.env.ARENA_TEST_EMULATOR_JAR;
assert(jar, 'Set ARENA_TEST_EMULATOR_JAR to the cached Firestore emulator JAR.');

function value(input) {
  if (input === null) return { nullValue: null };
  if (input instanceof Date) return { timestampValue: input.toISOString() };
  if (typeof input === 'string') return { stringValue: input };
  if (typeof input === 'number') return { integerValue: String(input) };
  if (Array.isArray(input)) return { arrayValue: { values: input.map(value) } };
  return { mapValue: { fields: fields(input) } };
}

function fields(input) {
  return Object.fromEntries(Object.entries(input).map(([key, item]) => [key, value(item)]));
}

function token(uid) {
  const now = Math.floor(Date.now() / 1000);
  const encode = (data) => Buffer.from(JSON.stringify(data)).toString('base64url');
  return `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
    iss: `https://securetoken.google.com/${project}`,
    aud: project,
    sub: uid,
    user_id: uid,
    iat: now,
    exp: now + 3600,
    auth_time: now,
    firebase: { sign_in_provider: 'anonymous', identities: {} },
  })}.`;
}

async function request(route, body, auth = 'owner', method = 'POST') {
  const response = await fetch(`${origin}${route}`, {
    method,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${auth}` },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(20000),
  });
  return { status: response.status, body: await response.json() };
}

async function rules(content) {
  const result = await request(`/emulator/v1/projects/${project}:securityRules`, {
    rules: { files: [{ name: 'firestore.rules', content }] },
  }, 'owner', 'PUT');
  assert.equal(result.status, 200, JSON.stringify(result.body));
  assert(!(result.body.issues || []).some((issue) => issue.severity === 'ERROR'), JSON.stringify(result.body));
}

async function seedGroup(id, members = ['host', 'guest'], extra = {}) {
  const now = new Date();
  const result = await request(`/v1/${database}/documents:commit`, { writes: [{ update: {
    name: `${database}/documents/arena_groups_v1/${id}`,
    fields: fields({ ownerUid: 'host', name: 'Test group', joinCode: 'TEST42',
      joinCodeProof: 'TEST42:guest', memberIds: members, activeEventId: null,
      eventSequence: 0, schemaVersion: 2, createdAt: now, updatedAt: now, ...extra }),
  } }] });
  assert.equal(result.status, 200, JSON.stringify(result.body));
}

let sequence = 0;
async function createEvent(groupId, games, { uid = 'host', participants = ['host', 'guest'], link = true } = {}) {
  const eventId = `event-${++sequence}`;
  const event = { groupId, ownerUid: uid, title: 'Test race', format: 'direct', status: 'active',
    level: 1, gameIds: games, participantIds: participants,
    layoutCodes: Object.fromEntries(games.map((game, index) => [game, index + 1])),
    endsAt: new Date(Date.now() + 48 * 3600000), schemaVersion: 2 };
  const writes = [{ update: { name: `${database}/documents/arena_events_v1/${eventId}`, fields: fields(event) },
    updateTransforms: ['createdAt', 'updatedAt'].map((fieldPath) => ({ fieldPath, setToServerValue: 'REQUEST_TIME' })) }];
  if (link) writes.push({ update: { name: `${database}/documents/arena_groups_v1/${groupId}`,
    fields: fields({ activeEventId: eventId, eventSequence: 1, schemaVersion: 2 }) },
    updateMask: { fieldPaths: ['activeEventId', 'eventSequence', 'schemaVersion'] },
    updateTransforms: [{ fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }] });
  return request(`/v1/${database}/documents:commit`, { writes }, token(uid));
}

async function expectStatus(promise, expected, description) {
  const result = await promise;
  assert.equal(result.status, expected, `${description}: ${JSON.stringify(result.body)}`);
  console.log(`PASS ${description}`);
}

async function main() {
  let log = '';
  const emulator = spawn(java, ['-jar', jar, '--host', '127.0.0.1', '--port', '8185',
    '--project_id', project, '--single_project_mode', 'true'], { windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
  emulator.stdout.on('data', (data) => { log += data; });
  emulator.stderr.on('data', (data) => { log += data; });
  emulator.on('error', (error) => { log += error.message; });
  try {
    let ready = false;
    for (let attempt = 0; attempt < 100; attempt++) {
      try {
        await fetch(`${origin}/`, { signal: AbortSignal.timeout(500) });
        ready = true;
        break;
      } catch { await new Promise((resolve) => setTimeout(resolve, 300)); }
    }
    assert(ready, `Emulator startup failed: ${log.slice(-5000)}`);
    const oldRules = path.join(root, '.codex-runtime/arena-rules/production-before.rules');
    if (fs.existsSync(oldRules)) {
      await rules(fs.readFileSync(oldRules, 'utf8'));
      await seedGroup('old-rules');
      await expectStatus(createEvent('old-rules', ['numbers', 'memory', 'hanoi', 'blocks', 'reflex', 'world_atlas']), 403,
        'published old rules reproduce permission-denied for a new game');
    }
    await rules(fs.readFileSync(path.join(root, 'firestore.rules'), 'utf8'));
    const catalog = fs.readFileSync(path.join(root, 'lib/features/catalog/domain/studio_game_catalog.dart'), 'utf8');
    const retiredBlock = catalog.match(/retiredGameIds = <String>\{([\s\S]*?)\};/)[1];
    const retired = new Set([...retiredBlock.matchAll(/'([^']+)'/g)].map((match) => match[1]));
    const active = [...catalog.matchAll(/GameDefinition\(([\s\S]*?)\),/g)]
      .map((match) => ({ id: match[1].match(/id: '([^']+)'/)?.[1], playable: /isPlayable: true/.test(match[1]) }))
      .filter((game) => game.id && game.playable && !retired.has(game.id)).map((game) => game.id);
    assert.equal(active.length, 44);
    for (const game of active) {
      const games = [game, ...active.filter((candidate) => candidate !== game).slice(0, 5)];
      await seedGroup(`active-${game}`);
      await expectStatus(createEvent(`active-${game}`, games), 200, `owner can start race containing ${game}`);
    }
    const games = active.slice(0, 6);
    await seedGroup('non-owner');
    await expectStatus(createEvent('non-owner', games, { uid: 'guest' }), 403, 'non-owner cannot start a race');
    await seedGroup('outsider');
    await expectStatus(createEvent('outsider', games, { uid: 'outsider' }), 403, 'outsider cannot start a race');
    await seedGroup('single-member', ['host']);
    await expectStatus(createEvent('single-member', games, { participants: ['host'] }), 403, 'one member cannot start a race');
    await seedGroup('wrong-participants');
    await expectStatus(createEvent('wrong-participants', games, { participants: ['host', 'outsider'] }), 403,
      'race cannot substitute outsiders for group members');
    await seedGroup('unlinked');
    await expectStatus(createEvent('unlinked', games, { link: false }), 403, 'race must be linked atomically to its group');
    await seedGroup('duplicates');
    await expectStatus(createEvent('duplicates', Array(6).fill(active[0])), 403, 'duplicate games are rejected');
    await seedGroup('unknown-game');
    await expectStatus(createEvent('unknown-game', ['unreleased-game', ...active.slice(0, 5)]), 403,
      'unknown games are rejected');
    console.log('All arena security rule tests passed.');
  } finally {
    emulator.kill();
  }
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
