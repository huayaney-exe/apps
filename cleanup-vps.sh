#!/bin/bash

# VPS Cleanup Script
# Run this on your VPS to completely clean Docker and project files

set -e

echo "🧹 Cleaning up VPS completely..."

# Stop any running containers
if command -v docker-compose &> /dev/null; then
    echo "🛑 Stopping all Docker Compose services..."
    docker-compose down --volumes --remove-orphans 2>/dev/null || true
fi

# Remove all Docker resources
if command -v docker &> /dev/null; then
    echo "🐳 Removing all Docker containers, images, volumes, and networks..."
    docker system prune -a --volumes -f
fi

# Remove project directory
if [ -d "/root/apps" ]; then
    echo "📁 Removing /root/apps directory..."
    rm -rf /root/apps
fi

# Optional: Remove Docker completely (uncomment if you want to reinstall Docker fresh)
# echo "🗑️ Removing Docker completely..."
# apt-get remove -y docker docker-engine docker.io containerd runc
# apt-get autoremove -y

echo "✅ VPS cleanup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Clone the updated repository:"
echo "   git clone https://github.com/huayaney-exe/apps.git /opt/apps"
echo "2. Run the new setup:"
echo "   cd /opt/apps && ./master-setup.sh"