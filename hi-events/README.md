# Hi.Events Setup Instructions

Hi.Events will be cloned from their official repository and configured to work with our shared infrastructure.

## Setup Process (Automated by master-setup.sh)

The master script will:

1. **Clone Hi.Events repository**:
   ```bash
   git clone https://github.com/HiEventsDev/hi.events.git /opt/hi-events-source
   ```

2. **Copy their Docker setup**:
   ```bash
   cp -r /opt/hi-events-source/docker/all-in-one/* ./hi-events/
   ```

3. **Configure to use shared infrastructure**:
   - Modify their docker-compose.yml to connect to our shared PostgreSQL
   - Update their .env to use our database settings
   - Configure Traefik routing

4. **Start Hi.Events**:
   ```bash
   cd hi-events && docker-compose up -d
   ```

## Expected Structure After Setup
```
hi-events/
├── docker-compose.yml    # Modified from Hi.Events official
├── .env                  # Configured for our setup
└── app/                  # Hi.Events application files
```

## Access
- **Hi.Events**: https://events.srv871991.hstgr.cloud

## Database Connection
Hi.Events will connect to:
- **Host**: postgres-shared (from shared infrastructure)
- **Database**: hievents_db
- **User**: appuser
- **Password**: HuayVPS2024!SecureDB