# Sistema de Gestión de Ventas y Despachos

Aplicación web de gestión de ventas y despachos para Innovatech Chile, compuesta por dos microservicios backend independientes y un frontend React, desplegada en AWS EKS con infraestructura como código (Terraform) y CI/CD con GitHub Actions.

---

## Estructura del proyecto

```
proyecto-devops/
├── back-Ventas_SpringBoot/
│   └── Springboot-API-REST/            # API REST de ventas  · puerto 8080
├── back-Despachos_SpringBoot/
│   └── Springboot-API-REST-DESPACHO/   # API REST de despachos · puerto 8081
├── front_despacho/                     # Frontend React + Tailwind · puerto 80
├── infra/
│   ├── k8s/
│   │   ├── mysql.yml                   # Deployment + Service MySQL
│   │   ├── backend-ventas.yml          # Deployment + Service Backend Ventas
│   │   ├── backend-despachos.yml       # Deployment + Service Backend Despachos
│   │   ├── frontend.yml                # Deployment + Service Frontend (LoadBalancer)
│   │   └── mysql-secret.yml            # Secret K8s (NO se sube a GitHub)
│   └── terraform/
│       ├── providers.tf                # Provider AWS + LabRole
│       ├── variables.tf                # Variables reutilizables
│       ├── vpc.tf                      # VPC + Subnets + IGW
│       ├── security-groups.tf          # Security Groups para nodos
│       ├── ecr.tf                      # Repositorios ECR (3)
│       ├── eks.tf                      # Cluster EKS + Node Group
│       ├── outputs.tf                  # Outputs de Terraform
│       └── terraform.tfvars.example    # Template de variables
├── .github/
│   └── workflows/
│       ├── ci.yml                      # Integración Continua (PR a main)
│       └── cd.yml                      # Despliegue Continuo (push a deploy)
├── docker-compose.yml
├── .env                                # Variables locales (NO se sube a GitHub)
├── .env.example                        # Template de variables locales
├── .gitignore
└── README.md
```

---

## Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Frontend | React 18 · Vite 5 · Tailwind CSS · Axios · Nginx |
| Backend Ventas | Spring Boot 3.4.4 · Java 17 · JPA · Lombok · Swagger |
| Backend Despachos | Spring Boot 3.4.4 · Java 17 · JPA · Lombok · Swagger |
| Base de datos | MySQL 8 (Pod en Kubernetes) |
| Contenedores | Docker · Docker Compose |
| Infraestructura | Terraform · AWS EKS · ECR |
| Orquestación | Kubernetes (EKS) |
| CI/CD | GitHub Actions (CI + CD separados) |

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

### Backend Ventas — `http://<HOST>:8080`

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/v1/ventas` | Listar todas las ventas |
| GET | `/api/v1/ventas/{id}` | Obtener venta por ID |
| POST | `/api/v1/ventas` | Crear venta |
| PUT | `/api/v1/ventas/{id}` | Actualizar venta |
| DELETE | `/api/v1/ventas/{id}` | Eliminar venta |

Swagger UI: `http://<HOST>:8080/swagger-ui.html`

### Backend Despachos — `http://<HOST>:8081`

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/v1/despachos` | Listar todos los despachos |
| GET | `/api/v1/despachos/{id}` | Obtener despacho por ID |
| POST | `/api/v1/despachos` | Crear despacho |
| PUT | `/api/v1/despachos/{id}` | Actualizar despacho |
| DELETE | `/api/v1/despachos/{id}` | Eliminar despacho |

Swagger UI: `http://<HOST>:8081/swagger-ui.html`

---

## Despliegue local con Docker Compose

### Requisitos
- Docker Desktop

### 1. Crear archivo `.env`

Copia el template y edita con tus valores:

```bash
cp .env.example .env
```

El archivo `.env.example` contiene placeholders. El `.env` real no se sube a GitHub.

### 2. Levantar todos los servicios

```bash
docker compose up --build
```

### 3. URLs locales

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

## Infraestructura AWS con Terraform y Kubernetes

### Arquitectura en AWS

```
Internet
    │
    ▼
LoadBalancer (frontend — puerto 80)
    │
    ▼
┌─────────────────────────────────────┐
│  EKS Cluster (devops-parcial2)      │
│                                      │
│  ┌──────────────┐  ┌──────────────┐ │
│  │ backend-ventas│  │backend-desp. │ │
│  │   (2 pods)   │  │   (2 pods)   │ │
│  │   :8080      │  │   :8081      │ │
│  └──────┬───────┘  └──────┬───────┘ │
│         │                 │         │
│  ┌──────┴─────────────────┴───────┐ │
│  │         mysql (1 pod)          │ │
│  │            :3306               │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌──────────┐  ┌──────────┐        │
│  │ frontend │  │ frontend │        │
│  │  (1 pod) │  │  (1 pod) │        │
│  │   :80    │  │   :80    │        │
│  └──────────┘  └──────────┘        │
│                                      │
│  Node Group: 2 x t3.medium          │
└─────────────────────────────────────┘
```

### Requisitos
- Terraform instalado
- AWS CLI instalado y configurado
- kubectl instalado

### 1. Configurar credenciales AWS

Desde AWS Academy → AWS Details, copia las credenciales y configura:

```bash
aws configure
```

> ⚠️ Las credenciales del LabRole expiran cada 4 horas. Debes renovarlas antes de cada operación.

### 2. Crear archivo de variables Terraform

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` si necesitas cambiar algún valor. El archivo no se sube a GitHub.

### 3. Crear la infraestructura

```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```

> ⏱️ El `apply` tarda aproximadamente 12–15 minutos por el cluster EKS.

### 4. Conectar kubectl al cluster

```bash
aws eks update-kubeconfig --region us-east-1 --name devops-parcial2-cluster
kubectl get nodes    # deberías ver 2 nodos Ready
```

### 5. Destruir infraestructura

```bash
cd infra/terraform
terraform destroy
```

---

## Pipeline CI/CD con GitHub Actions

### Flujo de trabajo

```
┌─ CI: Integración Continua ──────────────────┐
│                                               │
│  Se dispara en: pull_request a main           │
│                                               │
│  backend-ventas:   mvn test                   │
│  backend-despachos: mvn test                  │
│  frontend:          npm ci → npm run build    │
└───────────────────────────────────────────────┘

┌─ CD: Despliegue Continuo ────────────────────┐
│                                               │
│  Se dispara en: push a deploy                 │
│                                               │
│  1. Checkout código                           │
│  2. Login a ECR                               │
│  3. Build y Push 3 imágenes a ECR             │
│  4. Conectar a EKS                            │
│  5. Crear Secret con configuración            │
│  6. kubectl apply -f infra/k8s/               │
│  7. kubectl set image (3 deployments)         │
│  8. kubectl rollout status (3 deployments)    │
│  9. Mostrar URL del frontend                  │
└───────────────────────────────────────────────┘
```

### Secrets requeridos en GitHub

Ve a tu repositorio → **Settings → Secrets and variables → Actions → Repository secrets** y agrega:

| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Access key del LabRole |
| `AWS_SECRET_ACCESS_KEY` | Secret key del LabRole |
| `AWS_SESSION_TOKEN` | Session token del LabRole |
| `MYSQL_ROOT_PASSWORD` | Contraseña root de MySQL |
| `DB_ENDPOINT` | Hostname de la base de datos (`mysql`) |
| `DB_PORT` | Puerto de la base de datos (`3306`) |
| `DB_USERNAME` | Usuario de la base de datos (`root`) |
| `DB_NAME_VENTAS` | Nombre de la BD de ventas (`ventas_db`) |
| `DB_NAME_DESPACHOS` | Nombre de la BD de despachos (`despachos_db`) |

> ⚠️ Las credenciales AWS expiran cada 4 horas. Actualízalas antes de hacer push a `deploy`.

### Cómo desplegar

```bash
# Trabaja en la rama de features
git checkout feature/kubernetes-eks
# ... haces cambios ...
git add .
git commit -m "descripción del cambio"
git push origin feature/kubernetes-eks

# Cuando quieras desplegar, mergea a deploy
git checkout deploy
git merge feature/kubernetes-eks
git push origin deploy    # dispara el CD
```

### Disparar el CD manualmente

GitHub → Actions → Despliegue EKS en AWS → **Run workflow**.

---

## Seguridad

- **Secretos en GitHub**: todas las variables de configuración y contraseñas se almacenan en GitHub Secrets, no en el código.
- **Secret en Kubernetes**: el pipeline crea el Secret `mysql-secret` desde GitHub Secrets al momento del despliegue. Los manifiestos K8s solo contienen referencias (`secretKeyRef`).
- **Archivos locales**: `.env`, `mysql-secret.yml` y `terraform.tfvars` están en `.gitignore`.
- **Templates**: `.env.example` y `terraform.tfvars.example` contienen solo placeholders, nunca valores reales.

---

## Cambios realizados en esta versión

Respecto a la versión anterior (ECS), se migró la infraestructura completamente:

| Antes | Ahora |
|-------|-------|
| ECS Fargate | EKS (Kubernetes) |
| Terraform en 2 etapas (`etapa_1`, `etapa_2`) | Terraform unificado en carpeta `terraform/` |
| 1 pipeline (`cd.yml` en push a main) | CI (`ci.yml` en PR a main) + CD (`cd.yml` en push a `deploy`) |
| Configuración hardcodeada en YAML | GitHub Secrets + `secretKeyRef` en K8s |
| Node.js 20 | Node.js 22 |
| 4 secrets en GitHub | 9 secrets en GitHub |
| Swagger por IP pública de ECS | Swagger vía `kubectl port-forward` |
| MySQL en EC2 | MySQL como Pod en EKS |
| `nginx.conf` proxy a `localhost` | Proxy a nombres de servicio K8s |
| Variables en docker-compose hardcodeadas | Todas externalizadas a `.env` |
