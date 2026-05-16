# Quick Reference Guide

## Essential Commands

### System Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3-pip python3-venv wget curl

# Check Python version
python3 --version
```

### Flask Application

```bash
# Create project directory
mkdir python-monitoring
cd python-monitoring

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install flask prometheus_client

# Run Flask app
python3 app.py

# Access Flask app
curl http://localhost:5000
curl http://localhost:5000/metrics
```

### Prometheus

```bash
# Download Prometheus
cd ~
wget https://github.com/prometheus/prometheus/releases/download/v3.3.1/prometheus-3.3.1.linux-amd64.tar.gz

# Extract
tar -xvf prometheus-3.3.1.linux-amd64.tar.gz

# Rename directory
mv prometheus-3.3.1.linux-amd64 prometheus

# Enter directory
cd prometheus

# Start Prometheus
./prometheus --config.file=prometheus.yml

# Access Prometheus
curl http://localhost:9090

# Check if running
ps aux | grep prometheus
```

### Prometheus Configuration

```bash
# Edit prometheus.yml
nano prometheus.yml

# Minimal configuration:
cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'python-flask-app'
    static_configs:
      - targets: ['localhost:5000']
EOF
```

### Grafana

```bash
# Install Grafana
curl -fsSL https://apt.grafana.com/gpg.key | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/grafana.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://apt.grafana.com stable main" | \
  sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt update
sudo apt install grafana-server -y

# Start Grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# Check Grafana status
sudo systemctl status grafana-server

# View Grafana logs
sudo journalctl -u grafana-server -f

# Restart Grafana
sudo systemctl restart grafana-server

# Stop Grafana
sudo systemctl stop grafana-server
```

### Port Management

```bash
# Check if ports are open
sudo lsof -i :5000   # Flask
sudo lsof -i :9090   # Prometheus
sudo lsof -i :3000   # Grafana

# Open firewall ports
sudo ufw allow 5000/tcp
sudo ufw allow 9090/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 22/tcp

# Check firewall status
sudo ufw status

# Enable firewall
sudo ufw enable

# Disable firewall (not recommended for production)
sudo ufw disable
```

### Testing Connectivity

```bash
# Test Flask app
curl http://localhost:5000
curl http://localhost:5000/metrics

# Test Prometheus
curl http://localhost:9090

# Test Grafana
curl http://localhost:3000

# Verbose testing
curl -v http://localhost:5000
curl -I http://localhost:9090
```

## Web Addresses

| Service | Address | Port |
|---------|---------|------|
| Flask App | http://your-ec2-ip:5000 | 5000 |
| Flask Metrics | http://your-ec2-ip:5000/metrics | 5000 |
| Prometheus | http://your-ec2-ip:9090 | 9090 |
| Grafana | http://your-ec2-ip:3000 | 3000 |

## Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| Grafana | admin | admin |
| Prometheus | None | None |
| Flask | None | None |

## PromQL Queries

```promql
# Total requests
app_requests_total

# Request rate (requests per second)
rate(app_requests_total[5m])

# Request rate (1 minute average)
rate(app_requests_total[1m])

# Total requests in 5 minutes
increase(app_requests_total[5m])

# Average request duration
rate(app_request_duration_seconds_sum[5m]) / rate(app_request_duration_seconds_count[5m])

# Active connections
app_active_connections

# Error rate
rate(app_errors_total[5m])
```

## File Locations

```
home
├── python-monitoring/
│   ├── venv/
│   ├── app.py
│   └── requirements.txt
│
└── prometheus/
    ├── prometheus
    ├── prometheus.yml
    ├── data/
    └── consoles/
```

## Directory Navigation

```bash
# Go to Flask app
cd ~/python-monitoring

# Go to Prometheus
cd ~/prometheus

# Go to Grafana config
cd /etc/grafana

# Go to Grafana data
cd /var/lib/grafana
```

## Process Management

```bash
# Find running processes
ps aux | grep python
ps aux | grep prometheus
ps aux | grep grafana

# Kill process
kill -9 <PID>

# Kill by port
sudo lsof -i :5000 -t | xargs kill -9

# Run in background
nohup python3 app.py > app.log 2>&1 &
nohup ./prometheus --config.file=prometheus.yml > prom.log 2>&1 &
```

## Log Files

```bash
# Flask logs
# Appears in terminal running Flask

# Prometheus logs
# Appears in terminal running Prometheus

# Grafana logs
sudo journalctl -u grafana-server -n 50 -f

# System logs
tail -f /var/log/syslog
dmesg | tail -20
```

## Troubleshooting Commands

```bash
# Check if port is in use
netstat -tulpn | grep 5000
netstat -tulpn | grep 9090
netstat -tulpn | grep 3000

# Check service status
sudo systemctl status grafana-server
systemctl is-active grafana-server

# Restart services
sudo systemctl restart grafana-server

# View last 20 lines of logs
sudo journalctl -u grafana-server -n 20

# Follow logs in real time
sudo journalctl -u grafana-server -f

# Check disk space
df -h
du -sh ~/*

# Check memory usage
free -h
```

## Performance Monitoring

```bash
# CPU and memory usage
top
htop  # (if installed)

# Process specific resource usage
ps aux | grep python
ps aux | grep prometheus

# Disk I/O
iostat -x

# Network connections
netstat -an | grep ESTABLISHED
```

## Configuration Files

### prometheus.yml location
```
~/prometheus/prometheus.yml
```

### Grafana configuration
```
/etc/grafana/grafana.ini
```

### Grafana data storage
```
/var/lib/grafana/
```

## Restart Sequence

If you need to restart everything:

```bash
# Stop Flask (in Flask terminal: Ctrl+C)
# Stop Prometheus (in Prometheus terminal: Ctrl+C)
sudo systemctl stop grafana-server

# Wait a few seconds
sleep 2

# Start Flask
cd ~/python-monitoring
source venv/bin/activate
python3 app.py &

# Start Prometheus (in new terminal)
cd ~/prometheus
./prometheus --config.file=prometheus.yml &

# Start Grafana
sudo systemctl start grafana-server

# Verify all services
sleep 5
curl http://localhost:5000
curl http://localhost:9090
sudo systemctl status grafana-server
```

## SSH Connection

```bash
# Connect to EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Copy file to EC2
scp -i your-key.pem local-file ubuntu@your-ec2-ip:~/

# Copy file from EC2
scp -i your-key.pem ubuntu@your-ec2-ip:~/remote-file ./
```

## Useful One-Liners

```bash
# Generate 100 requests to Flask app
for i in {1..100}; do curl http://localhost:5000 & done

# Monitor metrics in real time
watch -n 1 'curl -s http://localhost:5000/metrics | tail -10'

# Check all metrics being exported
curl -s http://localhost:5000/metrics | grep -v '^#'

# Count number of metrics
curl -s http://localhost:5000/metrics | grep -v '^#' | wc -l

# Find process and kill it
pkill -f app.py
pkill -f prometheus
```

## Security

```bash
# Change Grafana admin password
sudo grafana-cli admin reset-admin-password newpassword

# Set file permissions
chmod 644 prometheus.yml
chmod 755 prometheus

# Check current user
whoami

# Run as specific user
sudo -u grafana grafana-server
```

## Backup Commands

```bash
# Backup Prometheus data
tar -czf prometheus-backup.tar.gz ~/prometheus

# Backup Grafana database
sudo tar -czf grafana-backup.tar.gz /var/lib/grafana

# Backup configurations
cp ~/prometheus/prometheus.yml ~/prometheus-backup.yml
```

## Cleanup Commands

```bash
# Remove Prometheus data
rm -rf ~/prometheus/data

# Remove Prometheus installation
rm -rf ~/prometheus

# Remove Grafana
sudo apt remove grafana-server -y

# Clean pip cache
pip cache purge

# Remove Python virtual environment
rm -rf ~/python-monitoring/venv
```

## Time-Saving Aliases

Add to ~/.bashrc:

```bash
alias checkflask='curl http://localhost:5000'
alias checkprom='curl http://localhost:9090'
alias checkgraf='curl http://localhost:3000'
alias viewmetrics='curl http://localhost:5000/metrics'
alias tailgraf='sudo journalctl -u grafana-server -f'
alias toprocesses='ps aux | sort -nrk 3,3 | head -n 10'
```

Then reload:
```bash
source ~/.bashrc
```

## Help and Documentation

```bash
# Get Flask help
python3 -c "import flask; help(flask)"

# Get prometheus_client help
python3 -c "import prometheus_client; help(prometheus_client)"

# View package versions
pip list

# Check Python modules
python3 -m pip list
```

## Summary Checklist

- [ ] EC2 instance is running and accessible
- [ ] Security group has ports 22, 5000, 9090, 3000 open
- [ ] Python 3 and pip installed
- [ ] Flask app created and running on port 5000
- [ ] Prometheus downloaded and configured
- [ ] Prometheus running on port 9090
- [ ] Prometheus shows Flask target as UP
- [ ] Grafana installed and running on port 3000
- [ ] Prometheus added as Grafana data source
- [ ] Test query works in Prometheus
- [ ] Metrics visible in Grafana dashboard
