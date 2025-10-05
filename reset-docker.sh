#!/bin/bash

echo "Stopping and removing Docker Compose services..."
docker-compose down

echo "Removing volumes..."
docker-compose down -v

echo "Removing images..."
docker-compose down --rmi all

echo "Starting services fresh..."
docker-compose up -d

echo "Docker Compose reset complete!"