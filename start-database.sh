#!/bin/bash

echo "🐳 Starting Gramps Infrastructure (PostgreSQL + Redis + Keycloak)..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Start all services
docker-compose up -d

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
while ! docker-compose exec postgres pg_isready -U gramps -d gramps_web > /dev/null 2>&1; do
    sleep 2
done
echo "✅ PostgreSQL is ready!"

# Wait for Redis to be ready
echo "⏳ Waiting for Redis to be ready..."
while ! docker-compose exec redis redis-cli ping > /dev/null 2>&1; do
    sleep 2
done
echo "✅ Redis is ready!"

# Wait for Keycloak to be ready (takes longer to start)
echo "⏳ Waiting for Keycloak to be ready (this may take a minute)..."
timeout=120
elapsed=0
while ! curl -s http://localhost:8080/realms/master > /dev/null 2>&1; do
    if [ $elapsed -ge $timeout ]; then
        echo "⚠️ Keycloak is taking longer than expected to start. Check logs with: docker-compose logs keycloak"
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
done

if curl -s http://localhost:8080/realms/master > /dev/null 2>&1; then
    echo "✅ Keycloak is ready!"
else
    echo "⚠️ Keycloak may still be starting. Check http://localhost:8080 in a few minutes."
fi

echo ""
echo "🎉 Infrastructure services are running!"
echo ""
echo "📊 Service details:"
echo "   📚 PostgreSQL: localhost:5432 (gramps/gramps_password)"
echo "   🔴 Redis: localhost:6379"
echo "   🔐 Keycloak: http://localhost:8080 (admin/admin)"
echo ""
echo "🔴 To stop all services: docker-compose down"
echo "📋 To view logs: docker-compose logs -f [service_name]"