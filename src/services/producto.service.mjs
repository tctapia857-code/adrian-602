import { pool } from '../middlewares/db.mjs';

async function obtenerRegistros() {
    const { rows } = await pool.query('SELECT id, nombre FROM productos ORDER BY id');
    return rows;
}
async function obtenerRegistro(id) {
    const { rows } = await pool.query('SELECT id, nombre FROM productos WHERE id = $1', [id]);
    return rows[0];
}
async function crearRegistro(nombre) {
    const { rows } = await pool.query('INSERT INTO productos (nombre) VALUES ($1) RETURNING id, nombre', [nombre]);
    return rows[0];
}
async function editarRegistro(id, nombre) {
    const { rows } = await pool.query('UPDATE productos SET nombre = $1 WHERE id = $2 RETURNING id, nombre', [nombre, id]);
    return rows[0];
}
async function eliminarRegistro(id) {
    const { rows } = await pool.query('DELETE FROM productos WHERE id = $1 RETURNING id', [id]);
    return rows[0];
}
export default { obtenerRegistros, obtenerRegistro, crearRegistro, editarRegistro, eliminarRegistro };
