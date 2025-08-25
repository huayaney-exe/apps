#!/bin/bash

# Quick log viewing script

echo "📋 Available services:"
echo "1. shared (traefik, postgres, redis)"
echo "2. n8n"
echo "3. hi-events"

if [ -z "$1" ]; then
    echo ""
    echo "Usage: ./logs.sh [service] [container]"
    echo ""
    echo "Examples:"
    echo "  ./logs.sh shared traefik-shared"
    echo "  ./logs.sh n8n n8n-app"
    echo "  ./logs.sh hi-events hi-events-app"
    echo ""
    echo "Or just: ./logs.sh [service] to see all logs for that service"
    exit 1
fi

SERVICE=$1
CONTAINER=${2:-""}

case $SERVICE in
    "shared")
        cd shared
        if [ -n "$CONTAINER" ]; then
            docker-compose logs -f $CONTAINER
        else
            docker-compose logs -f
        fi
        ;;
    "n8n")
        cd n8n
        if [ -n "$CONTAINER" ]; then
            docker-compose logs -f $CONTAINER
        else
            docker-compose logs -f
        fi
        ;;
    "hi-events")
        cd hi-events
        if [ -n "$CONTAINER" ]; then
            docker-compose logs -f $CONTAINER
        else
            docker-compose logs -f
        fi
        ;;
    *)
        echo "❌ Unknown service: $SERVICE"
        echo "Available: shared, n8n, hi-events"
        ;;
esac