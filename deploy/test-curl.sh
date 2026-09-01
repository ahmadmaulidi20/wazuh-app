#!/bin/bash
# Ganti ADMIN_PASSWORD dengan password admin backend saat menjalankan.
ADMIN_PASSWORD="${ADMIN_PASSWORD:-CHANGE_ME}"
sg docker -c "docker exec backend-backend-1 sh -c 'curl -s -X POST http://localhost:3000/api/auth/login -H \"Content-Type: application/json\" -d \"{\"username\":\"admin\",\"password\":\"$ADMIN_PASSWORD\"}\"'" 2>&1
