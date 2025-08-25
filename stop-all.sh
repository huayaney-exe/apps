#!/bin/bash

# Stop all services script

echo "🛑 Stopping all services..."

# Stop Hi.Events if exists
if [ -f "hi-events/docker-compose.yml" ]; then
    echo "📅 Stopping Hi.Events..."
    cd hi-events && docker-compose down && cd ..
fi

# Stop n8n
echo "🔧 Stopping n8n..."
cd n8n && docker-compose down && cd ..

# Stop shared infrastructure
echo "🏗️ Stopping shared infrastructure..."
cd shared && docker-compose down && cd ..

echo "✅ All services stopped"