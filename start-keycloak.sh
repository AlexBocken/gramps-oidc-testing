#!/bin/bash
echo "🔐 Starting Keycloak for OIDC testing..."
echo "This requires Docker to be installed and running."

docker run -d \
  --name gramps-keycloak \
  -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak:22.0 \
  start-dev

echo "Keycloak will be available at http://localhost:8080"
echo "Admin credentials: admin/admin"