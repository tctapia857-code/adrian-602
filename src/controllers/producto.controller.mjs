import express from 'express';
import service from '../services/producto.service.mjs';

const router = express.Router();
function idValido(value) {
    const id = Number(value);
    if (!/^\d+$/.test(String(value)) || !Number.isSafeInteger(id) || id < 1 || id > 2147483647) {
        const error = new Error('El id debe ser un entero positivo válido.');
        error.status = 400;
        throw error;
    }
    return id;
}
function nombreValido(value) {
    if (typeof value !== 'string' || !value.trim() || [...value.trim()].length > 255) {
        const error = new Error('nombre es obligatorio y debe tener entre 1 y 255 caracteres.');
        error.status = 400;
        throw error;
    }
    return value.trim();
}
function encontrado(producto) {
    if (!producto) {
        const error = new Error('Producto no encontrado.');
        error.status = 404;
        throw error;
    }
    return producto;
}
router.get('/', async (req, res) => res.json(await service.obtenerRegistros()));
router.get('/:id', async (req, res) => res.json(encontrado(await service.obtenerRegistro(idValido(req.params.id)))));
router.post('/', async (req, res) => {
    const producto = await service.crearRegistro(nombreValido(req.body?.nombre));
    res.location(`${req.baseUrl}/${producto.id}`).status(201).json(producto);
});
async function editar(req, res) {
    const id = idValido(req.params.id ?? req.body?.id);
    const nombre = nombreValido(req.body?.nombre);
    res.json(encontrado(await service.editarRegistro(id, nombre)));
}
router.put('/:id', editar);
router.put('/', editar); // Compatibilidad con el cliente original que envía id en el body.
router.delete('/:id', async (req, res) => {
    encontrado(await service.eliminarRegistro(idValido(req.params.id)));
    res.status(204).end();
});
export default router;
