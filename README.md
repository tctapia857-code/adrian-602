# API de productos: Node.js + PostgreSQL + Docker

API REST para crear, consultar, editar y eliminar productos. PostgreSQL se ejecuta localmente en Docker y conserva los datos en un volumen. La misma API se puede desplegar en Render y consumir desde n8n.

## 1. Ejecutar localmente

Requisitos: Node.js 22 o 24, npm y Docker con Compose. En Docker Desktop, iniciar Docker antes de continuar.

```bash
cp .env.example .env
npm ci
docker compose up -d --wait postgres
npm start
```

En PowerShell, usar `Copy-Item .env.example .env` en lugar de `cp`. No reemplazar un `.env` que ya contenga tu configuración.

La API escucha en el puerto 9090. `npm run dev` activa la recarga automática. El esquema se prepara al iniciar; también se puede ejecutar `npm run db:migrate`. No se insertan productos automáticamente.

La imagen PostgreSQL 17 está fijada por digest en `compose.yaml`. Docker crea el volumen `adrian-inventario_postgres_data`, montado en `/var/lib/postgresql/data`. `docker compose down` conserva el volumen y `docker compose up -d --wait postgres` recupera sus datos. **`docker compose down -v` elimina los datos**. Las credenciales de `.env.example` son únicamente para el desarrollo local y PostgreSQL solo se publica en loopback.

Si el puerto 5432 ya está ocupado, cambia `POSTGRES_PORT` y el puerto dentro de `DATABASE_URL` en `.env`. No cambies solo uno de los dos.

## 2. Hacer peticiones

| Método | Ruta | Resultado |
| --- | --- | --- |
| GET | `/health` | Verifica la conexión PostgreSQL; 200 o 503 |
| GET | `/api/productos` | Lista de productos |
| GET | `/api/productos/:id` | Un producto o 404 |
| POST | `/api/productos` | Crea un producto; 201 |
| PUT | `/api/productos/:id` | Edita un producto |
| DELETE | `/api/productos/:id` | Elimina un producto; 204 sin cuerpo |

Cuerpo de POST y PUT: `{"nombre":"Cuaderno"}`. El id es autogenerado. Se conservan `/productos` y el PUT original con `{"id":1,"nombre":"Cuaderno"}` como compatibilidad.

```bash
curl --fail http://127.0.0.1:9090/health
curl --fail -X POST http://127.0.0.1:9090/api/productos \
  -H 'Content-Type: application/json' -d '{"nombre":"Cuaderno"}'
curl --fail http://127.0.0.1:9090/api/productos
# Usa el id real que devolvió POST; no se garantiza que sea 1.
curl --fail http://127.0.0.1:9090/api/productos/1
curl --fail -X PUT http://127.0.0.1:9090/api/productos/1 \
  -H 'Content-Type: application/json' -d '{"nombre":"Cuaderno profesional"}'
curl --fail -X DELETE http://127.0.0.1:9090/api/productos/1
```

En Windows PowerShell se puede usar `curl.exe` o un cliente como Postman. En producción, todas las rutas de productos requieren el encabezado `X-API-Key`. `/health` permanece público para Render. Localmente, puedes activar la misma protección asignando `API_KEY` en `.env`.

Las consultas SQL son parametrizadas. Los datos inválidos devuelven 400, la clave ausente o incorrecta 401 y los productos inexistentes 404. Los errores internos no exponen detalles de la conexión.

## 3. Pruebas

Con PostgreSQL iniciado y `.env` configurado:

```bash
npm test
```

Las pruebas usan PostgreSQL real y crean registros temporales, que eliminan al terminar. Comprueban CRUD, validación, claves API, rutas inexistentes y consultas parametrizadas. No uses una base de producción para las pruebas.

## 4. GitHub y Render

El despliegue está descrito en `render.yaml`: API Node.js y PostgreSQL administrado. **Render no puede conectarse al PostgreSQL que está dentro del Docker de tu computadora.** En Render se utiliza una base separada, accesible mediante `DATABASE_URL`; los datos locales no se transfieren automáticamente.

1. Crea una cuenta en Render y conecta tu cuenta GitHub. Autoriza acceso al repositorio `tctapia857-code/adrian-602`.
2. En Render, crea un **Blueprint** desde ese repositorio y selecciona la rama `codex/postgres-render`, que contiene `render.yaml`. Si fusionas la rama en `main`, actualiza `branch` en el YAML antes de usar `main` para el despliegue.
3. Revisa los recursos y precios antes de confirmar. El archivo solicita los planes gratuitos, sujetos a disponibilidad y límites de Render. El PostgreSQL gratuito tiene duración limitada (habitualmente 30 días); no es almacenamiento permanente para producción. No se ha contratado un plan de pago.
4. Render asigna `DATABASE_URL` desde su PostgreSQL y genera `API_KEY`. No uses `localhost` como base de datos en Render. El servidor respeta el `PORT` que Render inyecta y escucha en `0.0.0.0`.
5. Espera al estado **Live** y comprueba `/health` en la URL real que Render asigne. Esa URL no se conoce hasta crear el servicio.
6. Consulta `API_KEY` en las variables del servicio y guárdala como credencial de n8n. No la pegues en el código, el repositorio ni el chat.
7. Crea un producto por POST antes de consultar `GET /api/productos/<id>`. La base comienza vacía y el id puede ser distinto de 1.

El plan gratuito puede suspender la API por inactividad; la primera petición puede tardar más. El flujo de n8n permite hasta 120 segundos por petición.

### Credenciales en Codex

La conexión Git existente sirve para las operaciones Git autorizadas. No necesitas poner un token GitHub en `.env`. Para automatizar Render desde Codex después de crear tu cuenta, configura `RENDER_API_KEY` mediante los secretos de los ajustes del entorno, con destino HTTPS `api.render.com`. El requisito se guardó en el borrador de configuración; no se ha suministrado una credencial ni creado un servicio. El flujo manual de Blueprint usa la sesión de tu cuenta Render y no requiere compartir ese token con Codex.

## 5. Consumir desde n8n

Se incluye `n8n/consultar-producto.json`, un flujo importable con disparador manual, configuración de URL/ID y una petición HTTP GET.

### n8n local, sin cuenta Cloud

```bash
docker compose --profile cliente up -d n8n
```

Abre n8n en tu navegador, en el puerto local 5678, y crea su usuario propietario. Los flujos y credenciales se guardan en el volumen `adrian-inventario_n8n_data`.

Importa el archivo JSON desde el menú de workflows. En **Configurar URL e ID**, usa `http://host.docker.internal:9090` como `apiBaseUrl` y el id de un producto existente. Este hostname permite que el contenedor de n8n llegue a la API del host. `localhost` dentro del contenedor se refiere al propio n8n.

Si `API_KEY` está vacío localmente, selecciona **Authentication: None** en el nodo HTTP. Si la activaste, configura una credencial **Header Auth** con nombre de encabezado `X-API-Key` y tu clave como valor.

### n8n como cliente de Render

1. En n8n Cloud o en tu n8n local, importa `n8n/consultar-producto.json`.
2. Sustituye `https://TU-SERVICIO.onrender.com` por la URL HTTPS real de Render, sin `/` al final.
3. Indica un `productoId` existente.
4. En **Consultar producto**, crea o selecciona una credencial **Header Auth**: `Name = X-API-Key`, `Value =` la API_KEY de Render. El JSON exportado no contiene credenciales.
5. Ejecuta el flujo. El nodo HTTP debe devolver `{"id":...,"nombre":"..."}`. Un 404 indica que ese producto no existe; un 401 indica que falta o no coincide la clave.

n8n llama a la API por HTTPS; no necesita acceso directo a PostgreSQL ni las credenciales de la base de datos. Para crear o editar desde n8n, usa el mismo nodo HTTP con POST/PUT, encabezado `Content-Type: application/json` y cuerpo JSON con `nombre`.
