// Aquí se realiza la conexión a la base de datos

// Librería
import mysql from "mysql2/promise";

async function connect() {
    try {
     const connection = await mysql.createConnection({
    host: "127.0.0.1",   // ⚠️ importante
    user: "root",
    password: "",        // ⚠️ en XAMPP normalmente vacío
    database: "inventario_papeleria",
    port: 3306
});

        return connection;
    } catch (error) {
        console.error(
            "Error al conectar a la base de datos:",
            error.message
        );
        throw error;
    }
}

export default connect;