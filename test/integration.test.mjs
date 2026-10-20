import assert from 'node:assert/strict';
import { once } from 'node:events';
import { after, before, test } from 'node:test';
import { createApp } from '../src/app.mjs';
import { pool } from '../src/middlewares/db.mjs';
import { migrate } from '../scripts/migrate.mjs';

const key = 'integration-test-only';
const ids = new Set();
let server;
let base;
async function request(path, { method = 'GET', body, auth = true, raw } = {}) {
    const response = await fetch(base + path, {
        method,
        headers: { ...(auth ? { 'X-API-Key': key } : {}), 'Content-Type': 'application/json' },
        body: raw ?? (body === undefined ? undefined : JSON.stringify(body)),
    });
    return { status: response.status, data: response.status === 204 ? null : await response.json() };
}
before(async () => {
    await migrate();
    await migrate(); // La preparación se puede repetir sin borrar datos.
    server = createApp({ apiKey: key }).listen(0, '127.0.0.1');
    await once(server, 'listening');
    base = `http://127.0.0.1:${server.address().port}`;
});
after(async () => {
    for (const id of ids) await pool.query('DELETE FROM productos WHERE id = $1', [id]);
    if (server) await new Promise(resolve => server.close(resolve));
    await pool.end();
});
test('health comprueba PostgreSQL y no requiere clave', async () => {
    const result = await request('/health', { auth: false });
    assert.equal(result.status, 200);
    assert.deepEqual(result.data, { status: 'ok', database: 'postgresql' });
});
test('la API protegida rechaza peticiones sin clave', async () => {
    assert.equal((await request('/api/productos', { auth: false })).status, 401);
    assert.equal((await request('/productos', { auth: false })).status, 401);
});
test('CRUD completo y errores 404 para un producto eliminado', async () => {
    const created = await request('/api/productos', { method: 'POST', body: { nombre: '  Prueba integración  ' } });
    assert.equal(created.status, 201);
    const { id } = created.data;
    ids.add(id);
    assert.ok(Number.isInteger(id));
    assert.equal(created.data.nombre, 'Prueba integración');
    assert.equal((await request(`/api/productos/${id}`)).data.nombre, 'Prueba integración');
    assert.ok((await request('/api/productos')).data.some(p => p.id === id));
    const edited = await request(`/api/productos/${id}`, { method: 'PUT', body: { nombre: 'Producto actualizado' } });
    assert.equal(edited.status, 200);
    assert.equal(edited.data.nombre, 'Producto actualizado');
    const legacy = await request('/productos', { method: 'PUT', body: { id, nombre: 'Cliente original' } });
    assert.equal(legacy.status, 200);
    assert.equal((await request(`/productos/${id}`)).data.nombre, 'Cliente original');
    assert.equal((await request(`/api/productos/${id}`, { method: 'DELETE' })).status, 204);
    ids.delete(id);
    assert.equal((await request(`/api/productos/${id}`)).status, 404);
    assert.equal((await request(`/api/productos/${id}`, { method: 'PUT', body: { nombre: 'Ausente' } })).status, 404);
    assert.equal((await request(`/api/productos/${id}`, { method: 'DELETE' })).status, 404);
});
test('valida nombres, id y JSON mal formado', async () => {
    for (const nombre of [undefined, '', '   ', 42, 'a'.repeat(256)]) {
        assert.equal((await request('/api/productos', { method: 'POST', body: { nombre } })).status, 400);
    }
    for (const id of ['0', '-1', '1.2', 'abc', '999999999999999999999', '1%20OR%201=1']) {
        assert.equal((await request('/api/productos/' + id)).status, 400);
    }
    const result = await request('/api/productos', { method: 'POST', raw: '{bad json' });
    assert.equal(result.status, 400);
    assert.equal(result.data.mensaje, 'JSON inválido.');
});
test('consultas parametrizadas conservan texto que parece SQL', async () => {
    const nombre = "Cuaderno'); DROP TABLE productos; --";
    const created = await request('/api/productos', { method: 'POST', body: { nombre } });
    assert.equal(created.status, 201);
    ids.add(created.data.id);
    assert.equal((await request('/api/productos/' + created.data.id)).data.nombre, nombre);
    assert.equal((await request('/api/productos')).status, 200);
});
test('las rutas desconocidas responden JSON y 404', async () => {
    const result = await request('/api/no-existe');
    assert.equal(result.status, 404);
    assert.equal(result.data.mensaje, 'Ruta no encontrada.');
});
