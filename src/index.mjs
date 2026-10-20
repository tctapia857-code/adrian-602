import config from './middlewares/config.mjs';
import { pool } from './middlewares/db.mjs';
import { createApp } from './app.mjs';
import { migrate } from '../scripts/migrate.mjs';

try {
    await migrate();
    const server = createApp().listen(config.PORT, config.HOST, () => {
        console.log(`API de productos escuchando en el puerto ${config.PORT}`);
    });
    server.on('error', async (error) => {
        console.error('No se pudo iniciar la API:', error.code);
        await pool.end();
        process.exitCode = 1;
    });
    let closing = false;
    function shutdown() {
        if (closing) return;
        closing = true;
        const timeout = setTimeout(() => process.exit(1), 10000);
        timeout.unref();
        server.close(async () => {
            await pool.end();
            clearTimeout(timeout);
        });
    }
    process.on('SIGTERM', shutdown);
    process.on('SIGINT', shutdown);
} catch (error) {
    console.error('No se pudo iniciar PostgreSQL:', error.code || error.name);
    await pool.end();
    process.exitCode = 1;
}
