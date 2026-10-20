import 'dotenv/config';

const port = Number(process.env.PORT || 9090);
if (!Number.isInteger(port) || port < 0 || port > 65535) {
    throw new Error('PORT debe ser un puerto válido.');
}
const production = process.env.NODE_ENV === 'production';
if (production && !process.env.API_KEY) {
    throw new Error('Configura API_KEY antes de iniciar en producción.');
}
export default {
    NODE_ENV: process.env.NODE_ENV || 'development',
    HOST: process.env.HOST || '0.0.0.0',
    PORT: port,
    API_KEY: process.env.API_KEY || '',
};
