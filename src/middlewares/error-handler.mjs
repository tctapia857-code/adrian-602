export default function errorHandler(error, req, res, next) {
    if (res.headersSent) return next(error);
    const status = Number.isInteger(error.status) && error.status >= 400 && error.status < 500 ? error.status : 500;
    if (status === 500) console.error('Error en API:', error.code || error.name);
    const mensaje = error.type === 'entity.parse.failed' ? 'JSON inválido.'
        : status === 500 ? 'No se pudo completar la petición.' : error.message;
    res.status(status).json({ mensaje });
}
