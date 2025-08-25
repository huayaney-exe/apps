#!/bin/bash

# Hi.Events VPS Setup Script
# Run this script on your VPS after cloning the repository

set -e

echo "🚀 Setting up Hi.Events and n8n with Traefik..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Create .env file from example if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from example..."
    cp .env.example .env
    echo "⚠️  Please edit .env file with your actual configuration before continuing!"
    echo "   Key items to update:"
    echo "   - DOMAIN=yourdomain.com"
    echo "   - ACME_EMAIL=your@email.com"
    echo "   - All password fields"
    echo "   - SMTP settings"
    echo ""
    read -p "Press Enter after you've edited the .env file..."
fi

# Load environment variables
source .env

# Generate Hi.Events secrets if not set
if [ -z "$HIEVENTS_APP_KEY" ]; then
    echo "🔑 Generating Hi.Events APP_KEY..."
    APP_KEY=$(openssl rand -base64 32)
    sed -i "s/HIEVENTS_APP_KEY=/HIEVENTS_APP_KEY=base64:$APP_KEY/" .env
fi

if [ -z "$HIEVENTS_JWT_SECRET" ]; then
    echo "🔑 Generating Hi.Events JWT_SECRET..."
    JWT_SECRET=$(openssl rand -base64 64)
    sed -i "s/HIEVENTS_JWT_SECRET=/HIEVENTS_JWT_SECRET=$JWT_SECRET/" .env
fi

# Generate Traefik auth if not set
if [ -z "$TRAEFIK_AUTH" ] || [ "$TRAEFIK_AUTH" = "admin:\$2y\$10\$example_hash_here" ]; then
    echo "🔑 Generating Traefik dashboard authentication..."
    echo "Enter password for Traefik dashboard (username will be 'admin'):"
    read -s TRAEFIK_PASSWORD
    TRAEFIK_HASH=$(openssl passwd -apr1 "$TRAEFIK_PASSWORD")
    sed -i "s|TRAEFIK_AUTH=.*|TRAEFIK_AUTH=admin:$TRAEFIK_HASH|" .env
fi

# Set correct permissions
echo "🔧 Setting up permissions..."
chmod 600 .env
mkdir -p traefik/acme
chmod 600 traefik/acme
touch traefik/acme/acme.json
chmod 600 traefik/acme/acme.json

# Install Docker and Docker Compose if not present
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
fi

if ! command -v docker-compose &> /dev/null; then
    echo "🐳 Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Start the services
echo "🚀 Starting services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Run Hi.Events migrations
echo "🗄️ Running Hi.Events database migrations..."
docker-compose exec hievents-app php artisan migrate --force
docker-compose exec hievents-app php artisan db:seed --force

echo "✅ Setup complete!"
echo ""
echo "🌐 Your applications should be available at:"
echo "   • Traefik Dashboard: https://traefik.$DOMAIN"
echo "   • n8n: https://n8n.$DOMAIN"
echo "   • Hi.Events: https://events.$DOMAIN"
echo ""
echo "📝 Default credentials:"
echo "   • Traefik Dashboard: admin / [password you entered]"
echo "   • n8n: $N8N_BASIC_AUTH_USER / $N8N_BASIC_AUTH_PASSWORD"
echo ""
echo "🔧 Useful commands:"
echo "   • View logs: docker-compose logs -f [service_name]"
echo "   • Restart services: docker-compose restart"
echo "   • Stop services: docker-compose down"
echo "   • Update services: docker-compose pull && docker-compose up -d"