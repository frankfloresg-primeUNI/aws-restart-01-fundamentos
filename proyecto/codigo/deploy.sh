#!/bin/bash
# Despliega el reto 01: sitio estático en S3 + servidor web en EC2
set -euo pipefail   # detiene el script ante cualquier error

REGION="us-east-2"
BUCKET="frank-reto01-2026"
SG_NAME="reto01-web-sg"
INSTANCE_NAME="reto01-web"

echo "===== PARTE A: S3 ====="

# Fuera de us-east-1 hay que indicar la región explícitamente
aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# Equivale a desmarcar "Block all public access"
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Política de lectura pública
POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "LecturaPublica",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::$BUCKET/*"
  }]
}
EOF
)
aws s3api put-bucket-policy --bucket "$BUCKET" --policy "$POLICY"

# Static website hosting
aws s3 website "s3://$BUCKET" --index-document index.html

# Subir la página
aws s3 cp index.html "s3://$BUCKET/index.html" --content-type "text/html; charset=utf-8"

echo "S3 listo: http://$BUCKET.s3-website.$REGION.amazonaws.com"

echo "===== PARTE B: EC2 ====="

# VPC por defecto de la región
VPC_ID=$(aws ec2 describe-vpcs --region "$REGION" \
  --filters Name=isDefault,Values=true \
  --query "Vpcs[0].VpcId" --output text)

# Security group con solo HTTP
SG_ID=$(aws ec2 create-security-group --region "$REGION" \
  --group-name "$SG_NAME" --description "HTTP publico para reto01" \
  --vpc-id "$VPC_ID" --query GroupId --output text)

aws ec2 authorize-security-group-ingress --region "$REGION" \
  --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0

# AMI más reciente de Amazon Linux 2023 (no se escribe a mano porque cambia)
AMI_ID=$(aws ssm get-parameter --region "$REGION" \
  --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --query Parameter.Value --output text)

# Lanzar la instancia con el user data
INSTANCE_ID=$(aws ec2 run-instances --region "$REGION" \
  --image-id "$AMI_ID" --instance-type t3.micro \
  --security-group-ids "$SG_ID" \
  --user-data file://proyecto/codigo/user-data.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
  --query "Instances[0].InstanceId" --output text)

echo "Esperando a que $INSTANCE_ID esté en ejecución..."
aws ec2 wait instance-running --region "$REGION" --instance-ids "$INSTANCE_ID"

IP=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

echo "EC2 lista: http://$IP  (Apache tarda 1-2 min en instalarse)"