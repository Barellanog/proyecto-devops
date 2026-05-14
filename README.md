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
│   ├── etapa_1/                      # Repositorios ECR únicamente
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars          # ⚠️ No se sube a GitHub — crear manualmente
│   └── etapa_2/                      # Infraestructura completa AWS
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars          # ⚠️ No se sube a GitHub — crear manualmente
├── docker-compose.yml
├── .env                              # ⚠️ No se sube a GitHub — crear manualmente
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

### 1. Crear el archivo de variables de entorno

Crea el archivo `.env` en la **raíz del proyecto** (no se sube a GitHub):

```env
MYSQL_ROOT_PASSWORD=<TU_PASSWORD>
DB_NAME_VENTAS=ventas_db
DB_NAME_DESPACHOS=despachos_db
```

### 2. Levantar todos los servicios

```bash
docker compose up --build
```

### 3. URLs disponibles

| Servicio | URL |
|----------|-----|
| Frontend | http://localhost:3000 |
| Swagger Ventas | http://localhost:8080/swagger-ui.html |
| Swagger Despachos | http://localhost:8081/swagger-ui.html |

### Comandos útiles

```bash
docker compose down        # detiene y elimina contenedores
docker compose down -v     # elimina también el volumen de datos
docker compose logs -f     # ver logs en tiempo real
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
- Docker Desktop
- Key pair creado en AWS → EC2 → Key Pairs

### 1. Configurar credenciales AWS

En AWS Academy → AWS Details → copia y pega en `~/.aws/credentials`:

```
[default]
aws_access_key_id     = <ACCESS_KEY>
aws_secret_access_key = <SECRET_KEY>
aws_session_token     = <SESSION_TOKEN>
```

> ⚠️ Las credenciales del LabRole expiran cada 4 horas. Renuévalas antes de cada `terraform apply`.

### 2. Crear los archivos de variables de Terraform

Estos archivos no se suben a GitHub y deben crearse manualmente al clonar el repositorio.

`infra/etapa_1/terraform.tfvars`:
```hcl
aws_region   = "us-east-1"
project_name = "<NOMBRE_DEL_PROYECTO>"
```

`infra/etapa_2/terraform.tfvars`:
```hcl
aws_region    = "us-east-1"
project_name  = "<NOMBRE_DEL_PROYECTO>"
key_pair_name = "<NOMBRE_DE_TU_KEY_PAIR>"
db_password   = "<TU_PASSWORD>"
```

> El `project_name` debe ser el mismo en ambos archivos.

### 3. Levantar la infraestructura

```bash
cd infra/etapa_2
terraform init
terraform apply
```

Terraform creará:
- VPC + subnet pública + internet gateway
- Security groups (puertos 22, 80, 8080, 8081, 3306)
- 3 repositorios ECR (frontend, backend-ventas, backend-despachos)
- EC2 para MySQL (30 GB · t3.micro)
- ECS Fargate cluster + task con los 3 contenedores
- CloudWatch log group (retención 7 días)

### 4. Build y push de imágenes a ECR

Desde la **raíz del proyecto**, reemplaza `<ACCOUNT_ID>` y `<NOMBRE_DEL_PROYECTO>`:

```bash
# Login a ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Backend Ventas
docker build --platform linux/amd64 \
  -t <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/<NOMBRE_DEL_PROYECTO>-backend-ventas:latest \
  ./back-Ventas_SpringBoot/Springboot-API-REST
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/<NOMBRE_DEL_PROYECTO>-backend-ventas:latest

# Backend Despachos
docker build --platform linux/amd64 \
  -t <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/<NOMBRE_DEL_PROYECTO>-backend-despachos:latest \
  ./back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/<NOMBRE_DEL_PROYECTO>-backend-despachos:latest

# Frontend
docker build --platform linux/amd64 \
  -t <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/<NOMBRE_DEL_PROYECTO>-frontend:latest \
  ./front_despacho
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/<NOMBRE_DEL_PROYECTO>-frontend:latest
```

### 5. Forzar redespliegue en ECS

```bash
aws ecs update-service \
  --cluster <NOMBRE_DEL_PROYECTO>-cluster \
  --service app \
  --force-new-deployment \
  --region us-east-1
```

### 6. Obtener la IP pública de la tarea

```bash
# Listar tareas activas
aws ecs list-tasks \
  --cluster <NOMBRE_DEL_PROYECTO>-cluster \
  --region us-east-1

# Obtener IP de la tarea
aws ecs describe-tasks \
  --cluster <NOMBRE_DEL_PROYECTO>-cluster \
  --tasks <ARN_DE_LA_TAREA> \
  --region us-east-1 \
  | grep publicIp
```

### 7. URLs en AWS

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

Convención de commits:
```
feat: descripción de la funcionalidad agregada
fix:  descripción del bug corregido
docs: cambios en documentación
```

---

## Fases del proyecto

| Fase | Descripción | Estado |
|------|-------------|--------|
| **Etapa 1** | Repositorio base en GitHub | ✅ |
| **Etapa 2** | Dockerfiles + docker-compose (despliegue local) | ✅ |
| **Etapa 3** | Infraestructura AWS con Terraform | ✅ |
| **Etapa 4** | Pipeline CI/CD con GitHub Actions | ⏳ |