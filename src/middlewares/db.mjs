import 'dotenv/config';
import pg from 'pg';

if (!process.env.DATABASE_URL) {
    throw new Error('Falta DATABASE_URL. Copia .env.example a .env para desarrollo local.');
}

// pg respeta los parámetros TLS de DATABASE_URL. No se desactiva la verificación.
export const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    max: 10,
    connectionTimeoutMillis: 5000,
    idleTimeoutMillis: 30000,
});
pool.on('error', (error) => console.error('Error en conexión PostgreSQL:', error.code));
