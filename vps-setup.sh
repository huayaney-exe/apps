#!/bin/bash

# Optimized VPS Setup Script for srv871991.hstgr.cloud
# Pre-configured for huayaney.exe@gmail.com

set -e

echo "🚀 Setting up Hi.Events and n8n with Traefik on srv871991.hstgr.cloud..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Use pre-configured production environment
if [ -f .env.production ]; then
    echo "📝 Using pre-configured .env.production file..."
    cp .env.production .env
    echo "✅ Environment configured for srv871991.hstgr.cloud"
else
    echo "❌ .env.production file not found. Using setup.sh instead."
    ./setup.sh
    exit 0
fi

# Load environment variables
source .env

# Check Hi.Events secrets (pre-configured in .env.production)
if [ -z "$HIEVENTS_APP_KEY" ]; then
    echo "❌ HIEVENTS_APP_KEY not found in .env file"
    echo "   Please ensure .env.production was copied correctly"
    exit 1
else
    echo "✅ Hi.Events APP_KEY configured"
fi

if [ -z "$HIEVENTS_JWT_SECRET" ]; then
    echo "❌ HIEVENTS_JWT_SECRET not found in .env file"
    echo "   Please ensure .env.production was copied correctly"
    exit 1
else
    echo "✅ Hi.Events JWT_SECRET configured"
fi

# Generate Traefik auth if not set
if [ "$TRAEFIK_AUTH" = "admin:\$2y\$10\$example_hash_here" ]; then
    echo "🔑 Generating Traefik dashboard authentication..."
    echo "Enter password for Traefik dashboard (username will be 'admin'):"
    read -s TRAEFIK_PASSWORD
    TRAEFIK_HASH=$(openssl passwd -apr1 "$TRAEFIK_PASSWORD")
    sed -i "s|TRAEFIK_AUTH=.*|TRAEFIK_AUTH=admin:$TRAEFIK_HASH|" .env
fi

# SMTP Configuration reminder
echo ""
echo "📧 SMTP Configuration Reminder:"
echo "   To enable email notifications, update your .env file with:"
echo "   SMTP_PASS=your-gmail-app-password"
echo "   (Generate App Password in your Google Account settings)"
echo ""

# Set correct permissions
echo "🔧 Setting up permissions..."
chmod 600 .env
mkdir -p traefik/acme
chmod 700 traefik/acme
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
    echo "✅ Docker installed successfully"
fi

if ! command -v docker-compose &> /dev/null; then
    echo "🐳 Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed successfully"
fi

# Start the services
echo "🚀 Starting services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start (30 seconds)..."
sleep 30

# Check if services are running
echo "🔍 Checking service status..."
docker-compose ps

# Run Hi.Events migrations
echo "🗄️ Running Hi.Events database migrations..."
if docker-compose exec -T hievents-app php artisan migrate --force; then
    echo "✅ Database migrations completed"
else
    echo "⚠️ Migration failed - checking if database is ready..."
    sleep 10
    docker-compose exec -T hievents-app php artisan migrate --force
fi

# Seed the database
echo "🌱 Seeding Hi.Events database..."
docker-compose exec -T hievents-app php artisan db:seed --force || echo "⚠️ Database seeding failed - this may be normal if already seeded"

echo ""
echo "🎉 Setup complete!"
echo ""
echo "🌐 Your applications should be available at:"
echo "   • Traefik Dashboard: https://traefik.srv871991.hstgr.cloud"
echo "   • n8n Workflows: https://n8n.srv871991.hstgr.cloud"
echo "   • Hi.Events: https://events.srv871991.hstgr.cloud"
echo ""
echo "📝 Default credentials:"
echo "   • Traefik Dashboard: admin / [password you entered]"
echo "   • n8n: admin / HuayAdmin2024!"
echo ""
echo "🔗 DNS Configuration Required:"
echo "   Configure these subdomains in your Hostinger DNS panel:"
echo "   • traefik.srv871991.hstgr.cloud → srv871991.hstgr.cloud IP"
echo "   • n8n.srv871991.hstgr.cloud → srv871991.hstgr.cloud IP"
echo "   • events.srv871991.hstgr.cloud → srv871991.hstgr.cloud IP"
echo ""
echo "📧 Email Setup:"
echo "   To enable email notifications, edit .env and set:"
echo "   SMTP_PASS=your-gmail-app-password"
echo "   Then restart: docker-compose restart"
echo ""
echo "🔧 Useful commands:"
echo "   • View logs: docker-compose logs -f [service_name]"
echo "   • Restart services: docker-compose restart"
echo "   • Stop services: docker-compose down"
echo "   • Update services: docker-compose pull && docker-compose up -d"