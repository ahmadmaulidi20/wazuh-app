#!/bin/bash
set -e

echo "=== Wazuh Monitor Deployment ==="

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "Error: Docker is required"; exit 1; }
command -v docker compose >/dev/null 2>&1 || { echo "Error: Docker Compose is required"; exit 1; }

# Load environment
if [ ! -f .env.production ]; then
    echo "Error: .env.production file not found"
    echo "Copy from .env.production template and fill in your values"
    exit 1
fi

# Check for Firebase credentials
if [ ! -f firebase-service-account.json ]; then
    echo "Warning: firebase-service-account.json not found"
    echo "Push notifications will not work until you add it"
fi

echo ""
echo "Step 1: Build Flutter web app"
echo "Make sure you have Flutter installed and run:"
echo "  cd ../wazuh_app && flutter build web"
echo ""
read -p "Continue with Docker deployment? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Step 2: Deploy with Docker Compose"
    docker compose --env-file .env.production -f docker-compose.prod.yml up -d --build

    echo ""
    echo "=== Deployment Complete ==="
    echo "Backend API: http://localhost:3000"
    echo ""
    echo "Next steps:"
    echo "1. Configure your domain DNS to point to this server"
    echo "2. Set up SSL with: certbot --nginx -d your-domain.com"
    echo "3. Configure Wazuh Manager to send alerts:"
    echo "   - Copy backend/wazuh/custom-wazuh.py to /var/ossec/integrations/"
    echo "   - Set WEBHOOK_URL and API_KEY environment variables"
    echo "   - Add integration config to /var/ossec/etc/ossec.conf"
fi
