import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
import { pool } from '../src/middlewares/db.mjs';

export async function migrate() {
    const sql = await readFile(new URL('../db/migrations/001_productos.sql', import.meta.url), 'utf8');
    await pool.query(sql);
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
    try {
        await migrate();
        console.log('Esquema de PostgreSQL preparado.');
    } catch (error) {
        console.error('No se pudo preparar PostgreSQL:', error.code || error.name);
        process.exitCode = 1;
    } finally {
        await pool.end();
    }
}
