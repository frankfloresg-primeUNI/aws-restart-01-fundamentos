#!/bin/bash
dnf install -y httpd
systemctl enable --now httpd

# Token de seguridad para acceder a información de la instancia
TOKEN=$(curl -s -X PUT \
    "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Consultamos el ID y la zona 
ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN"  \
    http://169.254.169.254/latest/meta-data/instance-id)

AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Crear la página HTML
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><title>Reto 01 - EC2</title></head>
<body>
  <h1>Hola, soy Frank</h1>
  <p>Esta página está servida desde: <strong>EC2 (con servidor)</strong></p>
  <p>Instancia: $ID | Zona: $AZ</p>
</body>
</html>
EOF