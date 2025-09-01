#!/bin/bash

set -e

# Update system
apt-get update -y

# Install Docker
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Start Docker service
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create working directory
mkdir -p /opt/latency-404
cd /opt/latency-404

# Clone the repository
git clone https://github.com/thonglmt/latency-404.git .

# Run the monitoring service
docker-compose -f monitoring-service/deploy/docker/docker-compose.yaml up -d

echo "$(date): Monitoring service deployment completed" >> /var/log/user-data.log

#
# Set up a cronjob for automatically updating the service every 180s.
# GitOps? Kind of.
#

# Create update script
cat > /opt/latency-404/update-service.sh << 'EOF'
#!/bin/bash
cd /opt/latency-404
git pull origin main
docker-compose -f monitoring-service/deploy/docker/docker-compose.yaml pull
docker-compose -f monitoring-service/deploy/docker/docker-compose.yaml up -d
echo "$(date): Service updated" >> /var/log/service-updates.log
EOF

chmod +x /opt/latency-404/update-service.sh

# Create cronjob to run every 180 seconds (3 minutes)
crontab -l > /tmp/crontab.bak 2>/dev/null || true
echo "*/3 * * * * /opt/latency-404/update-service.sh" >> /tmp/crontab.bak
crontab /tmp/crontab.bak

echo "$(date): Cronjob setup completed - checking for updates every 180s" >> /var/log/user-data.log
