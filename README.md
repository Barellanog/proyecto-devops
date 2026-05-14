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
│   └── etapa_2/                      # Infraestructura completa AWS
├── .github/
│   └── workflows/
│       └── cd.yml                    # Pipeline CI/CD
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
| CI/CD | GitHub Actions |

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

Crea el archivo `.env` en la raíz del proyecto (no se sube a GitHub):

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

> ⚠️ Las credenciales del LabRole expiran cada 4 horas.

### 2. Crear archivos de variables Terraform

Estos archivos no se suben a GitHub y deben crearse manualmente.

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

### 3. Levantar infraestructura

```bash
cd infra/etapa_2
terraform init
terraform apply
```

### 4. Build y push de imágenes a ECR

Desde la raíz del proyecto:

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

### 6. Obtener IP pública de la tarea

```bash
aws ecs list-tasks --cluster <NOMBRE_DEL_PROYECTO>-cluster --region us-east-1

aws ecs describe-tasks \
  --cluster <NOMBRE_DEL_PROYECTO>-cluster \
  --tasks <ARN_DE_LA_TAREA> \
  --region us-east-1 \
  | grep publicIp
```

### URLs en AWS

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

## Etapa 4 — Pipeline CI/CD con GitHub Actions

El pipeline se dispara automáticamente al hacer push a `main` y realiza el build, push a ECR y redespliegue en ECS de los tres servicios en un solo job.

### Flujo del pipeline

```
push a main
    │
    ▼
Checkout código
    │
    ▼
Configurar credenciales AWS
    │
    ▼
Login en ECR
    │
    ├── Build y Push backend-ventas
    ├── Build y Push backend-despachos
    └── Build y Push frontend
    │
    ▼
Forzar redespliegue en ECS
```

### Secrets requeridos en GitHub

Ve a tu repositorio → Settings → Secrets and variables → Actions → New repository secret y agrega los siguientes:

| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Access key del LabRole (AWS Academy → AWS Details) |
| `AWS_SECRET_ACCESS_KEY` | Secret key del LabRole |
| `AWS_SESSION_TOKEN` | Session token del LabRole |
| `AWS_ACCOUNT_ID` | ID de tu cuenta AWS |

> ⚠️ Las credenciales del LabRole expiran cada 4 horas. Antes de hacer un push a `main` debes actualizar los tres secrets de AWS con las credenciales vigentes.

### Cómo actualizar los secrets de AWS

1. En AWS Academy → AWS Details → copia las credenciales actuales
2. En GitHub → Settings → Secrets and variables → Actions
3. Actualiza `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` y `AWS_SESSION_TOKEN`
4. Haz el push a `main`

### Disparar el pipeline manualmente

Desde GitHub → Actions → Despliegue continuo → Run workflow.

---

## Estrategia de versionamiento

```
main          ← código base inicial · push a main dispara el pipeline CI/CD
  └── develop ← rama de integración
        ├── feature/dockerfile-backend-ventas    ✅
        ├── feature/dockerfile-backend-despachos ✅
        ├── feature/dockerfile-frontend          ✅
        ├── feature/docker-compose               ✅
        ├── fix/jdbc-connection-mysql8           ✅
        ├── feature/terraform-infra              ✅
        └── feature/cicd-pipeline                ✅
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
| **Etapa 4** | Pipeline CI/CD con GitHub Actions | ✅ |