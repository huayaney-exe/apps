# Modular VPS Applications Setup

Complete modular deployment of n8n and Hi.Events with shared infrastructure on srv871991.hstgr.cloud.

## 🏗️ Architecture

### Modular Design
```
/opt/apps/
├── master-setup.sh          # Orchestrates everything
├── cleanup-vps.sh           # VPS cleanup utility
├── stop-all.sh              # Stop all services
├── logs.sh                  # View service logs
├── shared/                  # Shared infrastructure
│   ├── docker-compose.yml   #   Traefik + PostgreSQL + Redis
│   └── .env
├── n8n/                     # n8n workflow automation
│   ├── docker-compose.yml
│   └── .env
└── hi-events/               # Hi.Events (populated by setup script)
    ├── docker-compose.yml   #   Generated from official Hi.Events
    └── .env                 #   Configured for our setup
```

### Shared Infrastructure
- **Traefik**: Reverse proxy with automatic SSL certificates
- **PostgreSQL**: Shared database with separate databases for each app
- **Redis**: Caching and session storage

### Applications
- **n8n**: Workflow automation platform
- **Hi.Events**: Event management system (uses official Docker setup)

## 🚀 Quick Start

### 1. Clean VPS (if needed)
```bash
# On your VPS, if you have previous installations
curl -sL https://raw.githubusercontent.com/huayaney-exe/apps/main/cleanup-vps.sh | bash
```

### 2. Deploy Everything
```bash
# Clone repository
git clone https://github.com/huayaney-exe/apps.git /opt/apps
cd /opt/apps

# Run master setup (installs Docker, starts all services)
./master-setup.sh
```

### 3. Configure DNS
Point these subdomains to your VPS IP in Hostinger DNS panel:
- `traefik.srv871991.hstgr.cloud`
- `n8n.srv871991.hstgr.cloud`
- `events.srv871991.hstgr.cloud`

## 🌐 Application Access

After successful deployment:
- **Traefik Dashboard**: `https://traefik.srv871991.hstgr.cloud`
- **n8n Workflows**: `https://n8n.srv871991.hstgr.cloud`
- **Hi.Events**: `https://events.srv871991.hstgr.cloud`

### Default Credentials
- **Traefik**: admin / [password you set during setup]
- **n8n**: admin / HuayAdmin2024!

## 🔧 Management Commands

### View Logs
```bash
# View specific service logs
./logs.sh shared traefik-shared
./logs.sh n8n n8n-app
./logs.sh hi-events hi-events-app

# View all logs for a service
./logs.sh shared
./logs.sh n8n
./logs.sh hi-events
```

### Service Management
```bash
# Stop all services
./stop-all.sh

# Restart specific service
cd n8n && docker-compose restart && cd ..
cd hi-events && docker-compose restart && cd ..
cd shared && docker-compose restart && cd ..

# View service status
docker-compose -f shared/docker-compose.yml ps
docker-compose -f n8n/docker-compose.yml ps
docker-compose -f hi-events/docker-compose.yml ps
```

### Update Services
```bash
# Pull latest images and restart
cd shared && docker-compose pull && docker-compose up -d && cd ..
cd n8n && docker-compose pull && docker-compose up -d && cd ..
cd hi-events && docker-compose pull && docker-compose up -d && cd ..
```

## 🛡️ Security Features

- Automatic SSL certificates via Let's Encrypt
- HTTP to HTTPS redirect  
- Security headers
- Basic authentication for sensitive endpoints
- Isolated network for inter-service communication

## 📧 Email Configuration

To enable email notifications:

1. **Generate Gmail App Password**:
   - Go to Google Account settings
   - Enable 2-factor authentication
   - Generate App Password

2. **Update configurations**:
   ```bash
   # Update n8n email settings
   nano n8n/.env
   # Set SMTP_PASS=your-gmail-app-password
   
   # Update Hi.Events email settings  
   nano hi-events/.env
   # Set MAIL_PASSWORD=your-gmail-app-password
   
   # Restart services
   cd n8n && docker-compose restart && cd ..
   cd hi-events && docker-compose restart && cd ..
   ```

## 🔍 Troubleshooting

### Check Service Health
```bash
# Check all containers
docker ps

# Check specific service
docker-compose -f shared/docker-compose.yml ps
docker-compose -f n8n/docker-compose.yml ps
docker-compose -f hi-events/docker-compose.yml ps
```

### Common Issues

#### SSL Certificate Problems
```bash
# Check Traefik logs
./logs.sh shared traefik-shared

# Regenerate certificates
cd shared && docker-compose restart traefik-shared && cd ..
```

#### Database Connection Issues
```bash
# Check PostgreSQL
./logs.sh shared postgres-shared

# Connect to database directly
docker-compose -f shared/docker-compose.yml exec postgres-shared psql -U appuser -d appdb
```

#### Hi.Events Issues
Hi.Events uses their official Docker setup, so refer to their documentation:
- [Hi.Events GitHub](https://github.com/HiEventsDev/hi.events)
- [Hi.Events Documentation](https://hi.events)

### Service Dependencies

**Startup Order** (automatically handled by master-setup.sh):
1. Shared infrastructure (Traefik, PostgreSQL, Redis)
2. n8n (depends on PostgreSQL)
3. Hi.Events (depends on PostgreSQL, Redis)

## 📊 Monitoring

### Resource Usage
```bash
# Check Docker resource usage
docker stats

# Check system resources
htop
df -h
```

### Application Metrics
- **Traefik Dashboard**: Shows routing and SSL status
- **Database**: Connect via psql for query analysis
- **Redis**: Use redis-cli for cache inspection

## 🔄 Backup and Recovery

### Database Backup
```bash
# Backup PostgreSQL data
docker-compose -f shared/docker-compose.yml exec postgres-shared pg_dump -U appuser appdb > backup-$(date +%Y%m%d).sql
```

### Configuration Backup
All configurations are in Git, so commit any changes:
```bash
git add -A
git commit -m "Update configuration"
git push origin main
```

## 📞 Support

For application-specific issues:
- **n8n**: [n8n Documentation](https://docs.n8n.io)
- **Hi.Events**: [Hi.Events GitHub Issues](https://github.com/HiEventsDev/hi.events/issues)
- **Traefik**: [Traefik Documentation](https://doc.traefik.io/traefik/)

For deployment and infrastructure issues: Use the troubleshooting commands above and check service logs.