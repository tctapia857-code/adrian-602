// Librerías 
import "rootpath";
import express from "express";
import cors from "cors";
import morgan from "morgan";

// Archivos de configuración propios 
import config from "./middlewares/config.mjs";
import errorHandler from "./middlewares/error-handler.mjs";

// Controller
import ProductoController from "./controllers/producto.controller.mjs";

// Instancia del servidor 
const app = express();

// Middlewares
app.use(morgan("dev"));
app.use(express.json()); // 🔥 reemplaza bodyParser
app.use(express.urlencoded({ extended: false }));
app.use(cors());

// Ruta principal (mejor en plural)
app.use("/productos", ProductoController);

// Middleware de errores (SIEMPRE al final)
app.use(errorHandler);

// Inicia el servidor 
app.listen(config.PORT, () => {
    console.log("Server listening on port", config.PORT);
});