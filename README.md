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
├── infra/
│   ├── etapa_1/                      # Solo repositorios ECR
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars          # No se sube a GitHub
│   └── etapa_2/                      # Infraestructura completa AWS
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars          # No se sube a GitHub
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
| Infraestructura | Terraform · AWS ECS Fargate · ECR · EC2 |

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
Crea un archivo `.env` en la raíz:

```env
MYSQL_ROOT_PASSWORD=
DB_NAME_VENTAS=
DB_NAME_DESPACHOS=
```

### Levantar todo
```bash
docker compose up --build
```

### URLs disponibles
| Servicio | URL |
|----------|-----|
| Frontend | http://localhost:3000 |
| Swagger Ventas | http://localhost:8080/swagger-ui.html |
| Swagger Despachos | http://localhost:8081/swagger-ui.html |

### Detener contenedores
```bash
docker compose down        # detiene y elimina contenedores
docker compose down -v     # elimina también el volumen de datos
```

---

## Etapa 3 — Infraestructura AWS con Terraform

### Arquitectura en AWS

```
Internet
    │
    ▼
ECS Fargate Task (IP pública)
    ├── frontend          (puerto 80)
    ├── backend-ventas    (puerto 8080)
    └── backend-despachos (puerto 8081)
              │
              ▼
       EC2 MySQL (puerto 3306 · 30 GB · t3.micro)
```

> En ECS Fargate los tres contenedores comparten el mismo namespace de red,
> por lo que nginx hace proxy a localhost:8080 y localhost:8081.

### Requisitos
- Terraform instalado (`terraform -v`)
- AWS CLI instalado (`aws --version`)
- Key pair creado en AWS → EC2 → Key Pairs

### Credenciales AWS (LabRole)
En AWS Academy → AWS Details → copia y pega en `~/.aws/credentials`:

```
[default]
aws_access_key_id     = ASIA...
aws_secret_access_key = ...
aws_session_token     = ...
```

> ⚠️ Las credenciales del LabRole expiran cada 4 horas. Renuévalas antes de cada `terraform apply`.


```

### Etapa 3a — Crear repositorios ECR

```bash
cd infra/etapa_1
terraform init
terraform apply
```

### Etapa 3b — Build y push de imágenes a ECR

```bash
# Login a ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 975050276487.dkr.ecr.us-east-1.amazonaws.com

# Backend Ventas
docker build --platform linux/amd64 \
  -t 975050276487.dkr.ecr.us-east-1.amazonaws.com/devops-parcial2-backend-ventas:latest \
  ./back-Ventas_SpringBoot/Springboot-API-REST
docker push 975050276487.dkr.ecr.us-east-1.amazonaws.com/devops-parcial2-backend-ventas:latest

# Backend Despachos
docker build --platform linux/amd64 \
  -t 975050276487.dkr.ecr.us-east-1.amazonaws.com/devops-parcial2-backend-despachos:latest \
  ./back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO
docker push 975050276487.dkr.ecr.us-east-1.amazonaws.com/devops-parcial2-backend-despachos:latest

# Frontend
docker build --platform linux/amd64 \
  -t 975050276487.dkr.ecr.us-east-1.amazonaws.com/devops-parcial2-frontend:latest \
  ./front_despacho
docker push 975050276487.dkr.ecr.us-east-1.amazonaws.com/devops-parcial2-frontend:latest
```

### Etapa 3c — Levantar infraestructura completa

```bash
cd infra/etapa_2
terraform init
terraform apply
```

Los valores sensibles se leen automáticamente desde `terraform.tfvars`.

### URLs en AWS
Una vez desplegado, ve a ECS → Clusters → devops-parcial2-cluster → Tasks → tarea activa → copia la IP pública.

| Servicio | URL |
|----------|-----|
| Frontend | `http://<IP_TAREA_ECS>` |
| Swagger Ventas | `http://<IP_TAREA_ECS>:8080/swagger-ui.html` |
| Swagger Despachos | `http://<IP_TAREA_ECS>:8081/swagger-ui.html` |

### Destruir infraestructura
```bash
cd infra/etapa_2
terraform destroy
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
        ├── fix/jdbc-connection-mysql8           ✅
        ├── feature/terraform-infra              ✅
        └── feature/cicd-pipeline                ⏳
```

---

## Fases del proyecto

| Fase | Descripción | Estado |
|------|-------------|--------|
| **Etapa 1** | Repositorio base en GitHub | ✅ |
| **Etapa 2** | Dockerfiles + docker-compose (despliegue local) | ✅ |
| **Etapa 3** | Infraestructura AWS con Terraform | ✅ |
| **Etapa 4** | Pipeline CI/CD con GitHub Actions | ⏳ |