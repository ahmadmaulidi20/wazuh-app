#!/bin/bash
sg docker -c "docker exec backend-backend-1 sh -c 'curl -s -X POST http://localhost:3000/api/auth/login -H \"Content-Type: application/json\" -d \"{\"username\":\"admin\",\"password\":\"admin123\"}\"'" 2>&1
