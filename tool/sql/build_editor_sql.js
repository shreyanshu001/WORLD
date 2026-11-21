// Builds the three SQL files that apply a migration to the development
// project (see supabase/README.md):
//   1-dry-run.sql            migration + test files, rolled back
//   2-apply-migration.sql    migration + its supabase_migrations row
//   3-tests-after-apply.sql  test files, rolled back
//
// Each file is ONE statement: a DO block that holds the migration and tests
// as text, checks their md5 against the committed files, and runs them.
// So a dry run cannot leave anything behind however it is sent (SQL editor
// or the Supabase connection), and a copy that was altered on the way (a
// clipboard, a retyped character) runs nothing at all.
//
// Usage: node tool/sql/build_editor_sql.js <migration file> [out dir] [tests]
//   out dir  defaults to .sql-to-run/ (gitignored)
//   tests    comma-separated test names (without .sql); defaults to all
// The version and name come from the file name: <version>_<name>.sql.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const [migrationFile, outDir = '.sql-to-run', only] = process.argv.slice(2);
if (!migrationFile) {
  console.error(
    'Usage: node tool/sql/build_editor_sql.js <migration file> [out dir] [tests]',
  );
  process.exit(2);
}
const match = path.basename(migrationFile).match(/^(\d{14})_(.+)\.sql$/);
if (!match) throw new Error('Migration file must be named <version>_<name>.sql');
const [, version, name] = match;

// Git may check files out with Windows line endings; the database gets LF.
const read = (file) => fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n');
const md5 = (text) => crypto.createHash('md5').update(text, 'utf8').digest('hex');

const migration = read(migrationFile);
const testsDir = 'supabase/tests';
const wanted = only ? only.split(',') : null;
const tests = fs
  .readdirSync(testsDir)
  .filter((file) => file.endsWith('_test.sql'))
  .filter((file) => !wanted || wanted.includes(file.replace(/\.sql$/, '')))
  .sort();
if (wanted && tests.length !== wanted.length) {
  throw new Error('Unknown test in: ' + only);
}

// Each test ends by raising its pass message. Chained, each records its
// result instead, and one final error reports them all and rolls back.
function chained(file) {
  const testName = file.replace(/\.sql$/, '');
  const source = read(path.join(testsDir, file));
  const line = `raise exception 'WORLDS_TESTS_PASSED ${testName}: % checks', checks;`;
  if (source.split(line).length !== 2) throw new Error('pass line not found once in ' + file);
  return source.replace(
    line,
    "reset role;\n  perform set_config('worlds_tests.results', " +
      "coalesce(current_setting('worlds_tests.results', true), '') || " +
      `'${testName} ' || checks || ' checks; ', false);`,
  );
}

// One DO block: every part declared as text, verified, then executed.
function oneStatement(parts, ending) {
  const lines = ['do $worlds_run$', 'declare'];
  parts.forEach((part, i) => {
    const tag = `$worlds_part_${i + 1}$`;
    if (part.sql.includes('$worlds_')) throw new Error('dollar-quote tag clash in ' + part.label);
    lines.push(`  part_${i + 1} constant text := ${tag}${part.sql}${tag};`);
  });
  lines.push('begin');
  parts.forEach((part, i) => {
    lines.push(
      `  if md5(part_${i + 1}) <> '${md5(part.sql)}' then`,
      `    raise exception 'WORLDS_TEXT_MISMATCH ${part.label}: this copy differs from the committed file, nothing was run';`,
      '  end if;',
    );
  });
  lines.push(...ending.before);
  parts.forEach((part, i) => lines.push(`  execute part_${i + 1};`));
  lines.push(...ending.after, 'end $worlds_run$;', '');
  return lines.join('\n');
}

// A failure is reported by its message alone; without the inner block the
// error would repeat the whole script as its context.
const rollBack = {
  before: ["  perform set_config('worlds_tests.results', '', false);", '  begin'],
  after: [
    '  exception when others then',
    "    raise exception '%', sqlerrm;",
    '  end;',
    "  raise exception 'WORLDS_ALL_TESTS_PASSED: %', current_setting('worlds_tests.results');",
  ],
};

const migrationPart = { label: path.basename(migrationFile), sql: migration };
const testParts = tests.map((file) => ({ label: file, sql: chained(file) }));

const header = (title, lines) =>
  ['-- ' + title, ...lines.map((l) => '-- ' + l), '', ''].join('\n');

fs.mkdirSync(outDir, { recursive: true });

fs.writeFileSync(
  path.join(outDir, '1-dry-run.sql'),
  header(`WORLDS ${name} — 1 of 3: DRY RUN (changes nothing)`, [
    'Runs the new migration and the tests as one statement, then rolls',
    'everything back by raising an error on purpose.',
    'Expected: an ERROR whose message starts with WORLDS_ALL_TESTS_PASSED.',
  ]) + oneStatement([migrationPart, ...testParts], rollBack),
);

fs.writeFileSync(
  path.join(outDir, '2-apply-migration.sql'),
  header(`WORLDS ${name} — 2 of 3: APPLY the migration (permanent)`, [
    `Runs ${migrationFile} exactly as committed and records it in the`,
    'migration history, as the Supabase migration tool would. One statement:',
    'it applies completely or not at all.',
    'Expected: "Success. No rows returned".',
  ]) +
    oneStatement([migrationPart], {
      before: [
        `  if exists (select 1 from supabase_migrations.schema_migrations where version = '${version}') then`,
        `    raise exception 'WORLDS_ALREADY_APPLIED ${version} ${name}';`,
        '  end if;',
      ],
      after: [
        '  insert into supabase_migrations.schema_migrations (version, name, statements)',
        `  values ('${version}', '${name}', array[part_1]);`,
      ],
    }),
);

fs.writeFileSync(
  path.join(outDir, '3-tests-after-apply.sql'),
  header(`WORLDS ${name} — 3 of 3: TESTS against the applied schema (changes nothing)`, [
    'Runs the tests as one statement, then rolls back by raising an error',
    'on purpose.',
    'Expected: an ERROR whose message starts with WORLDS_ALL_TESTS_PASSED.',
  ]) + oneStatement(testParts, rollBack),
);

console.log(`migration ${version} ${name}`);
console.log('md5 (LF)', md5(migration));
console.log('tests:', tests.join(', '));
