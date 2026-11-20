// Builds the three files the owner pastes into the Supabase SQL editor to
// apply a migration (see supabase/README.md):
//   1-dry-run.sql            migration + every test file, rolled back
//   2-apply-migration.sql    migration + its supabase_migrations row
//   3-tests-after-apply.sql  every test file, rolled back
//
// Usage: node tool/sql/build_editor_sql.js <migration file> [out dir]
// The version and name come from the file name: <version>_<name>.sql.
// Output goes to .sql-to-run/ (gitignored) by default.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const [migrationFile, outDir = '.sql-to-run'] = process.argv.slice(2);
if (!migrationFile) {
  console.error('Usage: node tool/sql/build_editor_sql.js <migration file> [out dir]');
  process.exit(2);
}
const match = path.basename(migrationFile).match(/^(\d{14})_(.+)\.sql$/);
if (!match) throw new Error('Migration file must be named <version>_<name>.sql');
const [, version, name] = match;

const migration = fs.readFileSync(migrationFile, 'utf8');
const testsDir = 'supabase/tests';
const tests = fs
  .readdirSync(testsDir)
  .filter((file) => file.endsWith('_test.sql'))
  .sort();

// Each test ends by raising its pass message. Chained, each records its
// result instead, and one final error reports them all and rolls back.
function chained(file) {
  const testName = file.replace(/\.sql$/, '');
  const source = fs.readFileSync(path.join(testsDir, file), 'utf8');
  const line = `raise exception 'WORLDS_TESTS_PASSED ${testName}: % checks', checks;`;
  if (source.split(line).length !== 2) throw new Error('pass line not found once in ' + file);
  return source.replace(
    line,
    "reset role;\n  perform set_config('worlds_tests.results', " +
      "coalesce(current_setting('worlds_tests.results', true), '') || " +
      `'${testName} ' || checks || ' checks; ', false);`,
  );
}

const testsOnly =
  tests.map(chained).join('\n\n') +
  "\n\ndo $$ begin raise exception 'WORLDS_ALL_TESTS_PASSED: %', " +
  "current_setting('worlds_tests.results'); end $$;\n";

const header = (title, lines) =>
  ['-- ' + title, ...lines.map((l) => '-- ' + l), '', ''].join('\n');

fs.mkdirSync(outDir, { recursive: true });

fs.writeFileSync(
  path.join(outDir, '1-dry-run.sql'),
  header(`WORLDS ${name} — 1 of 3: DRY RUN (changes nothing)`, [
    'Runs the new migration and every test file in one transaction, then',
    'rolls everything back by raising an error on purpose.',
    'Expected: an ERROR whose message starts with WORLDS_ALL_TESTS_PASSED.',
  ]) +
    migration +
    '\n\n' +
    testsOnly,
);

const tag = '$worlds_migration$';
if (migration.includes(tag)) throw new Error('dollar-quote tag clash');
fs.writeFileSync(
  path.join(outDir, '2-apply-migration.sql'),
  header(`WORLDS ${name} — 2 of 3: APPLY the migration (permanent)`, [
    `Runs ${migrationFile} exactly as committed and records it in the`,
    'migration history, as the Supabase migration tool would.',
    'Expected: "Success. No rows returned".',
  ]) +
    migration +
    '\n\n' +
    'insert into supabase_migrations.schema_migrations (version, name, statements)\n' +
    `values ('${version}', '${name}', array[${tag}${migration}${tag}]);\n`,
);

fs.writeFileSync(
  path.join(outDir, '3-tests-after-apply.sql'),
  header(`WORLDS ${name} — 3 of 3: TESTS against the applied schema (changes nothing)`, [
    'Runs every test file, then rolls back by raising an error on purpose.',
    'Expected: an ERROR whose message starts with WORLDS_ALL_TESTS_PASSED.',
  ]) + testsOnly,
);

console.log(`migration ${version} ${name}`);
console.log('md5 (LF)', crypto.createHash('md5').update(migration, 'utf8').digest('hex'));
console.log('tests:', tests.join(', '));
