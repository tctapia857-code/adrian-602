import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { test } from 'node:test';
import { pool } from '../src/middlewares/db.mjs';

test('la carga inicial completa 15 productos sin duplicar ni recrear eliminados', async () => {
    const schema = 'seed_test_' + randomUUID().replaceAll('-', '');
    function run(script) {
        const result = spawnSync(process.execPath, [script], {
            env: { ...process.env, PGOPTIONS: `-c search_path=${schema}` },
            encoding: 'utf8',
        });
        assert.equal(result.status, 0, result.stderr);
    }
    try {
        await pool.query(`CREATE SCHEMA ${schema}`);
        run('scripts/migrate.mjs');
        await pool.query(`INSERT INTO ${schema}.productos (nombre) VALUES ('Cuaderno')`);
        run('scripts/seed.mjs');
        run('scripts/seed.mjs');
        const count = await pool.query(`SELECT count(*)::int AS n FROM ${schema}.productos`);
        assert.equal(count.rows[0].n, 15);
        await pool.query(`DELETE FROM ${schema}.productos WHERE nombre = 'Cuaderno'`);
        run('scripts/seed.mjs');
        assert.equal((await pool.query(`SELECT count(*)::int AS n FROM ${schema}.productos`)).rows[0].n, 14);
    } finally {
        await pool.query(`DROP SCHEMA IF EXISTS ${schema} CASCADE`);
        await pool.end();
    }
});
