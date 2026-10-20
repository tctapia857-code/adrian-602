import { pathToFileURL } from 'node:url';
import { pool } from '../src/middlewares/db.mjs';

export const productosIniciales = [
    'Cuaderno', 'Lapiz', 'Boligrafo', 'Borrador', 'Sacapuntas',
    'Regla', 'Colores', 'Marcadores', 'Resaltador', 'Pegamento',
    'Tijeras', 'Carpeta', 'Hojas blancas', 'Cartulina', 'Cinta adhesiva',
];

// Una sola carga por base; reiniciar no duplica ni recupera productos eliminados.
export async function seed() {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        await client.query('SELECT pg_advisory_xact_lock(6022026)');
        await client.query('CREATE TABLE IF NOT EXISTS app_seeds (nombre TEXT PRIMARY KEY)');
        const applied = await client.query('SELECT 1 FROM app_seeds WHERE nombre = $1', ['productos-iniciales-v1']);
        if (!applied.rowCount) {
            for (const nombre of productosIniciales) {
                await client.query('INSERT INTO productos (nombre) SELECT $1::text WHERE NOT EXISTS (SELECT 1 FROM productos WHERE lower(trim(nombre)) = lower($1::text))', [nombre]);
            }
            await client.query('INSERT INTO app_seeds (nombre) VALUES ($1)', ['productos-iniciales-v1']);
        }
        await client.query('COMMIT');
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
    try {
        await seed();
        console.log('Catálogo inicial preparado sin duplicados.');
    } catch (error) {
        console.error('Error preparando el catálogo:', error.code || error.name);
        process.exitCode = 1;
    } finally {
        await pool.end();
    }
}
