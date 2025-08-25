# VPS Applications Setup

This repository contains the complete setup for running n8n and Hi.Events behind Traefik reverse proxy on your VPS.

## 🏗️ Architecture

- **Traefik 2**: Reverse proxy with automatic SSL certificates
- **n8n**: Workflow automation platform
- **Hi.Events**: Event management system  
- **PostgreSQL**: Shared database
- **Redis**: Caching and session storage

## 🚀 Quick Start

### Prerequisites

- VPS with Docker and Docker Compose
- Domain name with DNS pointing to your VPS IP
- Ports 80 and 443 open on your VPS

### Installation

1. **Clone this repository on your VPS:**
   ```bash
   git clone [YOUR_REPO_URL] /opt/apps
   cd /opt/apps
   ```

2. **Run the setup script:**
   ```bash
   chmod +x setup.sh
   sudo ./setup.sh
   ```

3. **Follow the prompts to configure your environment**

The script will:
- Create `.env` file from example
- Generate required secrets for Hi.Events
- Install Docker if needed
- Start all services
- Run database migrations

## 🌐 Access Your Applications

After setup, your applications will be available at:

- **Traefik Dashboard**: `https://traefik.yourdomain.com`
- **n8n**: `https://n8n.yourdomain.com`
- **Hi.Events**: `https://events.yourdomain.com`

## ⚙️ Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Your domain
DOMAIN=yourdomain.com
ACME_EMAIL=your@email.com

# Database settings
POSTGRES_PASSWORD=your_strong_password

# n8n authentication
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_password

# SMTP settings (optional but recommended)
SMTP_HOST=smtp.gmail.com
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

### DNS Configuration

Point these subdomains to your VPS IP:
- `traefik.yourdomain.com`
- `n8n.yourdomain.com`
- `events.yourdomain.com`

## 🔧 Management Commands

```bash
# View all services status
docker-compose ps

# View logs for specific service
docker-compose logs -f n8n
docker-compose logs -f hievents-app

# Restart services
docker-compose restart

# Stop all services
docker-compose down

# Update services
docker-compose pull
docker-compose up -d

# Backup database
docker-compose exec postgres pg_dump -U appuser appdb > backup.sql
```

## 🛡️ Security Features

- Automatic SSL certificates via Let's Encrypt
- HTTP to HTTPS redirect
- Security headers via Traefik
- Rate limiting
- Basic authentication for sensitive endpoints

## 🔍 Troubleshooting

### Check service health
```bash
docker-compose ps
docker-compose logs [service_name]
```

### SSL certificate issues
```bash
# Check Traefik logs
docker-compose logs traefik

# Remove and regenerate certificates
rm -rf traefik/acme/acme.json
docker-compose restart traefik
```

### Database connection issues
```bash
# Check PostgreSQL logs
docker-compose logs postgres

# Connect to database directly
docker-compose exec postgres psql -U appuser -d appdb
```

## 📊 Monitoring

Services include health checks and restart policies. Monitor via:

- Traefik dashboard for routing and SSL status
- Docker logs for application issues
- System resources with `htop` or similar tools

## 🔄 Updates

To update applications:

```bash
git pull origin main
docker-compose pull
docker-compose up -d
```

## 📞 Support

For issues with:
- **n8n**: Check [n8n documentation](https://docs.n8n.io)
- **Hi.Events**: Check [Hi.Events documentation](https://github.com/HiEventsDev/hi.events)
- **Traefik**: Check [Traefik documentation](https://doc.traefik.io/traefik/)