#!/bin/bash
# Elimina todo lo creado por deploy.sh
set -euo pipefail

REGION="us-east-2"
BUCKET="frank-reto01-2026"
SG_NAME="reto01-web-sg"
INSTANCE_NAME="reto01-web"

echo "===== PARTE B: EC2 ====="

# Buscar instancias por su etiqueta Name (en cualquier estado que no sea terminada)
INSTANCE_IDS=$(aws ec2 describe-instances --region "$REGION" \
  --filters "Name=tag:Name,Values=$INSTANCE_NAME" \
            "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query "Reservations[].Instances[].InstanceId" --output text)

if [ -n "$INSTANCE_IDS" ]; then
  aws ec2 terminate-instances --region "$REGION" --instance-ids $INSTANCE_IDS > /dev/null
  echo "Terminando: $INSTANCE_IDS ... (esperando, puede tardar 1-2 min)"
  # Sin este wait, el SG sigue "en uso" y delete-security-group falla
  aws ec2 wait instance-terminated --region "$REGION" --instance-ids $INSTANCE_IDS
else
  echo "No hay instancias activas con nombre $INSTANCE_NAME"
fi

# Buscar el security group por nombre
SG_ID=$(aws ec2 describe-security-groups --region "$REGION" \
  --filters "Name=group-name,Values=$SG_NAME" \
  --query "SecurityGroups[0].GroupId" --output text)

if [ "$SG_ID" != "None" ]; then
  aws ec2 delete-security-group --region "$REGION" --group-id "$SG_ID"
  echo "Security group $SG_ID eliminado"
else
  echo "No existe el security group $SG_NAME"
fi

echo "===== PARTE A: S3 ====="

if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  aws s3 rb "s3://$BUCKET" --force   # vacía y borra el bucket
  echo "Bucket $BUCKET eliminado"
else
  echo "El bucket $BUCKET no existe"
fi

echo "Limpieza completa."