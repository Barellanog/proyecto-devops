# Sistema de Gestión de Ventas y Despachos

Aplicación web de gestión de ventas y despachos para Innovatech Chile, compuesta por dos microservicios backend independientes y un frontend React.

---

## Estructura del proyecto

```
parcial-2/
├── back-Ventas_SpringBoot/
│   └── Springboot-API-REST/          # API REST de ventas  · puerto 8080
├── back-Despachos_SpringBoot/
│   └── Springboot-API-REST-DESPACHO/ # API REST de despachos · puerto 8081
├── front_despacho/                   # Frontend React + Tailwind · puerto 3000
├── docker-compose.yml
├── .env                              # No se sube a GitHub
├── .gitignore
└── README.md
```

---

## Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Frontend | React 18 · Vite 5 · Tailwind CSS · Axios |
| Backend Ventas | Spring Boot 3.4.4 · Java 17 · JPA · Lombok · Swagger |
| Backend Despachos | Spring Boot 3.4.4 · Java 17 · JPA · Lombok · Swagger |
| Base de datos | MySQL 8 |
| Contenedores | Docker · Docker Compose |

---

## Modelos de datos

### Venta
| Campo | Tipo | Descripción |
|-------|------|-------------|
| idVenta | Long | Identificador único |
| direccionCompra | String | Dirección de la compra |
| valorCompra | int | Valor de la compra |
| fechaCompra | LocalDate | Fecha de la compra |
| despachoGenerado | Boolean | Si ya tiene despacho asociado |

### Despacho
| Campo | Tipo | Descripción |
|-------|------|-------------|
| idDespacho | Long | Identificador único |
| fechaDespacho | LocalDate | Fecha del despacho |
| patenteCamion | String | Patente del camión asignado |
| intento | int | Número de intento de entrega |
| idCompra | Long | ID de la venta asociada |
| direccionCompra | String | Dirección de entrega |
| valorCompra | Long | Valor de la compra |
| despachado | boolean | Si fue entregado |

---

## Endpoints

### Backend Ventas — `http://localhost:8080`

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/v1/ventas` | Listar todas las ventas |
| GET | `/api/v1/ventas/{id}` | Obtener venta por ID |
| POST | `/api/v1/ventas` | Crear venta |
| PUT | `/api/v1/ventas/{id}` | Actualizar venta |
| DELETE | `/api/v1/ventas/{id}` | Eliminar venta |

Swagger UI: `http://localhost:8080/swagger-ui.html`

### Backend Despachos — `http://localhost:8081`

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/v1/despachos` | Listar todos los despachos |
| GET | `/api/v1/despachos/{id}` | Obtener despacho por ID |
| POST | `/api/v1/despachos` | Crear despacho |
| PUT | `/api/v1/despachos/{id}` | Actualizar despacho |
| DELETE | `/api/v1/despachos/{id}` | Eliminar despacho |

Swagger UI: `http://localhost:8081/swagger-ui.html`

---

## Etapa 2 — Despliegue local con Docker

### Requisitos
- Docker Desktop

### Variables de entorno
Crea un archivo `.env` en la raíz con:

```env
MYSQL_ROOT_PASSWORD= "Password de root"
DB_NAME_VENTAS= "Nombre del database de ventas"
DB_NAME_DESPACHOS= "Nombre del database de despachos"
```

### Levantar todo
```bash
docker compose up --build
```

### URLs disponibles
| Servicio | URL |
|----------|-----|
| Frontend | http://localhost:3000 |
| Backend Ventas | http://localhost:8080 |
| Swagger Ventas | http://localhost:8080/swagger-ui.html |
| Backend Despachos | http://localhost:8081 |
| Swagger Despachos | http://localhost:8081/swagger-ui.html |

### Detener contenedores
```bash
docker compose down
```

### Eliminar también el volumen de datos
```bash
docker compose down -v
```

---

## Estrategia de versionamiento

```
main          ← código base inicial · solo se toca al inicio y al final
  └── develop ← rama de integración
        ├── feature/dockerfile-backend-ventas    ✅
        ├── feature/dockerfile-backend-despachos ✅
        ├── feature/dockerfile-frontend          ✅
        ├── feature/docker-compose               ✅
        └── feature/cicd-pipeline                ⏳
```

---

## Fases del proyecto

| Fase | Descripción | Estado |
|------|-------------|--------|
| **Etapa 1** | Repositorio base en GitHub | ✅ |
| **Etapa 2** | Dockerfiles + docker-compose (despliegue local) | ✅ |
| **Etapa 3** | Infraestructura AWS con Terraform | ⏳ |
| **Etapa 4** | Pipeline CI/CD con GitHub Actions | ⏳ |