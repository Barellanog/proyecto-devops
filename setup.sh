#!/bin/bash
# ============================================
# Script de configuración inicial
# proyecto-devops — Innovatech Chile
# ============================================
#
# ORDEN DE EJECUCIÓN:
#   1. aws configure
#   2. ./setup.sh              (crea archivos locales)
#   3. terraform init && apply (crea infraestructura en AWS)
#   4. ./setup.sh              (conecta kubectl + Metrics Server)
#   5. Configurar 9 GitHub Secrets
#   6. git push origin deploy  (dispara el CD)
#
# ============================================
set -e

CLUSTER_NAME="devops-parcial2-cluster"
AWS_REGION="us-east-1"

echo ""
echo "=========================================="
echo "  SETUP — Sistema de Ventas y Despachos"
echo "  Innovatech Chile"
echo "=========================================="
echo ""

# ────────────────────────────────────────
# FASE 1: Archivos locales (siempre)
# ────────────────────────────────────────
echo "── FASE 1: Archivos locales"

if [ ! -f .env ]; then
  cp .env.example .env
  echo "  ✅ .env creado"
else
  echo "  ⏭️  .env ya existe"
fi



# ────────────────────────────────────────
# FASE 2: Verificar herramientas
# ────────────────────────────────────────
echo ""
echo "── FASE 2: Verificar herramientas"

if ! command -v aws &> /dev/null; then
  echo "  ❌ AWS CLI no instalado"
  echo "     https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
  exit 1
fi
echo "  ✅ AWS CLI"

if ! command -v terraform &> /dev/null; then
  echo "  ❌ Terraform no instalado"
  echo "     https://developer.hashicorp.com/terraform/downloads"
  exit 1
fi
echo "  ✅ Terraform"

if ! command -v kubectl &> /dev/null; then
  echo "  ❌ kubectl no instalado"
  echo "     https://kubernetes.io/docs/tasks/tools/"
  exit 1
fi
echo "  ✅ kubectl"

# ────────────────────────────────────────
# FASE 3: Verificar credenciales AWS
# ────────────────────────────────────────
echo ""
echo "── FASE 3: Verificar credenciales AWS"

if ! aws sts get-caller-identity &> /dev/null; then
  echo ""
  echo "  ⚠️  Credenciales AWS no configuradas."
  echo ""
  echo "  PASO 1 — Ejecuta esto primero:"
  echo "    aws configure"
  echo "    (usa las credenciales del LabRole de AWS Academy)"
  echo ""
  echo "  Luego vuelve a correr:"
  echo "    ./setup.sh"
  echo ""
  exit 1
fi
echo "  ✅ Credenciales AWS válidas"

# ────────────────────────────────────────
# FASE 4: Conectar kubectl al cluster
# ────────────────────────────────────────
echo ""
echo "── FASE 4: Conectar kubectl al cluster EKS"

if aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION &> /dev/null; then
  aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
  echo "  ✅ Conectado a $CLUSTER_NAME"

  # ────────────────────────────────────────
  # FASE 5: Metrics Server
  # ────────────────────────────────────────
  echo ""
  echo "── FASE 5: Instalar Metrics Server (HPA)"

  if kubectl get deployment metrics-server -n kube-system &> /dev/null; then
    echo "  ✅ Metrics Server ya está corriendo"
  else
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    echo "  ✅ Metrics Server instalado"
  fi

  # ────────────────────────────────────────
  # FASE 6: Estado del cluster
  # ────────────────────────────────────────
  echo ""
  echo "=========================================="
  echo "  ESTADO DEL CLUSTER"
  echo "=========================================="
  echo ""
  echo "Nodos:"
  kubectl get nodes 2>/dev/null || echo "  (no disponible)"
  echo ""
  echo "Pods:"
  kubectl get pods 2>/dev/null || echo "  (aún no hay pods desplegados)"
  echo ""
  echo "HPA:"
  kubectl get hpa 2>/dev/null || echo "  (aún no hay HPA configurados)"

else
  echo ""
  echo "  ⚠️  El cluster '$CLUSTER_NAME' no existe todavía."
  echo ""
  echo "  PASO 3 — Crea la infraestructura:"
  echo "    cd infra/terraform"
  echo "    terraform init"
  echo "    terraform apply"
  echo ""
  echo "  PASO 4 — Vuelve a correr este script:"
  echo "    ./setup.sh"
  echo "    (conectará kubectl y configurará Metrics Server)"
  echo ""
fi

# ────────────────────────────────────────
# FASE 7: Próximos pasos
# ────────────────────────────────────────
echo ""
echo "=========================================="
echo "  PRÓXIMOS PASOS"
echo "=========================================="
echo ""
echo "  PASO 5 — Configura los 9 secrets en GitHub:"
echo "    Settings → Secrets and variables → Actions"
echo "    AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,"
echo "    AWS_SESSION_TOKEN, MYSQL_ROOT_PASSWORD,"
echo "    DB_ENDPOINT, DB_PORT, DB_USERNAME,"
echo "    DB_NAME_VENTAS, DB_NAME_DESPACHOS"
echo ""
echo "  PASO 6 — Dispara el despliegue:"
echo "    git checkout deploy"
echo "    git merge main"
echo "    git push origin deploy"
echo ""
echo "  Opcional — Probar local:"
echo "    docker compose up --build"
echo ""
echo "=========================================="
