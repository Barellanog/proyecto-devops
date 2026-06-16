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
│   │   └── hpa.yml                     # Horizontal Pod Autoscaler
│   └── terraform/
│       ├── providers.tf                # Provider AWS + LabRole
│       ├── variables.tf                # Variables reutilizables
│       ├── vpc.tf                      # VPC + Subnets + IGW
│       ├── security-groups.tf          # Security Groups para nodos
│       ├── ecr.tf                      # Repositorios ECR (3)
│       ├── eks.tf                      # Cluster EKS + Node Group
│       ├── outputs.tf                  # Outputs de Terraform
│       ├── cloudwatch.tf               # CloudWatch Logs + Dashboard
│       └── dashboard.tf                # Dashboard de monitoreo
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
| Autoscaling | Horizontal Pod Autoscaler (HPA) + Node Group scaling |
| Monitoreo | CloudWatch Logs + Dashboard + Metrics Server |
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
- Terraform
- AWS CLI
- kubectl
- Docker Desktop (para desarrollo local)

### ⚡ Setup rápido (recomendado)

El script `setup.sh` automatiza todo el proceso:

```bash
# PASO 1 — Configurar credenciales AWS
aws configure
# (usa las credenciales del LabRole de AWS Academy)

# PASO 2 — Ejecutar script de setup
./setup.sh
# crea .env
# verifica herramientas y credenciales

# PASO 3 — Crear infraestructura en AWS
cd infra/terraform
terraform init
terraform apply
# ⏱️ ~12-15 minutos

# PASO 4 — Conectar kubectl y Metrics Server
cd ../..
./setup.sh
# conecta kubectl, instala Metrics Server, muestra estado

# PASO 5 — Configurar GitHub Secrets (ver sección Secrets)

# PASO 6 — Disparar el despliegue
git checkout deploy
git merge main
git push origin deploy
```

> ⚠️ Las credenciales del LabRole expiran cada 4 horas.

### Setup manual (alternativa)

Si prefieres hacerlo paso a paso sin el script:

```bash
# 1. Archivos locales
cp .env.example .env

# 2. Infraestructura
cd infra/terraform
terraform init
terraform apply

# 3. Conectar kubectl
aws eks update-kubeconfig --region us-east-1 --name devops-parcial2-cluster

# 4. Metrics Server (necesario para HPA)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Destruir infraestructura

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

## Autoscaling

### Horizontal Pod Autoscaler (HPA)

Los backends escalan automáticamente según CPU y memoria:

| Recurso | Min réplicas | Max réplicas | CPU target | Mem target |
|---------|:-----------:|:-----------:|:----------:|:----------:|
| `backend-ventas` | 2 | 4 | 50% | 70% |
| `backend-despachos` | 2 | 4 | 50% | 70% |

```bash
# Ver estado del HPA
kubectl get hpa

# Ver métricas en tiempo real
kubectl top pods

# Simular carga (para demo)
kubectl run load-test --image=busybox --restart=Never -- /bin/sh -c "
  while true; do
    wget -q -O- http://backend-ventas:8080/api/v1/ventas
    sleep 0.1
  done
"
```

### Node Group Scaling

| Parámetro | Valor |
|-----------|-------|
| Mínimo | 1 nodo |
| Deseado | 2 nodos |
| Máximo | 2 nodos |
| Tipo | t3.medium |

---

## Seguridad

- **Secretos en GitHub**: todas las variables de configuración y contraseñas se almacenan en GitHub Secrets, no en el código.
- **Secret en Kubernetes**: el pipeline CD crea el Secret `mysql-secret` desde GitHub Secrets al momento del despliegue. Los manifiestos K8s solo contienen referencias (`secretKeyRef`). No existe archivo YAML de secret en el repositorio.
- **Archivo local**: solo `.env` está en `.gitignore`. Las variables de Terraform viven en `variables.tf` con defaults seguros.
- **Template**: `.env.example` contiene solo placeholders, nunca valores reales.

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
| Sin autoscaling | HPA en backends + Node Group scaling |
| Sin monitoreo | CloudWatch Logs + Dashboard + Metrics Server |
