#!/bin/bash

# Master Setup Script for n8n + Hi.Events with Shared Infrastructure
# Modular approach using official Hi.Events Docker setup

set -e

echo "🚀 Starting modular deployment of n8n + Hi.Events..."
echo "📍 Working directory: $(pwd)"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root"
   exit 1
fi

# Install Docker and Docker Compose if not present
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "🐳 Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        systemctl enable docker
        systemctl start docker
        echo "✅ Docker installed"
    else
        echo "✅ Docker already installed"
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo "🐳 Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        echo "✅ Docker Compose installed"
    else
        echo "✅ Docker Compose already installed"
    fi
}

# Setup shared infrastructure
setup_shared_infrastructure() {
    echo ""
    echo "🏗️ Setting up shared infrastructure (Traefik + PostgreSQL + Redis)..."
    cd shared

    # Generate Traefik auth if needed
    if grep -q "example_hash_here" .env; then
        echo "🔑 Setting up Traefik dashboard authentication..."
        echo "Enter password for Traefik dashboard (username: admin):"
        read -s TRAEFIK_PASSWORD
        TRAEFIK_HASH=$(openssl passwd -apr1 "$TRAEFIK_PASSWORD")
        sed -i "s|TRAEFIK_AUTH=.*|TRAEFIK_AUTH=admin:$TRAEFIK_HASH|" .env
        echo "✅ Traefik authentication configured"
    fi

    # Set permissions
    chmod 600 .env
    mkdir -p traefik/acme
    chmod 700 traefik/acme
    touch traefik/acme/acme.json
    chmod 600 traefik/acme/acme.json

    # Start shared services
    echo "🚀 Starting shared infrastructure..."
    docker-compose up -d

    # Wait for PostgreSQL to be ready
    echo "⏳ Waiting for PostgreSQL to be ready..."
    for i in {1..30}; do
        if docker-compose exec -T postgres-shared pg_isready -U appuser -d appdb; then
            echo "✅ PostgreSQL is ready"
            break
        fi
        echo "   Waiting... ($i/30)"
        sleep 2
    done

    cd ..
}

# Setup n8n
setup_n8n() {
    echo ""
    echo "🔧 Setting up n8n..."
    cd n8n

    # Start n8n
    echo "🚀 Starting n8n..."
    docker-compose up -d

    # Wait for n8n to be ready
    echo "⏳ Waiting for n8n to initialize..."
    sleep 15

    cd ..
}

# Setup Hi.Events
setup_hievents() {
    echo ""
    echo "📅 Setting up Hi.Events..."

    # Clone Hi.Events repository if not exists
    if [ ! -d "/opt/hi-events-source" ]; then
        echo "📥 Cloning Hi.Events repository..."
        git clone https://github.com/HiEventsDev/hi.events.git /opt/hi-events-source
        echo "✅ Hi.Events repository cloned"
    else
        echo "✅ Hi.Events repository already exists"
    fi

    # Copy Hi.Events docker setup
    echo "📋 Copying Hi.Events Docker configuration..."
    cp -r /opt/hi-events-source/docker/all-in-one/* ./hi-events/ 2>/dev/null || {
        echo "⚠️ Hi.Events docker files not found, creating basic structure..."
        mkdir -p hi-events
    }

    cd hi-events

    # Create/update Hi.Events .env with our settings
    echo "⚙️ Configuring Hi.Events environment..."
    cat > .env << EOF
# Hi.Events Configuration for srv871991.hstgr.cloud
APP_NAME=Hi.Events
APP_ENV=production
APP_KEY=base64:qjh15QCjnA+PG/Dkz9XXuuefeQZZzMqE8CMK9lO6K2s=
APP_DEBUG=false
APP_URL=https://events.srv871991.hstgr.cloud

# Database Configuration (Shared PostgreSQL)
DB_CONNECTION=pgsql
DB_HOST=postgres-shared
DB_PORT=5432
DB_DATABASE=hievents_db
DB_USERNAME=appuser
DB_PASSWORD=HuayVPS2024!SecureDB

# Cache and Queue (Shared Redis)
CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
REDIS_HOST=redis-shared
REDIS_PORT=6379

# Mail Configuration
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=huayaney.exe@gmail.com
MAIL_PASSWORD=your-gmail-app-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=huayaney.exe@gmail.com
MAIL_FROM_NAME=Hi.Events

# JWT Configuration
JWT_SECRET=C1kFt+MqKMGxS8IWSHx75xNiiYlrJR12hEKHoVrgDY8=
JWT_TTL=86400

# File Storage
FILESYSTEM_DISK=local
EOF

    # Create Hi.Events docker-compose.yml if it doesn't exist
    if [ ! -f "docker-compose.yml" ]; then
        echo "📄 Creating Hi.Events Docker Compose configuration..."
        cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  hi-events-app:
    build:
      context: /opt/hi-events-source
      dockerfile: docker/Dockerfile
    container_name: hi-events-app
    restart: unless-stopped
    env_file: .env
    volumes:
      - hi_events_storage:/var/www/html/storage
      - hi_events_public:/var/www/html/public
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.hievents.rule=Host(\`events.srv871991.hstgr.cloud\`)"
      - "traefik.http.routers.hievents.entrypoints=websecure"
      - "traefik.http.routers.hievents.tls.certresolver=letsencrypt"
      - "traefik.http.services.hievents.loadbalancer.server.port=80"
    networks:
      - shared-network
    external_links:
      - postgres-shared
      - redis-shared
      - traefik-shared

  hi-events-queue:
    build:
      context: /opt/hi-events-source
      dockerfile: docker/Dockerfile
    container_name: hi-events-queue
    restart: unless-stopped
    command: php artisan queue:work --sleep=3 --tries=3 --timeout=90
    env_file: .env
    volumes:
      - hi_events_storage:/var/www/html/storage
    depends_on:
      - hi-events-app
    networks:
      - shared-network
    external_links:
      - postgres-shared
      - redis-shared

volumes:
  hi_events_storage:
  hi_events_public:

networks:
  shared-network:
    external: true
EOF
    fi

    # Start Hi.Events
    echo "🚀 Starting Hi.Events..."
    if docker-compose up -d; then
        echo "✅ Hi.Events containers started"
    else
        echo "⚠️ Hi.Events startup had issues, but continuing..."
    fi

    # Wait and run migrations
    echo "⏳ Waiting for Hi.Events to initialize..."
    sleep 20

    echo "🗄️ Running Hi.Events database migrations..."
    if docker-compose exec -T hi-events-app php artisan migrate --force; then
        echo "✅ Hi.Events migrations completed"
    else
        echo "⚠️ Hi.Events migrations failed - may need manual intervention"
    fi

    cd ..
}

# Display results
show_results() {
    echo ""
    echo "🎉 Deployment Summary"
    echo "===================="
    
    echo ""
    echo "🌐 Application URLs:"
    echo "   • Traefik Dashboard: https://traefik.srv871991.hstgr.cloud"
    echo "   • n8n Workflows: https://n8n.srv871991.hstgr.cloud"
    echo "   • Hi.Events: https://events.srv871991.hstgr.cloud"
    
    echo ""
    echo "🔑 Default Credentials:"
    echo "   • Traefik: admin / [password you entered]"
    echo "   • n8n: admin / HuayAdmin2024!"
    
    echo ""
    echo "🔧 Service Status:"
    docker-compose -f shared/docker-compose.yml ps
    docker-compose -f n8n/docker-compose.yml ps
    if [ -f "hi-events/docker-compose.yml" ]; then
        docker-compose -f hi-events/docker-compose.yml ps
    fi
    
    echo ""
    echo "📋 Next Steps:"
    echo "1. Configure DNS subdomains in Hostinger:"
    echo "   - traefik.srv871991.hstgr.cloud"
    echo "   - n8n.srv871991.hstgr.cloud"  
    echo "   - events.srv871991.hstgr.cloud"
    echo "2. Update SMTP settings for email functionality"
    echo "3. Test applications and troubleshoot if needed"
    
    echo ""
    echo "🛠️ Troubleshooting Commands:"
    echo "   • View logs: docker-compose -f [service]/docker-compose.yml logs [container]"
    echo "   • Restart service: docker-compose -f [service]/docker-compose.yml restart"
    echo "   • Stop all: ./stop-all.sh"
}

# Main execution
main() {
    install_docker
    setup_shared_infrastructure
    setup_n8n
    setup_hievents
    show_results
}

# Run main function
main