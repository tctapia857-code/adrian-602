import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import { timingSafeEqual } from 'node:crypto';
import config from './middlewares/config.mjs';
import { pool } from './middlewares/db.mjs';
import productos from './controllers/producto.controller.mjs';
import errorHandler from './middlewares/error-handler.mjs';

export function createApp({ apiKey = config.API_KEY } = {}) {
    const app = express();
    app.disable('x-powered-by');
    app.use(morgan('dev'));
    app.use(cors());
    app.use(express.json({ limit: '100kb' }));
    app.get('/health', async (req, res) => {
        try {
            await pool.query('SELECT 1');
            res.json({ status: 'ok', database: 'postgresql' });
        } catch {
            res.status(503).json({ status: 'error', database: 'unavailable' });
        }
    });
    function authenticate(req, res, next) {
        if (!apiKey) return next();
        const provided = Buffer.from(req.get('X-API-Key') || '');
        const expected = Buffer.from(apiKey);
        if (provided.length !== expected.length || !timingSafeEqual(provided, expected)) {
            return res.status(401).json({ mensaje: 'API key inválida o ausente.' });
        }
        next();
    }
    app.use('/api/productos', authenticate, productos);
    app.use('/productos', authenticate, productos);
    app.use((req, res) => res.status(404).json({ mensaje: 'Ruta no encontrada.' }));
    app.use(errorHandler);
    return app;
}
